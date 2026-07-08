import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/dispatch_hub_service.dart';
import '../../core/constants/booking_enums.dart';
import '../../core/utils/search_timeout.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'widgets/booking_action_bar.dart';
import 'widgets/booking_review_section.dart';
import 'widgets/live_tracking_map.dart';
import 'widgets/nearby_workers_google_map.dart';

final bookingDetailProvider = FutureProvider.autoDispose.family<Booking, String>((ref, id) async {
  final response = await DioClient.instance.get('/Bookings/$id');
  return Booking.fromJson(response.data);
});

/// Passed as `extra` on the `pushReplacement` in [_BookingDetailScreenState._reloadFresh] so the
/// `/booking/:id` route's `pageBuilder` (see `app_router.dart`) can skip the page-transition
/// animation for that one navigation. `_reloadFresh` replaces this screen with a fresh instance of
/// itself after every status change, and the outgoing instance can have a live GoogleMap platform
/// view mid-teardown (`NearbyWorkersGoogleMap` while searching/awaiting, `LiveTrackingMap` while
/// onTheWay). Animating a route transition over that teardown window corrupts the native view's
/// compositing surface on real Android devices/emulators — the incoming page renders blank with only
/// a stray leftover widget until an unrelated external repaint (rotate, background/foreground, tap)
/// forces a full recomposite. This never reproduces in `flutter test`: `google_maps_flutter` doesn't
/// run a real platform view there, so there is no teardown window to corrupt anything.
const kBookingDetailSkipTransitionExtra = 'booking-detail-skip-transition';

