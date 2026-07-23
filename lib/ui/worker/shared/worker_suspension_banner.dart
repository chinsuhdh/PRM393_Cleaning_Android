import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/worker_repository.dart';

class WorkerSuspensionBanner extends ConsumerWidget {
  const WorkerSuspensionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuspended = ref.watch(workerProfileProvider).valueOrNull?.isSuspended ?? false;
    if (!isSuspended) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('worker-suspension-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.red.shade700,
      child: const Row(
        children: [
          Icon(Icons.block_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tài khoản của bạn đã bị tạm khóa do hủy việc quá nhiều lần. Vui lòng liên hệ hỗ trợ.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
