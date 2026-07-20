import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/booking_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/search_timeout.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/services/dispatch_hub_service.dart';

class ActiveBookingBar extends ConsumerStatefulWidget {
  const ActiveBookingBar({super.key});

  @override
  ConsumerState<ActiveBookingBar> createState() => _ActiveBookingBarState();
}

class _ActiveBookingBarState extends ConsumerState<ActiveBookingBar> {
  Timer? _elapsedTicker;

  @override
  void dispose() {
    _elapsedTicker?.cancel();
    super.dispose();
  }

  static bool _isSearchingImmediate(Booking? booking) =>
      booking != null && booking.isImmediate && booking.status == BookingStatusName.awaitingWorker;

  void _ensureElapsedTicker(bool searching) {
    if (searching && _elapsedTicker == null) {
      _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!searching && _elapsedTicker != null) {
      _elapsedTicker!.cancel();
      _elapsedTicker = null;
    }
  }

  static final _statusRank = {...kCoreActiveBookingRank, BookingStatusName.awaitingWorker: 5};

  String _subtitleFor(Booking booking) {
    switch (booking.status) {
      case BookingStatusName.accepted:
        return 'Nhân viên đã nhận đơn của bạn';
      case BookingStatusName.onTheWay:
        return 'Nhân viên đang trên đường đến';
      case BookingStatusName.inProgress:
        return 'Công việc đang được thực hiện';
      case BookingStatusName.pendingPayment:
        return 'Đã xong việc — chờ thanh toán';
      case BookingStatusName.rescheduleRequested:
        return 'Yêu cầu đổi lịch đang chờ xác nhận';
      default:
        return booking.isImmediate ? 'Đang tìm nhân viên phù hợp…' : 'Đang chờ nhân viên nhận đơn…';
    }
  }

  IconData _iconFor(Booking booking) {
    switch (booking.status) {
      case BookingStatusName.accepted:
        return Icons.check_circle_outline_rounded;
      case BookingStatusName.onTheWay:
        return Icons.directions_car_filled_rounded;
      case BookingStatusName.inProgress:
        return Icons.cleaning_services_rounded;
      case BookingStatusName.pendingPayment:
        return Icons.payments_rounded;
      case BookingStatusName.rescheduleRequested:
        return Icons.event_repeat_rounded;
      default:
        return booking.isImmediate ? Icons.search_rounded : Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(clientBookingsLiveFeedProvider);
    final bookingsAsync = ref.watch(bookingsProvider);

    final activeBookings = bookingsAsync.maybeWhen(
      data: (bookings) => bookings.where((b) => _statusRank.containsKey(b.status)).toList()
        ..sort((a, b) {
          final rank = _statusRank[a.status]!.compareTo(_statusRank[b.status]!);
          if (rank != 0) return rank;
          return (a.scheduledStartTime ?? DateTime(9999)).compareTo(b.scheduledStartTime ?? DateTime(9999));
        }),
      orElse: () => <Booking>[],
    );

    final booking = activeBookings.isEmpty ? null : activeBookings.first;

    if (booking == null) {
      _ensureElapsedTicker(false);
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final subtitle = _subtitleFor(booking);
    final searching = _isSearchingImmediate(booking);
    _ensureElapsedTicker(searching);

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
                Icon(
                  _iconFor(booking),
                  color: kPrimary,
                ),
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
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: kOnPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                if (searching) ...[
                  Text(
                    formatSearchElapsed(booking),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: kOnPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right_rounded, color: kPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}