import 'package:flutter/material.dart';

import '../../../core/constants/booking_enums.dart';
import '../../../core/constants/user_role.dart';

class BookingActionBar extends StatelessWidget {
  final String status;
  final UserRole viewerRole;
  final bool isScheduled;
  final List<Map<String, dynamic>> statusTimeline;
  final VoidCallback onChat;
  final Future<void> Function() onGoingThere;
  final Future<void> Function()? onAccept;
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
    this.statusTimeline = const [],
    required this.onChat,
    required this.onGoingThere,
    this.onAccept,
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
    var showChat = false;
    var showReschedule = false;
    Widget? primary;
    Widget? secondary;
    final overflow = <_OverflowAction>[];

    switch (status) {
      case BookingStatusName.awaitingWorker:
        if (_isClient) secondary = _danger(context, 'Cancel booking', () => onReport(''));
        if (_isWorker && onAccept != null) primary = _primary(context, 'Accept Job', onAccept!);

      case BookingStatusName.accepted:
        showChat = true;
        showReschedule = isScheduled;
        if (_isWorker) {
          primary = _primary(context, 'Going there', onGoingThere);
          overflow.add(_OverflowAction('Cancel this job', onReleaseJob));
        }
        overflow.add(_OverflowAction('Report', () => _promptReason(context, onReport)));

      case BookingStatusName.rescheduleRequested:
        showChat = true;
        primary = _primary(context, 'Accept new time', onApproveReschedule);
        secondary = _danger(context, 'Cancel booking', () => _promptReason(context, onReport));

      case BookingStatusName.onTheWay:
        showChat = true;
        if (_isWorker) primary = _primary(context, 'Start job', onStart);
        overflow.add(_OverflowAction('Report', () => _promptReason(context, onReport)));

      case BookingStatusName.inProgress:
        showChat = true;
        if (_isWorker) primary = _primary(context, 'Finish', onFinish);
        overflow.add(_OverflowAction('Report', () => _promptReason(context, onReport)));

      case BookingStatusName.pendingPayment:
        showChat = true;
        if (_isClient) primary = _primarySync(context, 'Pay now', onPayNow);
        if (_isWorker) primary = _primary(context, 'Confirm cash received', onConfirmCash);
        overflow.add(_OverflowAction('Report', () => _promptReason(context, onReport)));

      case BookingStatusName.completed:
        showChat = true;
        if (_isClient) secondary = _outlinedSync(context, 'Review', onReview);
        if (_isWorker) secondary = _outlinedSync(context, 'View earning', onViewEarning);

      case BookingStatusName.cancelled:
        secondary = _outlinedSync(context, 'View reason', onViewReason);
    }

    final utilityIcons = <Widget>[
      if (showChat) _iconAction(context, icon: Icons.chat_bubble_outline_rounded, tooltip: 'Chat', onPressed: onChat),
      if (showReschedule)
        _iconAction(
          context,
          icon: Icons.event_repeat_rounded,
          tooltip: 'Request reschedule',
          onPressed: () => onRequestReschedule(),
        ),
      if (statusTimeline.isNotEmpty)
        _iconAction(
          context,
          icon: Icons.history_rounded,
          tooltip: 'History',
          onPressed: () => _showHistory(context),
        ),
    ];

    if (utilityIcons.isEmpty && primary == null && secondary == null && overflow.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (utilityIcons.isNotEmpty || overflow.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: utilityIcons),
              if (overflow.isNotEmpty) _overflowMenu(context, overflow),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (primary != null) ...[primary, const SizedBox(height: 12)],
        if (secondary != null) secondary,
      ],
    );
  }

  Widget _iconAction(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) =>
      IconButton.filledTonal(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      );

  Widget _overflowMenu(BuildContext context, List<_OverflowAction> actions) => PopupMenuButton<int>(
        tooltip: 'More actions',
        icon: const Icon(Icons.more_horiz_rounded),
        onSelected: (index) => actions[index].onSelected(),
        itemBuilder: (context) => [
          for (var i = 0; i < actions.length; i++)
            PopupMenuItem<int>(value: i, child: Text(actions[i].label)),
        ],
      );

  Widget _primary(BuildContext context, String label, Future<void> Function() onPressed) =>
      FilledButton(
        onPressed: () => onPressed(),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
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

  void _showHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status history', style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: statusTimeline.length,
                  itemBuilder: (context, index) {
                    final entry = statusTimeline[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline_rounded),
                      title: Text(entry['newStatus']?.toString() ?? ''),
                      subtitle: (entry['reason']?.toString() ?? '').isEmpty
                          ? null
                          : Text(entry['reason'].toString()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverflowAction {
  final String label;
  final Future<void> Function() onSelected;
  const _OverflowAction(this.label, this.onSelected);
}
