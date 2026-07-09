import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/booking_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/dispatch_repository.dart';
import '../../data/services/dispatch_hub_service.dart';
import '../booking/widgets/booking_info_cards.dart' show bookingQuestionRows;

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
            data: (bookings) => _buildJobList(
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
            data: (bookings) => _buildJobList(
              bookings.where((b) => b.status == BookingStatusName.completed).toList(),
              isAvailableTab: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList(List<Booking> list, {required bool isAvailableTab}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isAvailableTab ? 'Không có đơn đặt lịch mới nào.' : 'Chưa có đơn hàng nào trong mục này.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _RealJobCard(booking: list[i], isAvailableJob: isAvailableTab),
    );
  }

  Widget _buildAvailableList(List<Booking> list) {
    if (list.isEmpty) {
      return Center(
        child: Text('Không có đơn đặt lịch mới nào.', style: TextStyle(color: Colors.grey.shade600)),
      );
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
      child: _RealJobCard(
        booking: booking,
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

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
      ],
    );
  }
}

class _RealJobCard extends ConsumerWidget {
  final Booking booking;
  final bool isAvailableJob;
  final VoidCallback? onHide;
  const _RealJobCard({required this.booking, required this.isAvailableJob, this.onHide});

  Future<void> _openGoogleMaps(BuildContext context, double? lat, double? lng) async {
    if (lat == null || lng == null) return;

    final Uri geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    final Uri webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở bản đồ. Vui lòng kiểm tra lại điện thoại.')),
          );
        }
      }
    } catch (e) {
      debugPrint('[WorkerJobsScreen] openGoogleMaps failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở bản đồ.')),
        );
      }
    }
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingRepositoryProvider).acceptBooking(booking.id);
      ref.invalidate(availableBookingsProvider);
      ref.invalidate(workerBookingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhận đơn thành công!')));
      }
    } on BookingNoLongerAvailableException {
      debugPrint('[WorkerJobsScreen] acceptBooking failed: booking no longer available');
      ref.invalidate(availableBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rất tiếc, đơn này vừa có người khác nhận mất rồi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('[WorkerJobsScreen] acceptBooking failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/booking/${booking.id}'),
      child: Card(
      elevation: 0,
      color: isAvailableJob ? kPrimaryContainer : theme.colorScheme.surfaceContainerHighest,
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
                        fontWeight: FontWeight.w800,
                        color: isAvailableJob ? kOnPrimaryContainer : theme.colorScheme.onSurface,
                      )
                  ),
                ),
                Text(_vnd.format(booking.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: kPrimary
                    )
                ),
                if (onHide != null)
                  PopupMenuButton<String>(
                    tooltip: 'Tuỳ chọn',
                    icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurfaceVariant),
                    onSelected: (value) {
                      if (value == 'hide') onHide!();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'hide', child: Text('Ẩn công việc này')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(booking.date, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 16),
                Icon(Icons.access_time_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(booking.time, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if (booking.distanceKm != null)
                  _MetaChip(
                    icon: Icons.social_distance_rounded,
                    label: '${booking.distanceKm!.toStringAsFixed(1)} km',
                  ),
                _MetaChip(
                  icon: Icons.timelapse_rounded,
                  label: '${booking.durationHours.toStringAsFixed(1)} giờ',
                ),
                if (booking.photos.isNotEmpty)
                  _MetaChip(icon: Icons.photo_camera_rounded, label: '${booking.photos.length} ảnh'),
              ],
            ),
            if (booking.bookingQuestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: bookingQuestionRows(booking).take(2).map((row) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${row.$1}: ${row.$2}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )).toList(),
              ),
            ],

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.addressText ?? 'Chưa xác định địa chỉ',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (booking.latitude != null && booking.longitude != null)
                    IconButton(
                      icon: const Icon(Icons.map_rounded, color: kPrimary),
                      tooltip: 'Chỉ đường',
                      onPressed: () => _openGoogleMaps(context, booking.latitude, booking.longitude),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (isAvailableJob)
              FilledButton(
                onPressed: () => _accept(context, ref),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                child: const Text('Nhận việc'),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: booking.status == BookingStatusName.completed
                        ? Colors.green.withValues(alpha: 0.1)
                        : kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: booking.status == BookingStatusName.completed ? Colors.green : kPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
          ],
        ),
      ),
      ),
    );
  }
}
