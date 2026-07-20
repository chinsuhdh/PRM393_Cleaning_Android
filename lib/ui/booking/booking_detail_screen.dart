import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/dispatch_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/worker_repository.dart';
import '../../data/services/dispatch_hub_service.dart';
import '../../data/services/directions_service.dart';
import '../../data/repositories/review_repository.dart';
import '../../core/constants/booking_enums.dart';
import '../../core/constants/payment_methods.dart';
import '../../core/utils/search_timeout.dart';
import '../payment/vnpay_checkout_screen.dart';
import 'widgets/booking_action_bar.dart';
import 'widgets/booking_info_cards.dart';
import 'widgets/booking_load_error.dart';
import 'widgets/nearby_workers_google_map.dart';
import 'widgets/live_tracking_map.dart';
import 'widgets/reschedule_banner.dart';

part 'widgets/booking_detail_action_handlers.dart';
part 'widgets/booking_detail_cancellation_handlers.dart';
part 'widgets/booking_detail_payment_handlers.dart';
part 'widgets/booking_detail_reschedule_handlers.dart';

final bookingDetailProvider = FutureProvider.autoDispose.family<Booking, String>((ref, id) async {
  final response = await DioClient.instance.get('/Bookings/$id');
  return Booking.fromJson(response.data);
});

