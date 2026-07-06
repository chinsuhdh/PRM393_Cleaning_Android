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
import '../../data/repositories/dispatch_repository.dart';
import '../../core/constants/booking_enums.dart';
import 'widgets/booking_action_bar.dart';
import 'widgets/live_tracking_map.dart';
import 'widgets/nearby_workers_google_map.dart';

final bookingDetailProvider = FutureProvider.autoDispose.family<Booking, String>((ref, id) async {
  final response = await DioClient.instance.get('/Bookings/$id');
  return Booking.fromJson(response.data);
});

/// One consistent shell for the whole booking lifecycle: same app bar, same info-card layout, same
/// sticky action bar at the bottom, for every status — including the client's Immediate "searching"
/// state, which used to be a completely different full-screen experience. Only the map slot and the
/// content of the sticky footer change; the surrounding chrome never does.
class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _searchPollInterval = Duration(seconds: 4);
  static const _searchTimeout = Duration(minutes: 5);

  AnimationController? _searchProgress;
  Timer? _searchTimer;
  bool _searchTimedOut = false;

  /// Lazily starts/stops the countdown + poll timer as the booking enters/leaves the client's
  /// Immediate-searching state — there's no other lifecycle hook that fires exactly once when a
  /// freshly-fetched booking first satisfies that condition, since it depends on server data.
  void _ensureSearchTracking(bool isSearching) {
    if (isSearching && _searchProgress == null) {
      final controller = AnimationController(vsync: this, duration: _searchTimeout)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _onSearchTimeout();
        });
      _searchProgress = controller;
      controller.forward();
      _searchTimer = Timer.periodic(_searchPollInterval, (_) => _refreshBooking());
    } else if (!isSearching && _searchProgress != null) {
      _searchProgress!.dispose();
      _searchProgress = null;
      _searchTimer?.cancel();
      _searchTimer = null;
      _searchTimedOut = false;
    }
  }

  void _refreshBooking() => ref.invalidate(bookingDetailProvider(widget.bookingId));

  void _onSearchTimeout() {
    if (!mounted) return;
    setState(() => _searchTimedOut = true);
    _searchTimer?.cancel();
  }

  Future<void> _keepWaitingSearch() async {
    try {
      await ref.read(dispatchRepositoryProvider).retryBroadcast(widget.bookingId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _searchTimedOut = false);
    _searchTimer?.cancel();
    _searchTimer = Timer.periodic(_searchPollInterval, (_) => _refreshBooking());
    _searchProgress
      ?..reset()
      ..forward();
  }

  @override
  void dispose() {
    _searchProgress?.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));
    // `valueOrNull` (not `.when`) so a background poll (searching countdown / live tracking) keeps
    // showing the last-known booking instead of flashing a full-screen spinner every few seconds.
    final booking = bookingAsync.valueOrNull;

    if (booking == null) {
      return Scaffold(
        appBar: _appBar(context),
        body: bookingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _BookingLoadError(
            error: e,
            onRetry: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
          ),
          data: (_) => const SizedBox.shrink(), // unreachable — handled by the `booking != null` branch above
        ),
      );
    }

    final role = ref.watch(authProvider).role;
    final isSearching = booking.status == BookingStatusName.awaitingWorker &&
        booking.isImmediate &&
        role == UserRole.client;
    _ensureSearchTracking(isSearching);

    final mapSection = isSearching
        ? _SearchingMapSection(booking: booking, progress: _searchProgress!)
        : _mapSectionFor(booking, role);

    return Scaffold(
      appBar: _appBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(theme, booking),
            if (mapSection != null) ...[const SizedBox(height: 20), mapSection],
            if (isSearching && _searchTimedOut) ...[const SizedBox(height: 20), _timedOutCard(theme)],
            const SizedBox(height: 20),
            _InfoCard(title: 'Booking Details', rows: _tripInfoRows(booking)),
            const SizedBox(height: 16),
            _PriceCard(booking: booking),
            if (booking.bookingQuestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _InfoCard(title: 'Service requirements', rows: _questionRows(booking)),
            ],
            if (booking.photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _photosRow(booking),
            ],
            if (booking.worker != null) ...[
              const SizedBox(height: 16),
              _workerCard(theme, context, booking),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _stickyFooter(context, ref, booking, role, isSearching),
    );
  }

  AppBar _appBar(BuildContext context) => AppBar(
        title: const Text('Booking Detail', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      );

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

  Widget _timedOutCard(ThemeData theme) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_bottom_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chưa có nhân viên nào nhận đơn. Bạn có thể tiếp tục chờ hoặc hủy đơn bên dưới.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
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
          leading: CircleAvatar(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSearching && _searchTimedOut) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _keepWaitingSearch,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('Tiếp tục chờ'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
                onRequestReschedule: () => _advance(context, ref, BookingStatusName.rescheduleRequested),
                onApproveReschedule: () => _advance(context, ref, BookingStatusName.accepted),
                onPayNow: () => context.push('/payment/${booking.id}'),
                onReview: () => context.push('/review/${booking.id}'),
                onViewEarning: () => context.push('/worker/wallet'),
                onViewReason: () => _showCancellationReason(context, booking),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _advance(BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(widget.bookingId, newStatus);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
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
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(availableBookingsProvider);
      ref.invalidate(workerBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nhận đơn thành công!')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, String reason) async {
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(
            widget.bookingId,
            BookingStatusName.cancelled,
            reason: reason.isEmpty ? null : reason,
          );
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(bookingsProvider);
      ref.invalidate(workerBookingsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy Booking thành công!')));
    } catch (e) {
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

  /// A worker deciding whether to accept needs to see where the job actually is, regardless of
  /// booking type (Immediate or Scheduled) — and once OnTheWay, either side needs the live map
  /// (worker's position + destination) until the worker arrives and the job moves to InProgress.
  Widget? _mapSectionFor(Booking booking, UserRole role) {
    if (role == UserRole.worker && booking.status == BookingStatusName.awaitingWorker) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(height: 220, child: NearbyWorkersGoogleMap(booking: booking)),
      );
    }
    if (booking.status == BookingStatusName.onTheWay) {
      return LiveTrackingMap(bookingId: widget.bookingId, booking: booking, viewerRole: role);
    }
    return null;
  }
}

/// The client's map section while an Immediate booking is broadcasting: the same map treatment as
/// every other lifecycle moment (fixed height, rounded corners), with a compact countdown overlay
/// instead of a full separate "searching" screen.
class _SearchingMapSection extends StatelessWidget {
  final Booking booking;
  final Animation<double> progress;
  const _SearchingMapSection({required this.booking, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            Positioned.fill(child: NearbyWorkersGoogleMap(booking: booking)),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Đang tìm nhân viên phù hợp…',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const SizedBox(height: 4),
                          AnimatedBuilder(
                            animation: progress,
                            builder: (context, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress.value,
                                minHeight: 4,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
