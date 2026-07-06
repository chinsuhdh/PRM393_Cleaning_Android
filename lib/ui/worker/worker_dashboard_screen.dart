import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/worker_repository.dart';
import '../../data/services/dispatch_hub_service.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Keeps the dispatch hub connected while the dashboard is visible, so the newest-job preview
    // below updates live instead of only refreshing when the worker navigates away and back.
    ref.watch(dispatchLiveFeedProvider);

    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'Worker';
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : 'W';

    final workerBookingsAsync = ref.watch(workerBookingsProvider);
    final availableJobsAsync = ref.watch(availableBookingsProvider);
    final profileAsync = ref.watch(workerProfileProvider);

    final now = DateTime.now();
    bool completedToday(dynamic b) =>
        b.status == 'Completed' &&
        b.updatedAt != null &&
        b.updatedAt.year == now.year &&
        b.updatedAt.month == now.month &&
        b.updatedAt.day == now.day;

    final todaysCompleted = workerBookingsAsync.maybeWhen(
      data: (bookings) => bookings.where(completedToday).toList(),
      orElse: () => const [],
    );
    final todaysEarnings = todaysCompleted.fold<double>(0, (sum, b) => sum + b.price);
    final rating = profileAsync.maybeWhen(data: (worker) => worker?.rating ?? 0.0, orElse: () => 0.0);
    final availableJobs = availableJobsAsync.maybeWhen(data: (jobs) => jobs, orElse: () => const <Booking>[]);
    final newestJob = availableJobs.isEmpty
        ? null
        : (availableJobs.toList()
              ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))))
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
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Đăng xuất'),
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
                    colors: [kPrimary, Color(0xFF1D4ED8)],
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
                              'Good Morning,',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle, color: kSecondary, size: 10),
                          SizedBox(width: 6),
                          Text(
                            'Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      child: _StatCard(
                        icon: Icons.attach_money_rounded,
                        label: "Today's Earn",
                        value: _vnd.format(todaysEarnings),
                        color: kSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.work_rounded,
                        label: 'Jobs Today',
                        value: '${todaysCompleted.length}',
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.star_rounded,
                        label: 'Rating',
                        value: rating.toStringAsFixed(1),
                        color: kTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.work_rounded,
                      label: 'My Jobs',
                      onTap: () => context.go('/worker/jobs'),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Wallet',
                      onTap: () => context.push('/worker/wallet'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Shows the newest posted job's real details directly — not just a count with a
                // button to another screen — so the worker can see what it actually is at a glance.
                // The full live/hideable list still lives in the Jobs tab; this is just a preview.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Job',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (availableJobs.length > 1)
                      TextButton(
                        onPressed: () => context.go('/worker/jobs'),
                        child: const Text('View all'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (newestJob == null)
                  Card(
                    elevation: 0,
                    color: kPrimaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Icon(Icons.notifications_active_rounded, color: kPrimary),
                      title: Text(
                        'No jobs available right now',
                        style: TextStyle(fontWeight: FontWeight.w700, color: kOnPrimaryContainer),
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 0,
                    color: kPrimaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () => context.push('/worker/jobs/booking/${newestJob.id}'),
                      leading: const CircleAvatar(
                        backgroundColor: kPrimary,
                        child: Icon(Icons.cleaning_services_rounded, color: Colors.white),
                      ),
                      title: Text(
                        newestJob.serviceName,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: kOnPrimaryContainer),
                      ),
                      subtitle: Text(
                        newestJob.isImmediate ? 'Now · ${newestJob.time}' : '${newestJob.date} · ${newestJob.time}',
                        style: const TextStyle(color: kOnPrimaryContainer),
                      ),
                      trailing: Text(
                        _vnd.format(newestJob.price),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: kPrimary),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: kPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
