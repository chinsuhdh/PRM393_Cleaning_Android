import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/booking_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/dispatch_repository.dart';
import '../../data/services/dispatch_hub_service.dart';
import '../shared/booking_card.dart';

class WorkerJobsScreen extends ConsumerStatefulWidget {
  const WorkerJobsScreen({super.key});

  @override
  ConsumerState<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends ConsumerState<WorkerJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _hiddenBookingIds = {};
  final Set<String> _seenAvailableIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dispatchLiveFeedProvider);

    // Gọi 2 nguồn dữ liệu khác biệt
    final myBookingsAsync = ref.watch(workerBookingsProvider);
    final availableBookingsAsync = ref.watch(availableBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Việc của tôi', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kPrimary,
          tabs: const [
            Tab(text: 'Đang làm'),
            Tab(text: 'Có sẵn'),
            Tab(text: 'Đã xong')
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: ACTIVE
          myBookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Lỗi: $err')),
            data: (bookings) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(workerBookingsProvider),
              child: _buildJobList(
                bookings
                    .where((b) => const [
                          BookingStatusName.accepted,
                          BookingStatusName.onTheWay,
                          BookingStatusName.inProgress,
                          BookingStatusName.pendingPayment,
                        ].contains(b.status))
                    .toList(),
                isAvailableTab: false,
              ),
            ),
          ),

          availableBookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Lỗi: $err')),
            data: (bookings) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(availableBookingsProvider),
              child: _buildAvailableList(
                bookings.where((booking) => !_hiddenBookingIds.contains(booking.id)).toList(),
              ),
            ),
          ),

          myBookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Lỗi: $err')),
            data: (bookings) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(workerBookingsProvider),
              child: _buildJobList(
                bookings.where((b) => b.status == BookingStatusName.completed).toList(),
                isAvailableTab: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList(List<Booking> list, {required bool isAvailableTab}) {
    if (list.isEmpty) {
      return bookingListEmptyState(
        context,
        isAvailableTab ? 'Không có đơn đặt lịch mới nào.' : 'Chưa có đơn hàng nào trong mục này.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => BookingCard(
        booking: list[i],
        role: BookingCardRole.worker,
        isAvailableJob: isAvailableTab,
      ),
    );
  }

  Widget _buildAvailableList(List<Booking> list) {
    if (list.isEmpty) {
      return bookingListEmptyState(context, 'Không có đơn đặt lịch mới nào.');
    }

    final immediate = list.where((b) => b.isImmediate).toList();
    final scheduled = list.where((b) => !b.isImmediate).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (immediate.isNotEmpty) ...[
          _SectionHeader(title: 'Ngay bây giờ', count: immediate.length),
          for (final booking in immediate) ...[
            _availableCard(booking),
            const SizedBox(height: 12),
          ],
        ],
        if (scheduled.isNotEmpty) ...[
          if (immediate.isNotEmpty) const SizedBox(height: 8),
          _SectionHeader(title: 'Đã lên lịch', count: scheduled.length),
          for (final booking in scheduled) ...[
            _availableCard(booking),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Future<void> _hideBooking(Booking booking) async {
    setState(() => _hiddenBookingIds.add(booking.id));
    try {
      await ref.read(dispatchRepositoryProvider).hideBooking(booking.id);
      ref.invalidate(availableBookingsProvider);
    } catch (error) {
      debugPrint('[WorkerJobsScreen] hideBooking failed: $error');
      ref.invalidate(availableBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _availableCard(Booking booking) {
    final isNew = _seenAvailableIds.add(booking.id);

    final card = Dismissible(
      key: ValueKey('available-${booking.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.visibility_off, color: Colors.white),
      ),
      onDismissed: (_) => _hideBooking(booking),
      child: BookingCard(
        booking: booking,
        role: BookingCardRole.worker,
        isAvailableJob: true,
        onHide: () => _hideBooking(booking),
      ),
    );

    if (!isNew) return card;
    return _JobCardEntrance(key: ValueKey('entrance-${booking.id}'), child: card);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: kPrimaryContainer, borderRadius: BorderRadius.circular(10)),
            child: Text(
              '$count',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kOnPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCardEntrance extends StatefulWidget {
  final Widget child;
  const _JobCardEntrance({super.key, required this.child});

  @override
  State<_JobCardEntrance> createState() => _JobCardEntranceState();
}

class _JobCardEntranceState extends State<_JobCardEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero).animate(curved),
          child: widget.child,
        ),
      ),
    );
  }
}

