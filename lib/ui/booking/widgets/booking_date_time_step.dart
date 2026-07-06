import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// Step where the client chooses Immediate ("as soon as possible") or a specific Scheduled day/time.
/// No worker-availability slots are shown — the booking is created first and matched to a worker
/// afterwards, so this step only collects a requested time.
class BookingDateTimeStep extends StatelessWidget {
  final int bookingType; // 1 = Immediate, 0 = Scheduled
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final TextEditingController notesController;
  final ValueChanged<int> onBookingTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const BookingDateTimeStep({
    super.key,
    required this.bookingType,
    required this.selectedDate,
    required this.selectedTime,
    required this.notesController,
    required this.onBookingTypeChanged,
    required this.onDateChanged,
    required this.onTimeChanged,
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
            segments: const [
              ButtonSegment(value: 1, label: Text('Đặt ngay'), icon: Icon(Icons.bolt)),
              ButtonSegment(value: 0, label: Text('Hẹn giờ'), icon: Icon(Icons.event)),
            ],
            selected: {bookingType},
            onSelectionChanged: (selection) => onBookingTypeChanged(selection.first),
          ),
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
              leading: const Icon(Icons.calendar_today_rounded, color: kPrimary),
              title: const Text('Ngày'),
              subtitle: Text(
                DateFormat('dd/MM/yyyy').format(selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) onDateChanged(picked);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: const Icon(Icons.access_time_rounded, color: kPrimary),
              title: const Text('Giờ'),
              subtitle: Text(
                selectedTime.format(context),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              onTap: () async {
                final picked = await showModalBottomSheet<TimeOfDay>(
                  context: context,
                  builder: (sheetContext) => GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 2,
                    ),
                    itemCount: 48,
                    itemBuilder: (_, index) {
                      final time = TimeOfDay(hour: index ~/ 2, minute: index.isEven ? 0 : 30);
                      final candidate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, time.hour, time.minute);
                      final enabled = !candidate.isBefore(DateTime.now().add(const Duration(hours: 2))) &&
                          !candidate.isAfter(DateTime.now().add(const Duration(days: 30)));
                      return TextButton(
                        onPressed: enabled ? () => Navigator.pop(sheetContext, time) : null,
                        child: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
                      );
                    },
                  ),
                );
                if (picked != null) onTimeChanged(picked);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lịch hẹn cần trước ít nhất 2 giờ và trong giờ hoạt động của dịch vụ.',
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
}
