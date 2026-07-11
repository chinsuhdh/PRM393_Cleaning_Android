import 'package:cleanai/ui/booking/widgets/worker_cancel_reason_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(ValueChanged<WorkerCancelReasonResult?> onResult) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showWorkerCancelReasonSheet(context);
                onResult(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

  testWidgets('[UT-FE-WCR-01] Confirm is disabled until a reason is picked', (tester) async {
    await tester.pumpWidget(wrap((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final confirmButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Xác nhận hủy'));
    expect(confirmButton.onPressed, isNull);
  });

  testWidgets('[UT-FE-WCR-02] Picking a non-"other" reason enables confirm and returns its code',
      (tester) async {
    WorkerCancelReasonResult? result;
    await tester.pumpWidget(wrap((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trùng lịch trình'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận hủy'));
    await tester.pumpAndSettle();

    expect(result?.reasonCode, 'worker_cancel.schedule_conflict');
    expect(result?.freeText, isNull);
  });

  testWidgets('[UT-FE-WCR-03] Picking "other" reveals a required text field; empty text keeps confirm disabled',
      (tester) async {
    await tester.pumpWidget(wrap((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lý do khác'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    final confirmButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Xác nhận hủy'));
    expect(confirmButton.onPressed, isNull);
  });

  testWidgets('[UT-FE-WCR-04] "Other" with text entered confirms with the free text attached',
      (tester) async {
    WorkerCancelReasonResult? result;
    await tester.pumpWidget(wrap((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lý do khác'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Xe hỏng dọc đường');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận hủy'));
    await tester.pumpAndSettle();

    expect(result?.reasonCode, 'worker_cancel.other');
    expect(result?.freeText, 'Xe hỏng dọc đường');
  });
}
