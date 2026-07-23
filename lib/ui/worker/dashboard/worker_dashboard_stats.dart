import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/network/error_codes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../shared/app_snackbar.dart';

class OnlineStatusToggle extends ConsumerWidget {
  const OnlineStatusToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(workerOnlineStatusNotifierProvider);
    final status = statusAsync.valueOrNull;
    final isOnline = status == WorkerOnlineStatus.online;
    final isBusy = status == WorkerOnlineStatus.busy;

    final isSuspended = ref.watch(workerProfileProvider).valueOrNull?.isSuspended ?? false;
    if (isSuspended) {
      return Container(
        key: const ValueKey('online-status-toggle-suspended'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text(
              'Đã tạm khóa',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      key: const ValueKey('online-status-toggle'),
      onTap: statusAsync.isLoading
          ? null
          : () async {
              try {
                await ref
                    .read(workerOnlineStatusNotifierProvider.notifier)
                    .toggle(isBusy ? false : !isOnline);
              } on AppException catch (e) {
                debugPrint('[OnlineStatusToggle] toggle failed: ${e.code}');
                if (e.code == ErrorCodes.workerSuspended) {
                  ref.invalidate(workerProfileProvider);
                }
                if (context.mounted) showAppErrorSnackBar(context, e);
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              color: isOnline
                  ? kSecondary
                  : (isBusy ? Colors.orangeAccent : Colors.white70),
              size: 10,
            ),
            const SizedBox(width: 6),
            Text(
              statusAsync.isLoading
                  ? 'Đang tải…'
                  : (isOnline
                      ? 'Đang hoạt động'
                      : (isBusy ? 'Đang bận' : 'Ngoại tuyến')),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkerStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const WorkerStatCard({
    super.key,
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

class WorkerQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const WorkerQuickAction({
    super.key,
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
