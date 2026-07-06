import 'package:cleanai/ui/booking/widgets/booking_date_time_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// BOOK-003 (D.6): the 30-min slot grid disables times < 2h from now and > 30 days out.
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
      await tester.tap(find.text('Giờ'));
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
        DateTime.now().add(const Duration(days: 2)),
        onTimeChanged: (time) => picked = time,
      ));
      await tester.tap(find.text('Giờ'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(GridView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final slotButton = tester.widget<TextButton>(find.widgetWithText(TextButton, '10:00'));
      expect(slotButton.onPressed, isNotNull);

      await tester.tap(find.text('10:00'));
      await tester.pumpAndSettle();
      expect(picked, const TimeOfDay(hour: 10, minute: 0));
    },
  );

  testWidgets(
    '[UT-FE-BOOK-003-04] A day beyond the 30-day window disables every slot',
    (tester) async {
      await tester.pumpWidget(wrap(DateTime.now().add(const Duration(days: 40))));
      await tester.tap(find.text('Giờ'));
      await tester.pumpAndSettle();

      final midnightButton = tester.widget<TextButton>(find.widgetWithText(TextButton, '00:00'));
      expect(midnightButton.onPressed, isNull);

      await tester.drag(find.byType(GridView), const Offset(0, -400));
      await tester.pumpAndSettle();
      final laterButton = tester.widget<TextButton>(find.widgetWithText(TextButton, '12:00'));
      expect(laterButton.onPressed, isNull);
    },
  );
}
