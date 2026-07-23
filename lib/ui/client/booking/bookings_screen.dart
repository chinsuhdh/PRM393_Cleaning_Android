import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../logic/booking/booking_categorizer.dart';
import '../../shared/booking_card.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Đang hoạt động', 'Lịch sử'];

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
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn của tôi',
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

            final isActiveTab = tabStatus == 'Đang hoạt động';
            final filtered = isActiveTab ? activeBookings(bookings) : historyBookings(bookings);

            if (filtered.isEmpty) {
              return bookingListEmptyState(context, 'Chưa có đơn đặt lịch nào');
            }
            return RefreshIndicator(
              onRefresh: () => ref.refresh(bookingsProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) =>
                    BookingCard(booking: filtered[i], role: BookingCardRole.customer),
              ),
            );
          }).toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lỗi: $e'),
            FilledButton(onPressed: () => ref.invalidate(bookingsProvider), child: const Text('Thử lại')),
          ],
        )),
      ),
    );
  }
}
