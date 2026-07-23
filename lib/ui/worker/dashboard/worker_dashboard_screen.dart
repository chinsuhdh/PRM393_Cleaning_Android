import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/booking.dart';
import '../../../core/auth/auth_state.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/dispatch_repository.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../../data/services/dispatch_hub_service.dart';
import '../../../logic/booking/booking_categorizer.dart';
import '../../shared/logout_action.dart';
import '../../shared/popup_menu_action_item.dart';
import 'worker_dashboard_stats.dart';

Future<void> _hideJob(BuildContext context, WidgetRef ref, Booking booking) async {
  try {
    await ref.read(dispatchRepositoryProvider).hideBooking(booking.id);
    ref.invalidate(availableBookingsProvider);
  } catch (error) {
    debugPrint('[WorkerDashboardScreen] hideBooking failed: $error');
    ref.invalidate(availableBookingsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: Colors.red),
      );
    }
  }
}

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    ref.watch(dispatchLiveFeedProvider);

    final authState = ref.watch(authNotifierProvider);
    final userName = authState.userName ?? 'Nhân viên';
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : 'W';

    final workerBookingsAsync = ref.watch(workerBookingsProvider);
    final availableJobsAsync = ref.watch(availableBookingsProvider);
    final profileAsync = ref.watch(workerProfileProvider);

    final todaysCompleted = workerBookingsAsync.maybeWhen(
      data: (bookings) => todaysCompletedJobs(bookings, DateTime.now()),
      orElse: () => const <Booking>[],
    );
    final todaysEarnings = sumBookingPrices(todaysCompleted);
    final rating = profileAsync.maybeWhen(
      data: (worker) => worker?.rating ?? 0.0,
      orElse: () => 0.0,
    );
    final availableJobs = availableJobsAsync.maybeWhen(
      data: (jobs) => jobs,
      orElse: () => const <Booking>[],
    );
    final newestJob = newestByCreatedAt(availableJobs);

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
                onPressed: () => confirmAndLogout(context, ref),
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
                        GestureDetector(
                          onTap: () => confirmAndLogout(context, ref),
                          child: CircleAvatar(
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
                        value: vndFormat.format(todaysEarnings),
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
                      label: 'Thu nhập',
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            vndFormat.format(newestJob.price),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: kPrimary,
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Tuỳ chọn',
                            icon: const Icon(Icons.more_vert_rounded, color: kOnPrimaryContainer),
                            onSelected: (value) {
                              if (value == 'hide') _hideJob(context, ref, newestJob);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'hide',
                                child: PopupMenuActionItem(icon: Icons.visibility_off_rounded, label: 'Ẩn công việc này'),
                              ),
                            ],
                          ),
                        ],
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
