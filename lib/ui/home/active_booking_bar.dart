import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/booking_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';

class ActiveBookingBar extends ConsumerStatefulWidget {
  const ActiveBookingBar({super.key, this.pollInterval = const Duration(seconds: 6)});

  final Duration pollInterval;

  @override
  ConsumerState<ActiveBookingBar> createState() => _ActiveBookingBarState();
}

class _ActiveBookingBarState extends ConsumerState<ActiveBookingBar> {
  Timer? _timer;
  Booking? _active;

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
      bookings = await ref.read(bookingRepositoryProvider).getClientBookings();
    } catch (_) {
      return;
    }
    if (!mounted) return;

    final awaiting = bookings.where((b) => b.status == BookingStatusName.awaitingWorker).toList()
      ..sort((a, b) => (a.scheduledStartTime ?? DateTime(9999))
          .compareTo(b.scheduledStartTime ?? DateTime(9999)));

    final next = awaiting.isEmpty ? null : awaiting.first;
    if (next?.id != _active?.id) setState(() => _active = next);
  }

  @override
  Widget build(BuildContext context) {
    final booking = _active;
    if (booking == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final subtitle = booking.isImmediate
        ? 'Đang tìm nhân viên phù hợp…'
        : 'Đang chờ nhân viên nhận đơn…';

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
                  booking.isImmediate ? Icons.search_rounded : Icons.hourglass_top_rounded,
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
                const Icon(Icons.chevron_right_rounded, color: kPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
