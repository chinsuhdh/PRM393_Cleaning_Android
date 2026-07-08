import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/booking_enums.dart';
import '../../../core/constants/payment_methods.dart';
import '../../../core/constants/user_role.dart';
import '../../shared/destructive_dialog_actions.dart';

class BookingActionBar extends StatelessWidget {
  final String status;
  final UserRole viewerRole;
  final bool isScheduled;
  final PaymentMethod paymentMethod;
  final List<Map<String, dynamic>> statusTimeline;
  final VoidCallback onChat;
  final Future<void> Function() onGoingThere;
  final Future<void> Function()? onAccept;
  final Future<void> Function() onStart;
  final Future<void> Function() onFinish;
  final Future<void> Function() onConfirmCash;
  final Future<void> Function() onReleaseJob;
  final Future<void> Function(String reason) onReport;
  final VoidCallback onRetryAsNewBooking;
  final Future<void> Function() onRequestReschedule;
  final Future<void> Function() onApproveReschedule;
  final VoidCallback onReview;
  final VoidCallback onViewEarning;
  final VoidCallback onViewReason;

  const BookingActionBar({
    super.key,
    required this.status,
    required this.viewerRole,
    required this.isScheduled,
    this.paymentMethod = PaymentMethod.cash,
    this.statusTimeline = const [],
    required this.onChat,
    required this.onGoingThere,
    this.onAccept,
    required this.onStart,
    required this.onFinish,
    required this.onConfirmCash,
    required this.onReleaseJob,
    required this.onReport,
    required this.onRetryAsNewBooking,
    required this.onRequestReschedule,
    required this.onApproveReschedule,
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
        if (_isClient) {
          secondary = isScheduled
              ? _danger(context, 'Hủy đặt lịch', () => _promptCancelReason(context))
              : _cancelAndRetryRow(context);
        }
        if (_isWorker && onAccept != null) primary = _primary(context, 'Nhận việc', onAccept!);

      case BookingStatusName.accepted:
        showChat = true;
        showReschedule = isScheduled;
        if (_isWorker) {
          primary = _primary(context, 'Đang di chuyển', onGoingThere);
          overflow.add(_OverflowAction('Hủy công việc này', onReleaseJob));
        }
        overflow.add(_OverflowAction('Báo cáo', () => _promptReason(context, onReport)));

      case BookingStatusName.rescheduleRequested:
        showChat = true;
        primary = _primary(context, 'Chấp nhận giờ mới', onApproveReschedule);
        secondary = _danger(context, 'Hủy đặt lịch', () => _promptCancelReason(context));

      case BookingStatusName.onTheWay:
        showChat = true;
        if (_isWorker) primary = _primary(context, 'Bắt đầu công việc', onStart);
        overflow.add(_OverflowAction('Báo cáo', () => _promptReason(context, onReport)));

      case BookingStatusName.inProgress:
        showChat = true;
        if (_isWorker) primary = _primary(context, 'Hoàn thành', onFinish);
        overflow.add(_OverflowAction('Báo cáo', () => _promptReason(context, onReport)));

      case BookingStatusName.pendingPayment:
        showChat = true;
        final isCash = paymentMethod == PaymentMethod.cash;
        if (_isWorker && isCash) {
          primary = _primary(context, 'Xác nhận đã nhận tiền mặt', onConfirmCash);
        } else {
          secondary = _hint(
            context,
            isCash ? 'Vui lòng thanh toán tiền mặt cho nhân viên.' : 'Đang xử lý thanh toán VNPay…',
          );
        }
        overflow.add(_OverflowAction('Báo cáo', () => _promptReason(context, onReport)));

      case BookingStatusName.completed:
        showChat = true;
        if (_isWorker) secondary = _outlinedSync(context, 'Xem thu nhập', onViewEarning);

      case BookingStatusName.cancelled:
        secondary = _outlinedSync(context, 'Xem lý do', onViewReason);
    }

    final utilityIcons = <Widget>[
      if (showChat)
        _iconAction(context, icon: Icons.chat_bubble_outline_rounded, tooltip: 'Trò chuyện', onPressed: onChat),
      if (showReschedule)
        _iconAction(
          context,
          icon: Icons.event_repeat_rounded,
          tooltip: 'Yêu cầu đổi lịch',
          onPressed: () => onRequestReschedule(),
        ),
      if (statusTimeline.isNotEmpty)
        _iconAction(
          context,
          icon: Icons.history_rounded,
          tooltip: 'Lịch sử',
          onPressed: () => _showHistory(context),
        ),
    ];

    if (utilityIcons.isEmpty && primary == null && secondary == null && overflow.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
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
        tooltip: 'Thêm thao tác',
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

  Widget _outlinedSync(BuildContext context, String label, VoidCallback onPressed) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: Text(label),
      );

  Widget _cancelAndRetryRow(BuildContext context) => Row(
        children: [
          Expanded(child: _danger(context, 'Hủy đặt lịch', () => _promptCancelReason(context))),
          const SizedBox(width: 12),
          Expanded(child: _outlinedSync(context, 'Thử lại', onRetryAsNewBooking)),
        ],
      );

  Widget _hint(BuildContext context, String message) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
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

  Future<void> _promptCancelReason(BuildContext context) =>
      _promptReason(context, onReport, title: 'Hủy đơn đặt lịch này?');

  Future<void> _promptReason(
    BuildContext context,
    Future<void> Function(String reason) onConfirm, {
    String title = 'Báo cáo đơn đặt lịch này',
  }) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Lý do (không bắt buộc)'),
          maxLines: 3,
        ),
        actions: [
          DestructiveDialogActions(
            confirmLabel: 'Xác nhận',
            onConfirm: () => Navigator.pop(dialogContext, controller.text),
            onCancel: () => Navigator.pop(dialogContext),
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
              Text('Lịch sử trạng thái', style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: statusTimeline.length,
                  itemBuilder: (context, index) {
                    final entry = statusTimeline[index];
                    final createdAt =
                        DateTime.tryParse(entry['createdAt']?.toString() ?? '')?.toLocal();
                    final timestamp =
                        createdAt == null ? null : DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
                    final reason = entry['reason']?.toString() ?? '';
                    final subtitle = [
                      if (timestamp != null) timestamp,
                      if (reason.isNotEmpty) reason,
                    ].join('\n');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline_rounded),
                      title: Text(entry['newStatus']?.toString() ?? ''),
                      subtitle: subtitle.isEmpty ? null : Text(subtitle),
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
