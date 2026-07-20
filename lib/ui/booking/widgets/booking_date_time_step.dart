import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'slot_picker.dart';

class BookingDateTimeStep extends StatelessWidget {
  final int bookingType;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final TextEditingController notesController;
  final ValueChanged<int> onBookingTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  final bool hasActiveImmediateBooking;

  const BookingDateTimeStep({
    super.key,
    required this.bookingType,
    required this.selectedDate,
    required this.selectedTime,
    required this.notesController,
    required this.onBookingTypeChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
    this.hasActiveImmediateBooking = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bạn cần dọn dẹp khi nào?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Chọn đặt ngay hoặc chọn thời gian phù hợp để đặt lịch.'),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 1,
                label: const Text('Đặt ngay'),
                icon: const Icon(Icons.bolt),
                enabled: !hasActiveImmediateBooking,
              ),
              const ButtonSegment(value: 0, label: Text('Hẹn giờ'), icon: Icon(Icons.event)),
            ],
            selected: {bookingType},
            onSelectionChanged: (selection) => onBookingTypeChanged(selection.first),
          ),
          if (hasActiveImmediateBooking) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bạn đang có một đơn đặt ngay chờ nhân viên. Vui lòng chờ hoặc hủy đơn đó trước.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (bookingType == 1)
            const Card(
              child: ListTile(
                leading: Icon(Icons.schedule, color: kPrimary),
                title: Text('Sớm nhất có thể'),
                subtitle: Text('Hệ thống sẽ tìm nhân viên phù hợp và bắt đầu ngay khi có người nhận.'),
              ),
            ),
          if (bookingType == 0) ...[
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: const Icon(Icons.event_rounded, color: kPrimary),
              title: const Text('Ngày & giờ hẹn'),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(selectedDate)} • ${selectedTime.format(context)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              onTap: () => _openSlotPicker(context),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lịch hẹn cần trước ít nhất 2 giờ và trong vòng 30 ngày tới.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Text('Ghi chú thêm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhà có nuôi thú cưng, cần mang máy hút bụi...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSlotPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SlotPicker(
            initialDate: selectedDate,
            initialTime: selectedTime,
            onSlotSelected: (dateTime) {
              onDateChanged(DateTime(dateTime.year, dateTime.month, dateTime.day));
              onTimeChanged(TimeOfDay(hour: dateTime.hour, minute: dateTime.minute));
              Navigator.pop(sheetContext);
            },
          ),
        ),
      ),
    );
  }
}
