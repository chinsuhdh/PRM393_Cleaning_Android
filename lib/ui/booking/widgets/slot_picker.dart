import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SlotPicker extends StatefulWidget {
  static const int leadHours = 2;
  static const int maxDaysAhead = 30;

  final DateTime initialDate;
  final TimeOfDay? initialTime;
  final ValueChanged<DateTime> onSlotSelected;

  const SlotPicker({
    super.key,
    required this.initialDate,
    this.initialTime,
    required this.onSlotSelected,
  });

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate);
    _selectedTime = widget.initialTime;
  }

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  bool _isSlotEnabled(DateTime candidate) {
    final now = DateTime.now();
    return !candidate.isBefore(now.add(const Duration(hours: SlotPicker.leadHours))) &&
        !candidate.isAfter(now.add(const Duration(days: SlotPicker.maxDaysAhead)));
  }

  void _selectSlot(TimeOfDay time) {
    setState(() => _selectedTime = time);
    widget.onSlotSelected(DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final days = List.generate(SlotPicker.maxDaysAhead + 1, (i) => today.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = _dateOnly(day) == _selectedDate;
              return _DateChip(
                key: ValueKey('slot-date-chip-${day.year}-${day.month}-${day.day}'),
                label: index == 0 ? 'Hôm nay' : _weekdayLabels[day.weekday - 1],
                dayNumber: day.day,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedDate = day),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 2,
          ),
          itemCount: 48,
          itemBuilder: (_, index) {
            final time = TimeOfDay(hour: index ~/ 2, minute: index.isEven ? 0 : 30);
            final candidate = DateTime(
                _selectedDate.year, _selectedDate.month, _selectedDate.day, time.hour, time.minute);
            final enabled = _isSlotEnabled(candidate);
            final isSelected = enabled && _selectedTime == time;
            return TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isSelected ? kPrimary.withValues(alpha: 0.12) : null,
                foregroundColor: isSelected ? kPrimary : null,
              ),
              onPressed: enabled ? () => _selectSlot(time) : null,
              child: Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
            );
          },
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final int dayNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    super.key,
    required this.label,
    required this.dayNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.0,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                )),
            const SizedBox(height: 3),
            Text('$dayNumber',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black87,
                )),
          ],
        ),
      ),
    );
  }
}
