import 'package:cleanai/ui/client/booking/widgets/steps/booking_date_time_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(DateTime selectedDate, {ValueChanged<TimeOfDay>? onTimeChanged}) => MaterialApp(
        home: Scaffold(
          body: BookingDateTimeStep(
            bookingType: 0,
            selectedDate: selectedDate,
            selectedTime: const TimeOfDay(hour: 9, minute: 0),
            notesController: TextEditingController(),
            onBookingTypeChanged: (_) {},
            onDateChanged: (_) {},
            onTimeChanged: onTimeChanged ?? (_) {},
          ),
        ),
      );

  testWidgets(
    '[UT-FE-BOOK-003-02] A slot on today disables the midnight slot (< 2h lead time)',
    (tester) async {
      await tester.pumpWidget(wrap(DateTime.now()));
      await tester.tap(find.text('Ngày & giờ hẹn'));
      await tester.pumpAndSettle();

      final midnightButton = tester.widget<TextButton>(find.widgetWithText(TextButton, '00:00'));
      expect(midnightButton.onPressed, isNull);
    },
  );

  testWidgets(
    '[UT-FE-BOOK-003-03] A slot 2 days out is enabled and reports the tapped time',
    (tester) async {
      TimeOfDay? picked;
      await tester.pumpWidget(wrap(
        DateTime.now(),
        onTimeChanged: (time) => picked = time,
      ));
      await tester.tap(find.text('Ngày & giờ hẹn'));
      await tester.pumpAndSettle();
      final target = DateTime.now().add(const Duration(days: 2));
      await tester.tap(find.byKey(ValueKey('slot-date-chip-${target.year}-${target.month}-${target.day}')));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.text('10:00'),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      final slotButton = tester.widget<TextButton>(find.widgetWithText(TextButton, '10:00'));
      expect(slotButton.onPressed, isNotNull);

      await tester.tap(find.text('10:00'));
      await tester.pumpAndSettle();
      expect(picked, const TimeOfDay(hour: 10, minute: 0));
    },
  );

  testWidgets(
    '[UT-FE-BOOK-003-04] A day beyond the 30-day window is not offered in the date strip',
    (tester) async {
      await tester.pumpWidget(wrap(DateTime.now()));
      await tester.tap(find.text('Ngày & giờ hẹn'));
      await tester.pumpAndSettle();

      final tooFar = DateTime.now().add(const Duration(days: 31));
      expect(find.byKey(ValueKey('slot-date-chip-${tooFar.year}-${tooFar.month}-${tooFar.day}')),
          findsNothing);
    },
  );
}
