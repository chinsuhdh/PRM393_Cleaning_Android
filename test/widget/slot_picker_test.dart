import 'package:cleanai/ui/booking/widgets/slot_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({ValueChanged<DateTime>? onSlotSelected}) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SlotPicker(
              initialDate: DateTime.now(),
              onSlotSelected: onSlotSelected ?? (_) {},
            ),
          ),
        ),
      );

  testWidgets('[UT-FE-SLOT-01] Renders the date strip and the 30-min slot grid', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('[UT-FE-SLOT-02] A slot under the 2h lead on today is disabled', (tester) async {
    await tester.pumpWidget(wrap());

    final midnightButton = tester.widget<TextButton>(find.widgetWithText(TextButton, '00:00'));
    expect(midnightButton.onPressed, isNull);
  });

  testWidgets('[UT-FE-SLOT-03] Switching to a later date re-renders the enabled slot set', (tester) async {
    await tester.pumpWidget(wrap());
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(
        find.byKey(ValueKey('slot-date-chip-${tomorrow.year}-${tomorrow.month}-${tomorrow.day}')));
    await tester.pumpAndSettle();

    // Midnight on a future day is no longer within 2h of "now", so it becomes enabled.
    final midnightButton = tester.widget<TextButton>(find.widgetWithText(TextButton, '00:00'));
    expect(midnightButton.onPressed, isNotNull);
  });

  testWidgets('[UT-FE-SLOT-04] Tapping a valid slot reports the combined date and time', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(wrap(onSlotSelected: (dt) => picked = dt));
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await tester.tap(
        find.byKey(ValueKey('slot-date-chip-${tomorrow.year}-${tomorrow.month}-${tomorrow.day}')));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('10:00'),
      find.byType(SingleChildScrollView),
      const Offset(0, -50),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.year, tomorrow.year);
    expect(picked!.month, tomorrow.month);
    expect(picked!.day, tomorrow.day);
    expect(picked!.hour, 10);
    expect(picked!.minute, 0);
  });
}
