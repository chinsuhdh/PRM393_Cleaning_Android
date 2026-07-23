import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/app_formatters.dart';
import '../../../../../data/models/booking.dart';
import '../common/booking_buttons.dart';

class RescheduleBanner extends StatelessWidget {
  final RescheduleProposal proposal;
  final String? currentUserId;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;
  final Future<void> Function() onWithdraw;

  const RescheduleBanner({
    super.key,
    required this.proposal,
    required this.currentUserId,
    required this.onAccept,
    required this.onReject,
    required this.onWithdraw,
  });

  bool get _isRequester => proposal.requestedBy == currentUserId;

  @override
  Widget build(BuildContext context) {
    if (!proposal.isPending) return const SizedBox.shrink();
    final formatter = dateTimeFormat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kTertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kTertiary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_repeat_rounded, color: kTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đề nghị dời lịch hẹn',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Hiện tại: ${formatter.format(proposal.oldStartTime)}'),
          Text('Đề nghị: ${formatter.format(proposal.newStartTime)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          if (proposal.reason != null && proposal.reason!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Lời nhắn: ${proposal.reason}'),
          ],
          const SizedBox(height: 12),
          if (_isRequester) ...[
            Text('Đang chờ phản hồi từ phía bên kia…',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            dangerActionButton('Hủy đề nghị', () => onWithdraw()),
          ] else
            Row(
              children: [
                Expanded(child: primaryActionButton('Đồng ý', onAccept)),
                const SizedBox(width: 12),
                Expanded(child: dangerActionButton('Từ chối', () => onReject())),
              ],
            ),
        ],
      ),
    );
  }
}
