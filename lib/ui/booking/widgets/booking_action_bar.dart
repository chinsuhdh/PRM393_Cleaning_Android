import 'package:flutter/material.dart';

import '../../../core/constants/booking_enums.dart';
import '../../../core/constants/user_role.dart';

/// D.8 action matrix (MASTER_FEATURE_SPEC.md EPIC D): renders the buttons a participant sees for a
/// booking's current status, wired to their role. Reschedule Approve/Reject/Withdraw collapse into a
/// single "Accept new time" / "Cancel booking" pair for either participant, since the backend does not
/// track which side requested the reschedule (§ 4.1 only distinguishes Accepted <-> RescheduleRequested).
class BookingActionBar extends StatelessWidget {
  final String status;
  final UserRole viewerRole;
  final bool isScheduled;
  final VoidCallback onChat;
  final Future<void> Function() onGoingThere;
  final Future<void> Function() onStart;
  final Future<void> Function() onFinish;
  final Future<void> Function() onConfirmCash;
  final Future<void> Function() onReleaseJob;
  final Future<void> Function(String reason) onReport;
  final Future<void> Function() onRequestReschedule;
  final Future<void> Function() onApproveReschedule;
  final VoidCallback onPayNow;
  final VoidCallback onReview;
  final VoidCallback onViewEarning;
  final VoidCallback onViewReason;

  const BookingActionBar({
    super.key,
    required this.status,
    required this.viewerRole,
    required this.isScheduled,
    required this.onChat,
    required this.onGoingThere,
    required this.onStart,
    required this.onFinish,
    required this.onConfirmCash,
    required this.onReleaseJob,
    required this.onReport,
    required this.onRequestReschedule,
    required this.onApproveReschedule,
    required this.onPayNow,
    required this.onReview,
    required this.onViewEarning,
    required this.onViewReason,
  });

  bool get _isClient => viewerRole == UserRole.client;
  bool get _isWorker => viewerRole == UserRole.worker;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    switch (status) {
      case BookingStatusName.awaitingWorker:
        if (_isClient) buttons.add(_danger(context, 'Cancel booking', () => onReport('')));

      case BookingStatusName.accepted:
        buttons.add(_chat(context));
        if (isScheduled) {
          buttons.add(_outlined(context, 'Request reschedule', onRequestReschedule));
        }
        if (_isWorker) {
          buttons.add(_primary(context, 'Going there', onGoingThere));
          buttons.add(_outlined(context, 'Cancel this job', onReleaseJob));
        }
        buttons.add(_danger(context, 'Report', () => _promptReason(context, onReport)));

      case BookingStatusName.rescheduleRequested:
        buttons.add(_chat(context));
        buttons.add(_primary(context, 'Accept new time', onApproveReschedule));
        buttons.add(_danger(context, 'Cancel booking', () => _promptReason(context, onReport)));

      case BookingStatusName.onTheWay:
        buttons.add(_chat(context));
        if (_isWorker) buttons.add(_primary(context, 'Start job', onStart));
        buttons.add(_danger(context, 'Report', () => _promptReason(context, onReport)));

      case BookingStatusName.inProgress:
        buttons.add(_chat(context));
        if (_isWorker) buttons.add(_primary(context, 'Finish', onFinish));
        buttons.add(_danger(context, 'Report', () => _promptReason(context, onReport)));

      case BookingStatusName.pendingPayment:
        buttons.add(_chat(context));
        if (_isClient) buttons.add(_primarySync(context, 'Pay now', onPayNow));
        if (_isWorker) buttons.add(_primary(context, 'Confirm cash received', onConfirmCash));
        buttons.add(_danger(context, 'Report', () => _promptReason(context, onReport)));

      case BookingStatusName.completed:
        buttons.add(_chat(context));
        if (_isClient) buttons.add(_outlinedSync(context, 'Review', onReview));
        if (_isWorker) buttons.add(_outlinedSync(context, 'View earning', onViewEarning));

      case BookingStatusName.cancelled:
        buttons.add(_outlinedSync(context, 'View reason', onViewReason));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final button in buttons) ...[button, const SizedBox(height: 12)],
      ],
    );
  }

  Widget _chat(BuildContext context) => TextButton.icon(
        onPressed: onChat,
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Chat'),
      );

  Widget _primary(BuildContext context, String label, Future<void> Function() onPressed) =>
      FilledButton(
        onPressed: () => onPressed(),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: Text(label),
      );

  Widget _outlined(BuildContext context, String label, Future<void> Function() onPressed) =>
      OutlinedButton(
        onPressed: () => onPressed(),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: Text(label),
      );

  Widget _primarySync(BuildContext context, String label, VoidCallback onPressed) => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: Text(label),
      );

  Widget _outlinedSync(BuildContext context, String label, VoidCallback onPressed) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: Text(label),
      );

  Widget _danger(BuildContext context, String label, VoidCallback onPressed) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
        ),
        child: Text(label),
      );

  Future<void> _promptReason(BuildContext context, Future<void> Function(String reason) onConfirm) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report this booking'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Back')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (reason != null) await onConfirm(reason);
  }
}
