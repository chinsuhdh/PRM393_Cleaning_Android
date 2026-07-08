import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/booking_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';

class WorkerActiveJobBar extends ConsumerStatefulWidget {
  const WorkerActiveJobBar({super.key, this.pollInterval = const Duration(seconds: 6)});

  final Duration pollInterval;

  @override
  ConsumerState<WorkerActiveJobBar> createState() => _WorkerActiveJobBarState();
}

class _WorkerActiveJobBarState extends ConsumerState<WorkerActiveJobBar> {
  Timer? _timer;
  Booking? _active;

  // Lower rank = more urgent to surface: a job actually being worked right now matters more than one
  // that's merely been accepted.
  static const _statusRank = {
    BookingStatusName.inProgress: 0,
    BookingStatusName.onTheWay: 1,
    BookingStatusName.pendingPayment: 2,
    BookingStatusName.accepted: 3,
    BookingStatusName.rescheduleRequested: 4,
  };

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(widget.pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    List<Booking> bookings;
    try {
      bookings = await ref.read(bookingRepositoryProvider).getWorkerBookings();
    } catch (_) {
      return;
    }
    if (!mounted) return;

    final active = bookings.where((b) => _statusRank.containsKey(b.status)).toList()
      ..sort((a, b) {
        final rank = _statusRank[a.status]!.compareTo(_statusRank[b.status]!);
        if (rank != 0) return rank;
        return (a.scheduledStartTime ?? DateTime(9999)).compareTo(b.scheduledStartTime ?? DateTime(9999));
      });

    final next = active.isEmpty ? null : active.first;
    if (next?.id != _active?.id) setState(() => _active = next);
  }

  String _subtitleFor(Booking booking) {
    switch (booking.status) {
      case BookingStatusName.onTheWay:
        return 'Bạn đang trên đường đến';
      case BookingStatusName.inProgress:
        return 'Công việc đang thực hiện';
      case BookingStatusName.pendingPayment:
        return 'Đã xong việc — chờ khách thanh toán';
      case BookingStatusName.rescheduleRequested:
        return 'Yêu cầu đổi lịch đang chờ xác nhận';
      default:
        return 'Bạn đã nhận đơn này';
    }
  }

  IconData _iconFor(Booking booking) {
    switch (booking.status) {
      case BookingStatusName.onTheWay:
        return Icons.directions_car_filled_rounded;
      case BookingStatusName.inProgress:
        return Icons.cleaning_services_rounded;
      case BookingStatusName.pendingPayment:
        return Icons.payments_rounded;
      case BookingStatusName.rescheduleRequested:
        return Icons.event_repeat_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _active;
    if (booking == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Material(
        color: kPrimaryContainer,
        child: InkWell(
          onTap: () => context.push('/booking/${booking.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(_iconFor(booking), color: kPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        booking.serviceName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: kOnPrimaryContainer,
                        ),
                      ),
                      Text(
                        _subtitleFor(booking),
                        style: theme.textTheme.bodySmall?.copyWith(color: kOnPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: kPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