const kBookingDetailSkipTransitionExtra = 'booking-detail-skip-transition';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  static const _searchPollInterval = Duration(seconds: 4);

  Timer? _searchTicker;
  int _searchTickCount = 0;
  Timer? _progressTicker;
  bool _liveUpdatesWired = false;
  String? _lastKnownStatus;
  bool _selfCancelling = false;
  bool _cancelledPopupShown = false;
  bool _hasResolvedOnce = false;
  bool _showingMapLayout = false;
  bool _mapTornDown = false;
  double? _liveDistanceMeters;
  DirectionsRoute? _liveRoute;

  @override
  void initState() {
    super.initState();
    _wireLiveUpdates();
  }

  void _wireLiveUpdates() {
    if (_liveUpdatesWired) return;
    _liveUpdatesWired = true;
    final client = ref.read(dispatchHubClientProvider);
    client.onBookingStatusChanged(() {
      if (!mounted) return;
      final workerId = ref.read(bookingDetailProvider(widget.bookingId)).valueOrNull?.worker?.id;
      if (workerId != null) {
        ref.invalidate(bookingReviewProvider((workerUserId: workerId, bookingId: widget.bookingId)));
      }
      ref.invalidate(bookingDetailProvider(widget.bookingId));
    });
    client.onReconnected(() {
      if (!mounted) return;
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      unawaited(() async {
        try {
          await client.subscribeToBooking(widget.bookingId);
        } catch (e) {
          debugPrint('[BookingDetailScreen] resubscribe after reconnect failed: $e');
        }
      }());
    });
    unawaited(() async {
      try {
        await client.connect();
        await client.subscribeToBooking(widget.bookingId);
      } catch (e) {
        debugPrint('[BookingDetailScreen] live update subscribe failed: $e');
      }
    }());
  }

  void _ensureSearchTracking(bool isSearching) {
    if (isSearching && _searchTicker == null) {
      _searchTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!isSearching && _searchTicker != null) {
      _searchTicker!.cancel();
      _searchTicker = null;
    }
  }

  void _ensureProgressTracking(bool inProgress) {
    if (inProgress && _progressTicker == null) {
      _progressTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!inProgress && _progressTicker != null) {
      _progressTicker!.cancel();
      _progressTicker = null;
    }
  }

  void _refreshBooking() => ref.invalidate(bookingDetailProvider(widget.bookingId));

  void _markMapTornDown() => setState(() => _mapTornDown = true);
  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _searchTicker?.cancel();
    _progressTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));
    final booking = bookingAsync.valueOrNull;

    if (booking == null || (!_hasResolvedOnce && bookingAsync.isLoading)) {
      return Scaffold(
        key: const ValueKey('booking-detail-loading-layout'),
        appBar: _appBar(context),
        body: bookingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => BookingLoadError(
            error: e,
            onRetry: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
          ),
          data: (_) => const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    _hasResolvedOnce = true;

    if (_lastKnownStatus != null &&
        _lastKnownStatus != BookingStatusName.cancelled &&
        booking.status == BookingStatusName.cancelled &&
        !_selfCancelling &&
        !_cancelledPopupShown) {
      _cancelledPopupShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCancelledByOtherPartyPopup());
    }
    _lastKnownStatus = booking.status;

    final role = ref.watch(authProvider).role;
    final isSearching = booking.status == BookingStatusName.awaitingWorker &&
        booking.isImmediate &&
        role == UserRole.client;
    _ensureSearchTracking(isSearching);
    final isInProgress = booking.status == BookingStatusName.inProgress;
    _ensureProgressTracking(isInProgress);

    if (_mapTornDown) {
      return Scaffold(
        key: const ValueKey('booking-detail-map-teardown-placeholder'),
        appBar: _appBar(context),
        body: const SizedBox.expand(),
      );
    }

    final fullBleedMap = _fullBleedMapFor(booking, role, isSearching);
    _showingMapLayout = fullBleedMap != null;
    if (fullBleedMap != null) {
      return _mapLifecycleLayout(context, theme, booking, role, isSearching, fullBleedMap);
    }

    return Scaffold(
      key: const ValueKey('booking-detail-plain-layout'),
      appBar: _appBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (booking.pendingReschedule != null) ...[
              _rescheduleBanner(context, ref, booking),
              const SizedBox(height: 20),
            ],
            ...buildBookingDetailContent(theme, booking, role),
          ],
        ),
      ),
      bottomNavigationBar: _stickyFooter(context, ref, booking, role, isSearching),
    );
  }

  Widget _rescheduleBanner(BuildContext context, WidgetRef ref, Booking booking) => RescheduleBanner(
        proposal: booking.pendingReschedule!,
        currentUserId: ref.watch(authProvider).userId,
        onAccept: () => _respondReschedule(
            context, ref, booking.pendingReschedule!.id, RescheduleActionName.accept),
        onReject: () => _respondReschedule(
            context, ref, booking.pendingReschedule!.id, RescheduleActionName.reject),
        onWithdraw: () => _respondReschedule(
            context, ref, booking.pendingReschedule!.id, RescheduleActionName.withdraw),
      );

  Widget _mapLifecycleLayout(
    BuildContext context,
    ThemeData theme,
    Booking booking,
    UserRole role,
    bool isSearching,
    Widget map,
  ) {
    return Scaffold(
      key: const ValueKey('booking-detail-map-layout'),
      body: Stack(
        children: [
          Positioned.fill(child: map),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.18,
            maxChildSize: 1.0,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16)],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isSearching) ...[_searchStatusCard(theme, booking), const SizedBox(height: 16)],
                  if (booking.status == BookingStatusName.inProgress) ...[
                    _progressStatusCard(theme, booking),
                    const SizedBox(height: 16),
                  ],
                  if (booking.pendingReschedule != null) ...[
                    _rescheduleBanner(context, ref, booking),
                    const SizedBox(height: 16),
                  ],
                  BookingActionBar(
                    status: booking.status,
                    viewerRole: role,
                    isScheduled: booking.bookingType == BookingTypeName.scheduled,
                    paymentMethod: PaymentMethodApi.fromApiName(booking.paymentMethod),
                    scheduledStartTime: booking.scheduledStartTime ?? DateTime.now(),
                    statusTimeline: booking.statusTimeline,
                    onChat: () => context.push('/chat/${widget.bookingId}'),
                    onAccept: () => _accept(context, ref),
            onHideJob: () => _hideJob(context, ref),
                    onGoingThere: () => _advance(context, ref, BookingStatusName.onTheWay),
                    onStart: () => _advance(context, ref, BookingStatusName.inProgress),
                    onFinish: () => _advance(context, ref, BookingStatusName.pendingPayment),
                    onConfirmCash: () => _advance(context, ref, BookingStatusName.completed),
                    onPayNow: () => _payNow(context, ref),
                    onSwitchToCash: () => _switchToCash(context, ref),
                    onCancelByClient: () => _cancelByClient(context, ref),
                    onWorkerCancel: (reasonCode, freeText) =>
                        _workerCancelWithReason(context, ref, reasonCode, freeText),
                    onClientCancel: (reasonCode, freeText) =>
                        _clientCancelWithReason(context, ref, reasonCode, freeText),
                    onReport: (reasonCode, freeText) =>
                        _reportBooking(context, ref, reasonCode, freeText),
                    onProposeReschedule: (newStartTime, message) =>
                        _proposeReschedule(context, ref, newStartTime, message),
                    onRetryAsNewBooking: () => _retryAsNewBooking(context, ref, booking),
                    onAdjustDuration: () => _adjustDuration(context, ref, booking),
                    onViewEarning: () => context.push('/worker/wallet'),
                    onViewReason: () => _showCancellationReason(context, booking),
                  ),
                  const SizedBox(height: 20),
                  ...buildBookingDetailContent(theme, booking, role),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _floatingBackButton(context),
            ),
          ),
          if (_liveDistanceMeters != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Align(alignment: Alignment.topRight, child: _distanceBadge(theme)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _floatingBackButton(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      );

  Widget _searchStatusCard(ThemeData theme, Booking booking) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Đang tìm nhân viên phù hợp…', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            Text(formatSearchElapsed(booking), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      );

  Widget _progressStatusCard(ThemeData theme, Booking booking) {
    final startedAt = booking.actualStartTime;
    if (startedAt == null) return const SizedBox.shrink();

    final elapsed = DateTime.now().difference(startedAt);
    final target = Duration(minutes: (booking.durationHours * 60).round());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đã làm ${_formatJobDuration(elapsed)} / Dự kiến ${_formatJobDuration(target)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatJobDuration(Duration d) {
    final hours = d.inHours;
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  AppBar _appBar(BuildContext context) => AppBar(
        title: const Text('Chi tiết đơn đặt lịch', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      );

  Widget _stickyFooter(BuildContext context, WidgetRef ref, Booking booking, UserRole role, bool isSearching) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: BookingActionBar(
            status: booking.status,
            viewerRole: role,
            isScheduled: booking.bookingType == BookingTypeName.scheduled,
            paymentMethod: PaymentMethodApi.fromApiName(booking.paymentMethod),
            scheduledStartTime: booking.scheduledStartTime ?? DateTime.now(),
            statusTimeline: booking.statusTimeline,
            onChat: () => context.push('/chat/${widget.bookingId}'),
            onAccept: () => _accept(context, ref),
            onHideJob: () => _hideJob(context, ref),
            onGoingThere: () => _advance(context, ref, BookingStatusName.onTheWay),
            onStart: () => _advance(context, ref, BookingStatusName.inProgress),
            onFinish: () => _advance(context, ref, BookingStatusName.pendingPayment),
            onConfirmCash: () => _advance(context, ref, BookingStatusName.completed),
            onPayNow: () => _payNow(context, ref),
            onSwitchToCash: () => _switchToCash(context, ref),
            onCancelByClient: () => _cancelByClient(context, ref),
            onWorkerCancel: (reasonCode, freeText) =>
                _workerCancelWithReason(context, ref, reasonCode, freeText),
            onClientCancel: (reasonCode, freeText) =>
                _clientCancelWithReason(context, ref, reasonCode, freeText),
            onReport: (reasonCode, freeText) => _reportBooking(context, ref, reasonCode, freeText),
            onProposeReschedule: (newStartTime, message) =>
                _proposeReschedule(context, ref, newStartTime, message),
            onRetryAsNewBooking: () => _retryAsNewBooking(context, ref, booking),
            onAdjustDuration: () => _adjustDuration(context, ref, booking),
            onViewEarning: () => context.push('/worker/wallet'),
            onViewReason: () => _showCancellationReason(context, booking),
          ),
        ),
      ),
    );
  }

  Widget? _fullBleedMapFor(Booking booking, UserRole role, bool isSearching) {
    if (booking.status == BookingStatusName.completed) return null;
    if (booking.status == BookingStatusName.cancelled) return null;
    if (booking.status == BookingStatusName.awaitingWorker) {
      return NearbyWorkersGoogleMap(booking: booking, viewerRole: role);
    }

    return LiveTrackingMap(
      bookingId: widget.bookingId,
      booking: booking,
      viewerRole: role,
      fullBleed: true,
      showRoute: booking.status == BookingStatusName.accepted || booking.status == BookingStatusName.onTheWay,
      onDistanceUpdate: (distanceMeters, route) {
        if (!mounted) return;
        if (distanceMeters == _liveDistanceMeters && route == _liveRoute) return;
        setState(() {
          _liveDistanceMeters = distanceMeters;
          _liveRoute = route;
        });
      },
    );
  }

  Widget _distanceBadge(ThemeData theme) {
    final distance = _liveDistanceMeters;
    final route = _liveRoute;
    if (distance == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
      ),
      child: Text(
        route != null
            ? 'Cách ${route.distanceText} · ${route.durationText}'
            : 'Cách ${formatDistance(distance)} · ${formatDuration(estimatedTravelDuration(distance))}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
