import 'package:flutter/material.dart';

import '../../../../../core/constants/booking_enums.dart' show bookingStatusLabel;
import '../../../../../core/constants/payment_methods.dart';
import '../../../../../core/constants/user_role.dart';
import '../../../../../core/utils/app_formatters.dart';
import '../../../../../logic/booking/booking_action_rules.dart';
import '../../../../shared/destructive_dialog_actions.dart';
import '../../../../shared/popup_menu_action_item.dart';
import '../common/booking_buttons.dart';
import '../sheets/client_cancel_reason_sheet.dart';
import '../sheets/propose_reschedule_sheet.dart';
import '../sheets/report_booking_sheet.dart';
import '../sheets/worker_cancel_reason_sheet.dart';

class BookingActionBar extends StatelessWidget {
  final String status;
  final UserRole viewerRole;
  final bool isScheduled;
  final PaymentMethod paymentMethod;
  final DateTime scheduledStartTime;
  final List<Map<String, dynamic>> statusTimeline;
  final VoidCallback onChat;
  final Future<void> Function() onGoingThere;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onHideJob;
  final Future<void> Function() onStart;
  final Future<void> Function() onFinish;
  final Future<void> Function() onConfirmCash;
  final Future<void> Function() onPayNow;
  final Future<void> Function() onSwitchToCash;

  final Future<void> Function() onCancelByClient;

  final Future<void> Function(String reasonCode, String? freeText) onWorkerCancel;

  final Future<void> Function(String reasonCode, String? freeText) onClientCancel;

  final Future<void> Function(String reasonCode, String freeText) onReport;

  final Future<void> Function(DateTime newStartTime, String? message) onProposeReschedule;
  final VoidCallback onRetryAsNewBooking;
  final Future<void> Function() onAdjustDuration;
  final VoidCallback onViewEarning;
  final VoidCallback onViewReason;

  const BookingActionBar({
    super.key,
    required this.status,
    required this.viewerRole,
    required this.isScheduled,
    this.paymentMethod = PaymentMethod.cash,
    required this.scheduledStartTime,
    this.statusTimeline = const [],
    required this.onChat,
    required this.onGoingThere,
    this.onAccept,
    this.onHideJob,
    required this.onStart,
    required this.onFinish,
    required this.onConfirmCash,
    required this.onPayNow,
    required this.onSwitchToCash,
    required this.onCancelByClient,
    required this.onWorkerCancel,
    required this.onClientCancel,
    required this.onReport,
    required this.onProposeReschedule,
    required this.onRetryAsNewBooking,
    required this.onAdjustDuration,
    required this.onViewEarning,
    required this.onViewReason,
  });

  Widget? _buildPrimary(BuildContext context, BookingPrimaryAction? action) => switch (action) {
        null => null,
        BookingPrimaryAction.accept => _primary(context, 'Nhận việc', onAccept!),
        BookingPrimaryAction.goingThere => _primary(context, 'Đang di chuyển', onGoingThere),
        BookingPrimaryAction.start => _primary(context, 'Bắt đầu công việc', onStart),
        BookingPrimaryAction.finish => _primary(context, 'Hoàn thành', onFinish),
        BookingPrimaryAction.confirmCash => _primary(context, 'Xác nhận đã nhận tiền mặt', onConfirmCash),
        BookingPrimaryAction.payNow => _primary(context, 'Thanh toán ngay', onPayNow),
      };

  Widget? _buildSecondary(BuildContext context, BookingSecondaryAction? action) => switch (action) {
        null => null,
        BookingSecondaryAction.cancelByClient =>
          _danger(context, 'Hủy đặt lịch', () => _confirmCancelByClient(context)),
        BookingSecondaryAction.cancelAndRetry => _cancelAndRetryRow(context),
        BookingSecondaryAction.payCashHint => _hint(context, 'Vui lòng thanh toán tiền mặt cho nhân viên.'),
        BookingSecondaryAction.switchToCashLink =>
          _textLink(context, 'Thanh toán bằng tiền mặt', () => _confirmSwitchToCash(context)),
        BookingSecondaryAction.waitingForClientHint => _hint(context, 'Đang chờ khách thanh toán…'),
        BookingSecondaryAction.viewEarning => _outlinedSync(context, 'Xem thu nhập', onViewEarning),
        BookingSecondaryAction.viewReason => _outlinedSync(context, 'Xem lý do', onViewReason),
      };

