import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/booking_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/worker_repository.dart';
import '../../data/services/dispatch_hub_service.dart';
import '../shared/destructive_dialog_actions.dart';
import 'widgets/worker_dashboard_stats.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    ref.watch(dispatchLiveFeedProvider);

    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'Nhân viên';
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : 'W';

    final workerBookingsAsync = ref.watch(workerBookingsProvider);
    final availableJobsAsync = ref.watch(availableBookingsProvider);
    final profileAsync = ref.watch(workerProfileProvider);

    final now = DateTime.now();
    bool completedToday(dynamic b) =>
        b.status == BookingStatusName.completed &&
        b.updatedAt != null &&
        b.updatedAt.year == now.year &&
        b.updatedAt.month == now.month &&
        b.updatedAt.day == now.day;

    final todaysCompleted = workerBookingsAsync.maybeWhen(
      data: (bookings) => bookings.where(completedToday).toList(),
      orElse: () => const [],
    );
    final todaysEarnings = todaysCompleted.fold<double>(
      0,
      (sum, b) => sum + b.price,
    );
    final rating = profileAsync.maybeWhen(
      data: (worker) => worker?.rating ?? 0.0,
      orElse: () => 0.0,
    );
    final availableJobs = availableJobsAsync.maybeWhen(
      data: (jobs) => jobs,
      orElse: () => const <Booking>[],
    );
    final newestJob = availableJobs.isEmpty
        ? null
        : (availableJobs.toList()..sort(
                (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                  a.createdAt ?? DateTime(0),
                ),
              ))
              .first;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Đăng xuất'),
                      content: const Text(
                        'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
                      ),
                      actions: [
                        DestructiveDialogActions(
                          confirmLabel: 'Đăng xuất',
                          onConfirm: () => Navigator.pop(context, true),
                          onCancel: () => Navigator.pop(context, false),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, kPrimaryGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chào buổi sáng,',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const OnlineStatusToggle(),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: WorkerStatCard(
                        icon: Icons.attach_money_rounded,
                        label: 'Thu nhập hôm nay',
                        value: _vnd.format(todaysEarnings),
                        color: kSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WorkerStatCard(
                        icon: Icons.work_rounded,
                        label: 'Việc hôm nay',
                        value: '${todaysCompleted.length}',
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WorkerStatCard(
                        icon: Icons.star_rounded,
                        label: 'Đánh giá',
                        value: rating.toStringAsFixed(1),
                        color: kTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Thao tác nhanh',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    WorkerQuickAction(
                      icon: Icons.work_rounded,
                      label: 'Việc của tôi',
                      onTap: () => context.go('/worker/jobs'),
                    ),
                    const SizedBox(width: 12),
                    WorkerQuickAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Ví tiền',
                      onTap: () => context.push('/worker/wallet'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Việc mới',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (availableJobs.length > 1)
                      TextButton(
                        onPressed: () => context.go('/worker/jobs'),
                        child: const Text('Xem tất cả'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (newestJob == null)
                  Card(
                    elevation: 0,
                    color: kPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Icon(
                        Icons.notifications_active_rounded,
                        color: kPrimary,
                      ),
                      title: Text(
                        'Hiện chưa có công việc nào',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kOnPrimaryContainer,
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 0,
                    color: kPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () => context.push('/booking/${newestJob.id}'),
                      leading: const CircleAvatar(
                        backgroundColor: kPrimary,
                        child: Icon(
                          Icons.cleaning_services_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        newestJob.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kOnPrimaryContainer,
                        ),
                      ),
                      subtitle: Text(
                        newestJob.isImmediate
                            ? 'Ngay bây giờ · ${newestJob.time}'
                            : '${newestJob.date} · ${newestJob.time}',
                        style: const TextStyle(color: kOnPrimaryContainer),
                      ),
                      trailing: Text(
                        _vnd.format(newestJob.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