/// One consistent shell for the whole booking lifecycle: same app bar, same info-card layout, same
/// sticky action bar at the bottom, for every status that has no map. Statuses that DO have a map
/// (Immediate "searching", a worker previewing an unaccepted job, OnTheWay) instead get a full-bleed
/// map behind a Grab/Uber-style draggable bottom sheet holding the same cards + action bar.
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
  bool _liveUpdatesWired = false;
  String? _lastKnownStatus;
  bool _selfCancelling = false;
  bool _cancelledPopupShown = false;
  bool _hasResolvedOnce = false;
  bool _showingMapLayout = false;
  bool _mapTornDown = false;

  @override
  void initState() {
    super.initState();
    _wireLiveUpdates();
  }

  /// Joins the `booking:{bookingId}` SignalR group so this screen live-updates the instant the
  /// *other* party changes the status (worker taps "Going there" while the client is looking at the
  /// screen, etc.) instead of only refreshing on the searching/OnTheWay poll timers.
  void _wireLiveUpdates() {
    if (_liveUpdatesWired) return;
    _liveUpdatesWired = true;
    final client = ref.read(dispatchHubClientProvider);
    client.onBookingStatusChanged(() {
      if (!mounted) return;
      ref.invalidate(bookingDetailProvider(widget.bookingId));
    });
    unawaited(() async {
      try {
        await client.connect();
        await client.subscribeToBooking(widget.bookingId);
      } catch (_) {
        // Best-effort: the screen still works via its own poll timers without the live push.
      }
    }());
  }

  /// Lazily starts/stops the countdown + poll timer as the booking enters/leaves the client's
  /// Immediate-searching state. The countdown itself is always derived from `booking.createdAt`/
  /// `updatedAt` (not from when this timer started) so it survives leaving and re-opening the screen,
  /// and restarts on a retry — it never just resets to "0 elapsed" locally.
  void _ensureSearchTracking(bool isSearching) {
    if (isSearching && _searchTicker == null) {
      _searchTickCount = 0;
      _searchTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        _searchTickCount++;
        if (_searchTickCount % _searchPollInterval.inSeconds == 0) _refreshBooking();
        if (mounted) setState(() {});
      });
    } else if (!isSearching && _searchTicker != null) {
      _searchTicker!.cancel();
      _searchTicker = null;
    }
  }

  void _refreshBooking() => ref.invalidate(bookingDetailProvider(widget.bookingId));

  /// Retry abandons this search entirely: cancels the current booking (so it stops broadcasting and
  /// no longer blocks a new Immediate booking) and sends the client back to the request-creation flow
  /// for the same service, to start fresh.
  Future<void> _retryAsNewBooking(BuildContext context, WidgetRef ref, Booking booking) async {
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(
            widget.bookingId,
            BookingStatusName.cancelled,
            reason: 'Khách hàng muốn đặt lại yêu cầu mới.',
          );
      ref.invalidate(bookingsProvider);
    } catch (_) {
      // Best-effort — still let them start a fresh request even if cancelling the old one failed.
    }
    if (!context.mounted) return;
    context.pushReplacement('/booking/create/${booking.serviceId}');
  }

  /// If the booking flips to Cancelled while this screen is open and it wasn't this screen's own
  /// "Cancel booking" tap that did it, the other party (or the system) cancelled it out from under
  /// whoever is looking at it right now — tell them and take them back to wherever they came from.
  Future<void> _showCancelledByOtherPartyPopup() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đơn đã bị hủy'),
        content: const Text('Đơn đặt lịch này đã bị hủy.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đã hiểu')),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _searchTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));
    // `valueOrNull` (not `.when`) so a background poll (searching countdown / live tracking) keeps
    // showing the last-known booking instead of flashing a full-screen spinner every few seconds.
    final booking = bookingAsync.valueOrNull;

    // `bookingDetailProvider` is a `FutureProvider.autoDispose.family`: when it's invalidated while a
    // listener still exists (as `_reloadFresh` does right before navigating to a brand-new instance
    // of this screen), Riverpod's `AsyncLoading` keeps the *previous* value available via
    // `valueOrNull` so an in-place refresh doesn't flash a spinner — but that previous value is
    // shared by every watcher of this family key, including a brand-new instance that just mounted
    // and has never seen real data of its own yet. Without `_hasResolvedOnce`, a fresh instance's
    // first build could render using the *old*, pre-update booking (e.g. still `AwaitingWorker` right
    // after this same instance's own cancel/accept already committed the new status), taking that
    // stale value as `_lastKnownStatus` — so moments later, when the real fetch resolves, the jump to
    // the new status looks exactly like an external change and wrongly fires the "cancelled by the
    // other party" popup below, on top of redoing the map-layout-to-plain-layout swap this whole
    // reload mechanism exists to avoid. Waiting for this instance's own first non-loading resolution
    // closes that gap: a fresh instance's `_lastKnownStatus` baseline is always genuinely fresh data.
    if (booking == null || (!_hasResolvedOnce && bookingAsync.isLoading)) {
      return Scaffold(
        key: const ValueKey('booking-detail-loading-layout'),
        appBar: _appBar(context),
        body: bookingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _BookingLoadError(
            error: e,
            onRetry: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
          ),
          data: (_) => const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    _hasResolvedOnce = true;

    // If this booking flips to Cancelled while the screen is open — from the *other* party, not this
    // screen's own "Cancel booking" tap — surface it immediately instead of silently re-rendering a
    // now-dead booking underneath the user.
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

    // `_reloadFresh` sets this before navigating away, to unmount a live GoogleMap under an ordinary
    // rebuild first (see `_reloadFresh`'s doc comment) instead of leaving that teardown to race the
    // Navigator's route replace. This placeholder is what that rebuild lands on — distinctly keyed so
    // it's a clean unmount of the map Scaffold, not an in-place patch. Deliberately no spinner/animation
    // here: it's only ever on screen for a fraction of a second before the route replace lands, and an
    // indeterminate `CircularProgressIndicator`'s repeating ticker would (correctly) keep
    // `pumpAndSettle()` from ever settling in widget tests that exercise this same flow.
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

    // Keyed distinctly from the map layout's Scaffold below: a status change (e.g. cancelling while
    // searching, or "Start job" while OnTheWay) can flip this screen between the map layout and this
    // plain one *without navigating away* — same BookingDetailScreen instance, drastically different
    // Scaffold shape (Stack+DraggableScrollableSheet vs. SingleChildScrollView+AppBar). Without a key,
    // Flutter tries to patch one Scaffold into the other in place instead of a clean unmount/remount,
    // which is what corrupted the render (footer widgets left behind, everything else blank).
    return Scaffold(
      key: const ValueKey('booking-detail-plain-layout'),
      appBar: _appBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _detailContent(theme, booking, role),
        ),
      ),
      bottomNavigationBar: _stickyFooter(context, ref, booking, role, isSearching),
    );
  }

  /// Grab/Uber-style layout for the map-bearing lifecycle moments: a full-bleed map fills the whole
  /// body, a floating back button sits over it, and a draggable sheet holding the same info/price/
  /// action-bar content as every other status can be pulled up for detail or left collapsed to just
  /// the summary + primary action.
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
                  BookingActionBar(
                    status: booking.status,
                    viewerRole: role,
                    isScheduled: booking.bookingType == BookingTypeName.scheduled,
                    statusTimeline: booking.statusTimeline,
                    onChat: () => context.push('/chat/${widget.bookingId}'),
                    onAccept: () => _accept(context, ref),
                    onGoingThere: () => _advance(context, ref, BookingStatusName.onTheWay),
                    onStart: () => _advance(context, ref, BookingStatusName.inProgress),
                    onFinish: () => _advance(context, ref, BookingStatusName.pendingPayment),
                    onConfirmCash: () => _advance(context, ref, BookingStatusName.completed),
                    onReleaseJob: () => _advance(context, ref, BookingStatusName.awaitingWorker),
                    onReport: (reason) => _cancel(context, ref, reason),
                    onRetryAsNewBooking: () => _retryAsNewBooking(context, ref, booking),
                    onRequestReschedule: () => _advance(context, ref, BookingStatusName.rescheduleRequested),
                    onApproveReschedule: () => _advance(context, ref, BookingStatusName.accepted),
                    onPayNow: () => context.push('/payment/${booking.id}'),
                    onReview: () => context.push('/review/${booking.id}'),
                    onViewEarning: () => context.push('/worker/wallet'),
                    onViewReason: () => _showCancellationReason(context, booking),
                  ),
                  const SizedBox(height: 20),
                  ..._detailContent(theme, booking, role),
                ],
              ),
            ),
          ),
          // Painted last so it always stays on top of the sheet, including when the sheet is
          // dragged to maxChildSize (the very top of the screen).
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _floatingBackButton(context),
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

  AppBar _appBar(BuildContext context) => AppBar(
        title: const Text('Booking Detail', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      );

  List<Widget> _detailContent(ThemeData theme, Booking booking, UserRole role) {
    final isCompleted = booking.status == BookingStatusName.completed;
    return [
      _summaryCard(theme, booking),
      const SizedBox(height: 20),
      if (isCompleted && booking.latitude != null && booking.longitude != null) ...[
        _CompletedJobLocationCard(booking: booking),
        const SizedBox(height: 16),
      ],
      _InfoCard(title: 'Booking Details', rows: _tripInfoRows(booking)),
      const SizedBox(height: 16),
      _PriceCard(booking: booking),
      if (booking.bookingQuestions.isNotEmpty) ...[
        const SizedBox(height: 16),
        _InfoCard(title: 'Service requirements', rows: _questionRows(booking)),
      ],
      if (booking.photos.isNotEmpty) ...[const SizedBox(height: 16), _photosRow(booking)],
      if (booking.worker != null) ...[const SizedBox(height: 16), _workerCard(theme, context, booking)],
      if (isCompleted && booking.worker != null) ...[
        const SizedBox(height: 16),
        BookingReviewSection(booking: booking, viewerRole: role),
      ],
    ];
  }

  Widget _summaryCard(ThemeData theme, Booking booking) => Card(
        elevation: 0,
        color: kPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.cleaning_services_rounded, size: 48, color: kPrimary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800, color: kOnPrimaryContainer)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(8)),
                      child: Text(booking.status,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  List<(String, String)> _tripInfoRows(Booking booking) => [
        (
          'Date & Time',
          booking.isImmediate ? 'Now' : [booking.date, booking.time].where((v) => v.isNotEmpty).join(' • '),
        ),
        ('Duration', '${booking.durationHours.toStringAsFixed(1)} hours'),
        if (booking.addressText?.isNotEmpty == true) ('Address', booking.addressText!),
        if (booking.notes.isNotEmpty) ('Notes', booking.notes),
      ];

  List<(String, String)> _questionRows(Booking booking) => booking.bookingQuestions.map((question) {
        final id = question['id']?.toString() ?? question['key']?.toString() ?? '';
        final label = question['label']?.toString() ?? question['title']?.toString() ?? id;
        final answer = booking.optionAnswers[id];
        return (label, answer == null ? 'Not specified' : _formatAnswer(answer));
      }).toList();

  Widget _photosRow(Booking booking) => SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: booking.photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(booking.photos[index]['photoUrl'].toString(), width: 96, fit: BoxFit.cover),
          ),
        ),
      );

  Widget _workerCard(ThemeData theme, BuildContext context, Booking booking) => Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: (booking.worker!.avatarUrl?.isNotEmpty ?? false)
              ? CircleAvatar(backgroundImage: NetworkImage(booking.worker!.avatarUrl!))
              : CircleAvatar(
                  backgroundColor: kPrimaryContainer,
                  child: Text(booking.worker!.initials,
                      style: const TextStyle(color: kOnPrimaryContainer, fontWeight: FontWeight.w700)),
                ),
          title: Text(booking.worker!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: kTertiary),
              const SizedBox(width: 4),
              Text('${booking.worker!.rating} · ${booking.worker!.reviews} reviews'),
            ],
          ),
        ),
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
            statusTimeline: booking.statusTimeline,
            onChat: () => context.push('/chat/${widget.bookingId}'),
            onAccept: () => _accept(context, ref),
            onGoingThere: () => _advance(context, ref, BookingStatusName.onTheWay),
            onStart: () => _advance(context, ref, BookingStatusName.inProgress),
            onFinish: () => _advance(context, ref, BookingStatusName.pendingPayment),
            onConfirmCash: () => _advance(context, ref, BookingStatusName.completed),
            onReleaseJob: () => _advance(context, ref, BookingStatusName.awaitingWorker),
            onReport: (reason) => _cancel(context, ref, reason),
            onRetryAsNewBooking: () => _retryAsNewBooking(context, ref, booking),
            onRequestReschedule: () => _advance(context, ref, BookingStatusName.rescheduleRequested),
            onApproveReschedule: () => _advance(context, ref, BookingStatusName.accepted),
            onPayNow: () => context.push('/payment/${booking.id}'),
            onReview: () => context.push('/review/${booking.id}'),
            onViewEarning: () => context.push('/worker/wallet'),
            onViewReason: () => _showCancellationReason(context, booking),
          ),
        ),
      ),
    );
  }

  Future<void> _reloadFresh(WidgetRef ref) async {
    ref.invalidate(bookingDetailProvider(widget.bookingId));
    if (!mounted) return;
    if (_showingMapLayout && !_mapTornDown) {
      setState(() => _mapTornDown = true);
      await WidgetsBinding.instance.endOfFrame;
      for (var i = 0; i < 8; i++) {
        if (!mounted) return;
        setState(() {});
        await WidgetsBinding.instance.endOfFrame;
      }
    }
    if (!mounted) return;
    context.pushReplacement('/booking/${widget.bookingId}', extra: kBookingDetailSkipTransitionExtra);
  }

  Future<void> _advance(BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(widget.bookingId, newStatus);
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
      await _reloadFresh(ref);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật trạng thái: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingRepositoryProvider).acceptBooking(widget.bookingId);
      ref.invalidate(availableBookingsProvider);
      ref.invalidate(workerBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhận đơn thành công!')),
        );
      }
      await _reloadFresh(ref);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, String reason) async {
    // Guards the "cancelled while viewing" popup from also firing for this screen's own cancel —
    // that flow already gets its own feedback (the snackbar below).
    _selfCancelling = true;
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(
            widget.bookingId,
            BookingStatusName.cancelled,
            reason: reason.isEmpty ? null : reason,
          );
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy Booking thành công!')));
      await _reloadFresh(ref);
    } catch (e) {
      _selfCancelling = false;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi hủy đơn: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCancellationReason(BuildContext context, Booking booking) {
    final cancelEntry = booking.statusTimeline.lastWhere(
      (entry) => entry['newStatus']?.toString() == BookingStatusName.cancelled,
      orElse: () => const {},
    );
    final reason = (cancelEntry['reason'] as String?)?.trim();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lý do hủy đơn'),
        content: Text(reason == null || reason.isEmpty ? 'Không có lý do được cung cấp.' : reason),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng')),
        ],
      ),
    );
  }

  String _formatAnswer(Object answer) {
    if (answer is bool) return answer ? 'Yes' : 'No';
    if (answer is List) return answer.join(', ');
    return answer.toString();
  }

  Widget? _fullBleedMapFor(Booking booking, UserRole role, bool isSearching) {
    // Completed/Cancelled are the only statuses that ever drop the map: nothing left to track once
    // the job is over, one way or the other — just the plain booking-data layout below with its
    // status-appropriate action (Review/View earning, or View reason).
    if (booking.status == BookingStatusName.completed) return null;
    if (booking.status == BookingStatusName.cancelled) return null;
    if (booking.status == BookingStatusName.awaitingWorker) {
      // Not yet accepted: everyone sees the nearby-workers map — client and worker alike, Immediate
      // and Scheduled alike. Only the searching countdown card stays Immediate-client-only
      // (isSearching), since a Scheduled booking has no live "finding you someone now" phase.
      return NearbyWorkersGoogleMap(booking: booking);
    }
    // Accepted onward (Accepted, OnTheWay, InProgress, PendingPayment, RescheduleRequested): a worker
    // is assigned, so the map — and their live GPS position — stays up for the rest of the lifecycle.
    // The route line/ETA only draws through OnTheWay (see LiveTrackingMap.showRoute): once InProgress
    // the worker has already arrived, so there's nothing left to route to.
    return LiveTrackingMap(
      bookingId: widget.bookingId,
      booking: booking,
      viewerRole: role,
      fullBleed: true,
      showRoute: booking.status == BookingStatusName.accepted || booking.status == BookingStatusName.onTheWay,
    );
  }
}

