import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/booking_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../logic/booking/active_booking_selector.dart';

class WorkerActiveJobBar extends ConsumerStatefulWidget {
  const WorkerActiveJobBar({super.key, this.pollInterval = AppConstants.activeBookingPollInterval});

  final Duration pollInterval;

  @override
  ConsumerState<WorkerActiveJobBar> createState() => _WorkerActiveJobBarState();
}

class _WorkerActiveJobBarState extends ConsumerState<WorkerActiveJobBar> {
  Timer? _timer;
  Booking? _active;

  static const _statusRank = kCoreActiveBookingRank;

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
    } catch (e) {
      debugPrint('[WorkerActiveJobBar] refresh failed: $e');
      return;
    }
    if (!mounted) return;

    final next = selectActiveBooking(bookings, _statusRank);
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
