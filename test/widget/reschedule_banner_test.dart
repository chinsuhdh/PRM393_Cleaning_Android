import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/ui/booking/widgets/reschedule_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RescheduleProposal proposal({required String status, String requestedBy = 'client-1'}) => RescheduleProposal(
        id: 'r1',
        requestedBy: requestedBy,
        oldStartTime: DateTime(2026, 7, 10, 9, 0),
        oldEndTime: DateTime(2026, 7, 10, 11, 0),
        newStartTime: DateTime(2026, 7, 12, 9, 0),
        newEndTime: DateTime(2026, 7, 12, 11, 0),
        status: status,
        reason: 'Bận việc đột xuất',
      );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('[UT-FE-RSCBANNER-01] Renders nothing once the request is resolved', (tester) async {
    await tester.pumpWidget(wrap(RescheduleBanner(
      proposal: proposal(status: 'Accepted'),
      currentUserId: 'client-1',
      onAccept: () async {},
      onReject: () async {},
      onWithdraw: () async {},
    )));

    expect(find.text('Đề nghị dời lịch hẹn'), findsNothing);
  });

  testWidgets('[UT-FE-RSCBANNER-02] The requester sees a waiting state and Withdraw, no Accept/Reject',
      (tester) async {
    var withdrawn = false;
    await tester.pumpWidget(wrap(RescheduleBanner(
      proposal: proposal(status: 'Pending', requestedBy: 'client-1'),
      currentUserId: 'client-1',
      onAccept: () async {},
      onReject: () async {},
      onWithdraw: () async => withdrawn = true,
    )));

    expect(find.text('Đề nghị dời lịch hẹn'), findsOneWidget);
    expect(find.textContaining('Đang chờ phản hồi'), findsOneWidget);
    expect(find.text('Đồng ý'), findsNothing);
    expect(find.text('Từ chối'), findsNothing);

    await tester.tap(find.text('Hủy đề nghị'));
    await tester.pumpAndSettle();
    expect(withdrawn, isTrue);
  });

  testWidgets('[UT-FE-RSCBANNER-03] The other participant sees old→new time with Accept/Reject',
      (tester) async {
    var accepted = false;
    var rejected = false;
    await tester.pumpWidget(wrap(RescheduleBanner(
      proposal: proposal(status: 'Pending', requestedBy: 'client-1'),
      currentUserId: 'worker-1',
      onAccept: () async => accepted = true,
      onReject: () async => rejected = true,
      onWithdraw: () async {},
    )));

    expect(find.text('Hủy đề nghị'), findsNothing);
    expect(find.text('Đồng ý'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);

    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
    expect(rejected, isFalse);
  });

  testWidgets('[UT-FE-RSCBANNER-04] Shows the old and new times formatted, plus the reason message',
      (tester) async {
    await tester.pumpWidget(wrap(RescheduleBanner(
      proposal: proposal(status: 'Pending'),
      currentUserId: 'worker-1',
      onAccept: () async {},
      onReject: () async {},
      onWithdraw: () async {},
    )));

    expect(find.textContaining('10/07/2026 09:00'), findsOneWidget);
    expect(find.textContaining('12/07/2026 09:00'), findsOneWidget);
    expect(find.textContaining('Bận việc đột xuất'), findsOneWidget);
  });
}
