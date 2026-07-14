import 'package:flutter/material.dart';

import '../../../core/constants/cancellation_reasons.dart';
import 'reason_radio_list.dart';

typedef ClientCancelReasonResult = ({String reasonCode, String? freeText});

Future<ClientCancelReasonResult?> showClientCancelReasonSheet(BuildContext context) {
  return showModalBottomSheet<ClientCancelReasonResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => const _ClientCancelReasonSheet(),
  );
}

class _ClientCancelReasonSheet extends StatefulWidget {
  const _ClientCancelReasonSheet();

  @override
  State<_ClientCancelReasonSheet> createState() => _ClientCancelReasonSheetState();
}

class _ClientCancelReasonSheetState extends State<_ClientCancelReasonSheet> {
  String? _selectedCode;
  final _freeTextController = TextEditingController();

  bool get _isOther => _selectedCode == kClientCancelReasonOther;
  bool get _canConfirm =>
      _selectedCode != null && (!_isOther || _freeTextController.text.trim().isNotEmpty);

  @override
  void dispose() {
    _freeTextController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.pop(context, (
      reasonCode: _selectedCode!,
      freeText: _freeTextController.text.trim().isEmpty ? null : _freeTextController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hủy đơn đặt lịch này?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Đơn sẽ được tìm nhân viên khác. Vui lòng chọn lý do.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            ReasonRadioList(
              options: kClientCancelReasons.map((option) => (code: option.code, label: option.label)).toList(),
              selected: _selectedCode,
              onChanged: (value) => setState(() => _selectedCode = value),
            ),
            if (_isOther) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _freeTextController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Nhập lý do cụ thể...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canConfirm ? _confirm : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Xác nhận hủy'),
            ),
          ],
        ),
      ),
    );
  }
}
