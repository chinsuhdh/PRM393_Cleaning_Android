import 'package:flutter/material.dart';

import 'slot_picker.dart';

typedef ProposeRescheduleResult = ({DateTime newStartTime, String? message});

Future<ProposeRescheduleResult?> showProposeRescheduleSheet(
  BuildContext context, {
  required DateTime initialDate,
  TimeOfDay? initialTime,
}) {
  return showModalBottomSheet<ProposeRescheduleResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ProposeRescheduleSheet(initialDate: initialDate, initialTime: initialTime),
  );
}

class _ProposeRescheduleSheet extends StatefulWidget {
  final DateTime initialDate;
  final TimeOfDay? initialTime;

  const _ProposeRescheduleSheet({required this.initialDate, this.initialTime});

  @override
  State<_ProposeRescheduleSheet> createState() => _ProposeRescheduleSheetState();
}

class _ProposeRescheduleSheetState extends State<_ProposeRescheduleSheet> {
  DateTime? _selectedSlot;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_selectedSlot == null) return;
    Navigator.pop(context, (
      newStartTime: _selectedSlot!,
      message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đề nghị dời lịch hẹn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Chọn thời gian mới cho lịch hẹn này. Bên còn lại cần đồng ý trước khi có hiệu lực.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SlotPicker(
              initialDate: widget.initialDate,
              initialTime: widget.initialTime,
              onSlotSelected: (dateTime) => setState(() => _selectedSlot = dateTime),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Lời nhắn (không bắt buộc)...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _selectedSlot != null ? _confirm : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Gửi đề nghị'),
            ),
          ],
        ),
      ),
    );
  }
}
