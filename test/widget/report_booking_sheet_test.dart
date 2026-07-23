import 'package:cleanai/core/constants/user_role.dart';
import 'package:cleanai/ui/client/booking/widgets/sheets/report_booking_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(UserRole role, ValueChanged<ReportBookingResult?> onResult) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showReportBookingSheet(context, role);
                onResult(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

  testWidgets('[UT-FE-RPT-01] A client sees the client reason list, a worker sees the worker list',
      (tester) async {
    await tester.pumpWidget(wrap(UserRole.client, (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Nhân viên không đến'), findsOneWidget);
    expect(find.text('Khách hàng vắng mặt'), findsNothing);
  });

  testWidgets('[UT-FE-RPT-02] Confirm is disabled until both a reason and 20+ chars of free text are given',
      (tester) async {
    await tester.pumpWidget(wrap(UserRole.worker, (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Gửi báo cáo'), findsOneWidget);
    var confirmButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Gửi báo cáo'));
    expect(confirmButton.onPressed, isNull);

    await tester.tap(find.text('Khách hàng vắng mặt'));
    await tester.pumpAndSettle();
    confirmButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Gửi báo cáo'));
    expect(confirmButton.onPressed, isNull, reason: 'still no free text');

    await tester.enterText(find.byType(TextField), 'qua ngan');
    await tester.pumpAndSettle();
    confirmButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Gửi báo cáo'));
    expect(confirmButton.onPressed, isNull, reason: 'under 20 chars');

    await tester.enterText(find.byType(TextField), 'Khach hang khong co mat dung gio hen');
    await tester.pumpAndSettle();
    confirmButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Gửi báo cáo'));
    expect(confirmButton.onPressed, isNotNull);
  });

  testWidgets('[UT-FE-RPT-03] Confirming returns the picked reason code and trimmed free text',
      (tester) async {
    ReportBookingResult? result;
    await tester.pumpWidget(wrap(UserRole.client, (r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chất lượng dịch vụ kém'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Phong khong duoc don dep ky luong  ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();

    expect(result?.reasonCode, 'report.client.worker_poor_quality');
    expect(result?.freeText, 'Phong khong duoc don dep ky luong');
  });
}