  _OverflowAction _buildOverflow(BuildContext context, BookingOverflowAction action) => switch (action) {
        BookingOverflowAction.hideJob =>
          _OverflowAction('Ẩn công việc này', onHideJob!, icon: Icons.visibility_off_rounded),
        BookingOverflowAction.workerCancel => _OverflowAction(
            'Hủy công việc này', () => _openWorkerCancelSheet(context), icon: Icons.cancel_outlined),
        BookingOverflowAction.clientCancel => _OverflowAction(
            'Hủy công việc này', () => _openClientCancelSheet(context), icon: Icons.cancel_outlined),
        BookingOverflowAction.adjustDuration =>
          _OverflowAction('Điều chỉnh thời lượng', onAdjustDuration, icon: Icons.schedule_outlined),
        BookingOverflowAction.report =>
          _OverflowAction('Báo cáo', () => _openReportSheet(context), icon: Icons.flag_outlined),
      };

  @override
  Widget build(BuildContext context) {
    final plan = computeBookingActionPlan(
      status: status,
      viewerRole: viewerRole,
      isScheduled: isScheduled,
      paymentMethod: paymentMethod,
      hasAcceptHandler: onAccept != null,
      hasHideJobHandler: onHideJob != null,
    );

    final primary = _buildPrimary(context, plan.primary);
    final secondary = _buildSecondary(context, plan.secondary);
    final overflow = plan.overflow.map((action) => _buildOverflow(context, action)).toList();

    final utilityIcons = <Widget>[
      if (plan.showChat)
        _iconAction(context, icon: Icons.chat_bubble_outline_rounded, tooltip: 'Trò chuyện', onPressed: onChat),
      if (plan.showReschedule)
        _iconAction(
          context,
          icon: Icons.event_repeat_rounded,
          tooltip: 'Yêu cầu đổi lịch',
          onPressed: () => _openProposeRescheduleSheet(context),
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
        PopupMenuItem<int>(
          value: i,
          child: PopupMenuActionItem(icon: actions[i].icon, label: actions[i].label),
        ),
    ],
  );

  Widget _primary(BuildContext context, String label, Future<void> Function() onPressed) =>
    primaryActionButton(label, onPressed);

  Widget _outlinedSync(BuildContext context, String label, VoidCallback onPressed) =>
    outlinedSyncActionButton(label, onPressed);

  Widget _cancelAndRetryRow(BuildContext context) => Row(
    children: [
      Expanded(child: _danger(context, 'Hủy đặt lịch', () => _confirmCancelByClient(context))),
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

  Widget _danger(BuildContext context, String label, VoidCallback onPressed) =>
    dangerActionButton(label, onPressed);

  Widget _textLink(BuildContext context, String label, VoidCallback onPressed) =>
    TextButton(onPressed: onPressed, child: Text(label));

  Future<void> _confirmSwitchToCash(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chuyển sang thanh toán tiền mặt?'),
        content: const Text(
          'Bạn sẽ thanh toán trực tiếp cho nhân viên bằng tiền mặt thay vì VNPay.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (confirmed == true) await onSwitchToCash();
  }

  Future<void> _confirmCancelByClient(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đơn đặt lịch này?'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn đặt lịch này không?'),
        actions: [
          DestructiveDialogActions(
            confirmLabel: 'Xác nhận hủy',
            onConfirm: () => Navigator.pop(dialogContext, true),
            onCancel: () => Navigator.pop(dialogContext, false),
          ),
        ],
      ),
    );
    if (confirmed == true) await onCancelByClient();
  }

  Future<void> _openWorkerCancelSheet(BuildContext context) async {
    final result = await showWorkerCancelReasonSheet(context);
    if (result != null) await onWorkerCancel(result.reasonCode, result.freeText);
  }

  Future<void> _openClientCancelSheet(BuildContext context) async {
    final result = await showClientCancelReasonSheet(context);
    if (result != null) await onClientCancel(result.reasonCode, result.freeText);
  }

  Future<void> _openReportSheet(BuildContext context) async {
    final result = await showReportBookingSheet(context, viewerRole);
    if (result != null) await onReport(result.reasonCode, result.freeText);
  }

  Future<void> _openProposeRescheduleSheet(BuildContext context) async {
    final result = await showProposeRescheduleSheet(
      context,
      initialDate: scheduledStartTime,
      initialTime: TimeOfDay.fromDateTime(scheduledStartTime),
    );
    if (result != null) await onProposeReschedule(result.newStartTime, result.message);
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
                        createdAt == null ? null : dateTimeFormat.format(createdAt);
                    final reason = entry['reason']?.toString() ?? '';
                    final subtitle = [
                      if (timestamp != null) timestamp,
                      if (reason.isNotEmpty) reason,
                    ].join('\n');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline_rounded),
                      title: Text(bookingStatusLabel(entry['newStatus']?.toString() ?? '')),
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
  final IconData icon;
  final Future<void> Function() onSelected;
  const _OverflowAction(this.label, this.onSelected, {this.icon = Icons.more_horiz_rounded});
}
