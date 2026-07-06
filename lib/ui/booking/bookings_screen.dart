import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/booking_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Active', 'History'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings',
            style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          indicatorColor: kPrimary,
          labelColor: kPrimary,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: bookingsAsync.when(
        data: (bookings) => TabBarView(
          controller: _tabController,
          children: _tabs.map((tabStatus) {

            // Mọi trạng thái đang hoạt động (tìm thợ -> chờ thanh toán) gom vào tab 'Upcoming'.
            final filtered = bookings.where((b) {
              if (tabStatus == 'Active') {
                return const [
                  BookingStatusName.awaitingWorker,
                  BookingStatusName.accepted,
                  BookingStatusName.onTheWay,
                  BookingStatusName.inProgress,
                  BookingStatusName.pendingPayment,
                  BookingStatusName.rescheduleRequested,
                ].contains(b.status);
              }
              return const [BookingStatusName.completed, BookingStatusName.cancelled].contains(b.status);
            }).toList()
              ..sort((a, b) => tabStatus == 'Active'
                  ? (a.scheduledStartTime ?? DateTime(9999)).compareTo(b.scheduledStartTime ?? DateTime(9999))
                  : (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'No bookings yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => ref.refresh(bookingsProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) => BookingCard(booking: filtered[i]),
              ),
            );
          }).toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $e'),
            FilledButton(onPressed: () => ref.invalidate(bookingsProvider), child: const Text('Retry')),
          ],
        )),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final Booking booking;
  const BookingCard({super.key, required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case BookingStatusName.awaitingWorker:
      case BookingStatusName.accepted:
      case BookingStatusName.onTheWay:
      case BookingStatusName.inProgress:
      case BookingStatusName.pendingPayment:
      case BookingStatusName.rescheduleRequested:
        return kPrimary;
      case BookingStatusName.completed:
        return kSecondary;
      case BookingStatusName.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case BookingStatusName.awaitingWorker:
      case BookingStatusName.accepted:
      case BookingStatusName.onTheWay:
      case BookingStatusName.inProgress:
      case BookingStatusName.pendingPayment:
      case BookingStatusName.rescheduleRequested:
        return kPrimaryContainer;
      case BookingStatusName.completed:
        return kSecondaryContainer;
      case BookingStatusName.cancelled:
        return const Color(0xFFFFDAD6);
      default:
        return Colors.grey.shade200;
    }
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBgColor(booking.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: _statusColor(booking.status),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: kPrimary),
                const SizedBox(width: 6),
                Text(booking.date, style: theme.textTheme.bodyMedium),
                const SizedBox(width: 16),
                const Icon(Icons.access_time_rounded,
                    size: 16, color: kPrimary),
                const SizedBox(width: 6),
                Text(booking.time, style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(booking.price),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kPrimary),
            ),
            if (booking.worker != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: kTertiaryContainer,
                        child: Text(
                          booking.worker!.initials,
                          style: const TextStyle(
                            color: kOnTertiaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned Worker',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            booking.worker!.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '\$${booking.price.toStringAsFixed(0)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
