import 'package:cleanai/ui/client/booking/widgets/sheets/propose_reschedule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(ValueChanged<ProposeRescheduleResult?> onResult) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showProposeRescheduleSheet(
                  context,
                  initialDate: DateTime.now().add(const Duration(hours: 5)),
                );
                onResult(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

  testWidgets('[UT-FE-PRS-01] Confirm is disabled until a slot is picked', (tester) async {
    await tester.pumpWidget(wrap((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final confirmButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Gửi đề nghị'));
    expect(confirmButton.onPressed, isNull);
  });

  testWidgets('[UT-FE-PRS-02] Picking a slot and confirming returns the new start time and optional message',
      (tester) async {
    ProposeRescheduleResult? result;
    await tester.pumpWidget(wrap((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

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
    await tester.enterText(find.byType(TextField), 'Xin doi lich giup minh');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gửi đề nghị'));
    await tester.pumpAndSettle();

    final confirmButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Gửi đề nghị'));
    expect(confirmButton.onPressed, isNotNull);
    await tester.tap(find.text('Gửi đề nghị'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.newStartTime.hour, 10);
    expect(result!.message, 'Xin doi lich giup minh');
  });
}