/// A 403/404 here means the booking is no longer viewable by this account — most often a job that
/// was still cached in a worker's list but got cancelled/taken in the meantime (§ E.1: an unassigned,
/// no-longer-AwaitingWorker booking fails the eligibility check `GetBookingByIdAsync` falls back to).
/// That is a normal race, not a technical failure, so it gets its own friendly message instead of a
/// raw DioException dump; anything else is a real load failure with a retry option.
class _BookingLoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _BookingLoadError({required this.error, required this.onRetry});

  bool get _noLongerViewable {
    final e = error;
    if (e is DioException) {
      final status = e.response?.statusCode;
      return status == 403 || status == 404;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_noLongerViewable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 16),
              const Text(
                'Đơn này không còn khả dụng.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    final message = error is DioException
        ? backendMessageFromDioException(error as DioException, fallback: 'Không thể tải dữ liệu đơn.')
        : 'Không thể tải dữ liệu đơn.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

/// A small, static (no polling, no worker marker) map card for a Completed booking's job location —
/// bounded, not full-bleed, unlike the live-lifecycle map. Deliberately not `LiveTrackingMap`: that
/// widget polls the worker's position every ~10s forever, which is wrong once the job is done and
/// the worker has stopped sending updates.
const _osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgentPackageName = 'com.example.cleanai';

class _CompletedJobLocationCard extends StatelessWidget {
  const _CompletedJobLocationCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final location = LatLng(booking.latitude!, booking.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          key: const ValueKey('completed-job-location-map'),
          options: MapOptions(
            initialCenter: location,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: _osmTileUrlTemplate,
              userAgentPackageName: _osmUserAgentPackageName,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  key: const ValueKey('job-location'),
                  point: location,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_pin, color: kPrimary, size: 40),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A clean grouped card of label/value rows separated by thin dividers — replaces the old repeated
/// icon-square-per-field treatment, which read as noisy once there were more than a couple of rows.
class _InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (var i = 0; i < rows.length; i++) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(rows[i].$1,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(rows[i].$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

/// Receipt-style price breakdown: line items, then Total set apart with its own divider and heavier
/// styling so it reads as the one number that actually matters.
class _PriceCard extends StatelessWidget {
  final Booking booking;
  const _PriceCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _line(theme, 'Unit price', booking.unitPrice),
            if (booking.extraFee != 0) _line(theme, 'Extra fee', booking.extraFee),
            if (booking.discountAmount != 0) _line(theme, 'Discount', -booking.discountAmount),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text('${booking.price.toStringAsFixed(0)} VND',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(ThemeData theme, String label, double amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            Text('${amount < 0 ? '-' : ''}${amount.abs().toStringAsFixed(0)} VND'),
          ],
        ),
      );
}
