import 'package:flutter/material.dart';

import '../../../../../core/constants/report_reasons.dart';
import '../../../../../core/constants/user_role.dart';
import '../common/reason_radio_list.dart';

typedef ReportBookingResult = ({String reasonCode, String freeText});

Future<ReportBookingResult?> showReportBookingSheet(BuildContext context, UserRole viewerRole) {
  return showModalBottomSheet<ReportBookingResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ReportBookingSheet(viewerRole: viewerRole),
  );
}

class _ReportBookingSheet extends StatefulWidget {
  final UserRole viewerRole;
  const _ReportBookingSheet({required this.viewerRole});

  @override
  State<_ReportBookingSheet> createState() => _ReportBookingSheetState();
}

class _ReportBookingSheetState extends State<_ReportBookingSheet> {
  String? _selectedCode;
  final _freeTextController = TextEditingController();

  List<ReportReasonOption> get _options =>
      widget.viewerRole == UserRole.worker ? kWorkerReportReasons : kClientReportReasons;

  bool get _canConfirm =>
      _selectedCode != null && _freeTextController.text.trim().length >= kReportMinFreeTextLength;

  @override
  void dispose() {
    _freeTextController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.pop(context, (reasonCode: _selectedCode!, freeText: _freeTextController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final length = _freeTextController.text.trim().length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Báo cáo đơn đặt lịch này',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Vui lòng chọn lý do và mô tả chi tiết để chúng tôi xử lý. Đơn sẽ được hủy sau khi báo cáo.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            ReasonRadioList(
              options: _options.map((option) => (code: option.code, label: option.label)).toList(),
              selected: _selectedCode,
              onChanged: (value) => setState(() => _selectedCode = value),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _freeTextController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết vấn đề gặp phải (tối thiểu $kReportMinFreeTextLength ký tự)...',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$length/$kReportMinFreeTextLength',
                style: TextStyle(
                  fontSize: 12,
                  color: length >= kReportMinFreeTextLength ? Colors.grey.shade600 : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _canConfirm ? _confirm : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Gửi báo cáo'),
            ),
          ],
        ),
      ),
    );
  }
}
