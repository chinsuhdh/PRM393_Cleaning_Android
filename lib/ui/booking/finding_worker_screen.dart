import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/models/worker.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/worker_repository.dart';
import 'widgets/finding_worker_map.dart';

/// After a booking is created it is offered to eligible workers. This screen watches the booking's
/// status until a worker accepts. Immediate bookings show a live GPS-style map with nearby workers
/// and a countdown; scheduled bookings show a simpler "request sent, please wait" state.
class FindingWorkerScreen extends ConsumerStatefulWidget {
  final String bookingId;

  /// How long to keep searching (for Immediate bookings) before showing the timed-out state.
  final Duration searchTimeout;

  const FindingWorkerScreen({
    super.key,
    required this.bookingId,
    this.searchTimeout = const Duration(seconds: 90),
  });

  @override
  ConsumerState<FindingWorkerScreen> createState() => _FindingWorkerScreenState();
}

class _FindingWorkerScreenState extends ConsumerState<FindingWorkerScreen>
    with SingleTickerProviderStateMixin {
  static const _pollInterval = Duration(seconds: 4);

  late final AnimationController _progress;

  Timer? _timer;
  Booking? _booking;
  bool _loading = true;
  bool _failed = false;
  bool _timedOut = false;
  bool _cancelling = false;
  bool _searchStarted = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: widget.searchTimeout)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _onTimeout();
      });
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final booking =
        await ref.read(bookingRepositoryProvider).getBookingById(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (booking == null) {
        _failed = true;
      } else {
        _booking = booking;
        _failed = false;
        if (booking.hasWorkerAssigned || booking.status == 'Cancelled') {
          _stopSearch();
        } else if (booking.isImmediate && !_searchStarted) {
          // Only Immediate bookings run the countdown / time limit.
          _searchStarted = true;
          _progress.forward();
        }
      }
    });
    if (booking?.isImmediate == true && !booking!.hasWorkerAssigned) {
      ref.invalidate(recommendedWorkersProvider(widget.bookingId));
    }
  }

  void _stopSearch() {
    _timer?.cancel();
    if (_progress.isAnimating) _progress.stop();
  }

  void _onTimeout() {
    if (!mounted) return;
    final booking = _booking;
    if (booking != null && (booking.hasWorkerAssigned || booking.status == 'Cancelled')) {
      return;
    }
    setState(() => _timedOut = true);
    _timer?.cancel();
  }

  void _keepWaiting() {
    setState(() => _timedOut = false);
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
    _progress
      ..reset()
      ..forward();
    _refresh();
  }

  Future<void> _cancelBooking() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(bookingRepositoryProvider).cancelBooking(widget.bookingId);
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể hủy đơn: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đang tìm nhân viên', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final booking = _booking;
    if (_failed || booking == null) {
      return _ErrorState(onRetry: _refresh);
    }
    if (booking.hasWorkerAssigned) {
      return _AssignedState(booking: booking);
    }
    if (booking.status == 'Cancelled') {
      return const _CancelledState();
    }
    if (_timedOut) {
      return _TimedOutState(
        booking: booking,
        cancelling: _cancelling,
        onKeepWaiting: _keepWaiting,
        onCancel: _cancelBooking,
      );
    }
    if (booking.isImmediate) {
      final workers = ref
          .watch(recommendedWorkersProvider(widget.bookingId))
          .maybeWhen(data: (list) => list, orElse: () => const <Worker>[]);
      return FindingWorkerMap(
        booking: booking,
        nearbyWorkers: workers,
        progress: _progress,
        cancelling: _cancelling,
        onCancel: _cancelBooking,
      );
    }
    return _ScheduledWaitingView(
      booking: booking,
      cancelling: _cancelling,
      onCancel: _cancelBooking,
    );
  }
}

class _ScheduledWaitingView extends StatelessWidget {
  final Booking booking;
  final bool cancelling;
  final VoidCallback onCancel;

  const _ScheduledWaitingView({
    required this.booking,
    required this.cancelling,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: kPrimaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.event_available_rounded, size: 52, color: kPrimary),
          ),
          const SizedBox(height: 24),
          Text(
            'Đã gửi yêu cầu thành công!',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Yêu cầu đặt lịch của bạn đã được gửi tới các nhân viên phù hợp. '
            'Vui lòng chờ nhân viên nhận đơn — bạn sẽ được thông báo ngay khi có người nhận.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          _BookingSummaryCard(booking: booking),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: cancelling ? null : onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: theme.colorScheme.error,
              ),
              child: cancelling
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Hủy đơn'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedState extends StatelessWidget {
  final Booking booking;
  const _AssignedState({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: kPrimaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, size: 56, color: kPrimary),
          ),
          const SizedBox(height: 24),
          Text(
            'Đã có nhân viên nhận đơn!',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            booking.worker != null
                ? '${booking.worker!.name} sẽ thực hiện dịch vụ của bạn.'
                : 'Một nhân viên đã nhận và sẽ thực hiện dịch vụ của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          _BookingSummaryCard(booking: booking),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/booking/${booking.id}'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Xem chi tiết đơn'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimedOutState extends StatelessWidget {
  final Booking booking;
  final bool cancelling;
  final VoidCallback onKeepWaiting;
  final VoidCallback onCancel;

  const _TimedOutState({
    required this.booking,
    required this.cancelling,
    required this.onKeepWaiting,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_bottom_rounded, size: 64, color: theme.colorScheme.tertiary),
          const SizedBox(height: 20),
          Text(
            'Chưa có nhân viên nào nhận đơn',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Hiện chưa có nhân viên phù hợp nhận đơn của bạn. '
            'Bạn có thể tiếp tục chờ hoặc hủy đơn này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          _BookingSummaryCard(booking: booking),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: cancelling ? null : onKeepWaiting,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Tiếp tục chờ'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: cancelling ? null : onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: theme.colorScheme.error,
              ),
              child: cancelling
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Hủy đơn'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledState extends StatelessWidget {
  const _CancelledState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Đơn đặt lịch đã bị hủy.',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('Không tải được trạng thái đơn.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  final Booking booking;
  const _BookingSummaryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(booking.serviceName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (booking.date.isNotEmpty || booking.time.isNotEmpty)
            _SummaryRow(
              icon: Icons.access_time_rounded,
              text: booking.isImmediate
                  ? 'Ngay bây giờ'
                  : [booking.date, booking.time].where((v) => v.isNotEmpty).join(' • '),
            ),
          if (booking.addressText != null && booking.addressText!.isNotEmpty)
            _SummaryRow(icon: Icons.location_on_rounded, text: booking.addressText!),
          _SummaryRow(
            icon: Icons.payments_rounded,
            text: '${booking.price.toStringAsFixed(0)} ₫',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SummaryRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
