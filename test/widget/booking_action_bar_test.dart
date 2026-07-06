import 'package:cleanai/core/constants/booking_enums.dart';
import 'package:cleanai/core/constants/user_role.dart';
import 'package:cleanai/ui/booking/widgets/booking_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// D.8 action matrix (MASTER_FEATURE_SPEC.md EPIC D). Reschedule Approve/Reject/Withdraw collapse into
// a single "Accept new time" / "Cancel booking" pair for either participant, since the backend does not
// track which side requested the reschedule.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  BookingActionBar bar({
    required String status,
    required UserRole viewerRole,
    bool isScheduled = true,
    VoidCallback? onChat,
    Future<void> Function()? onGoingThere,
    Future<void> Function()? onStart,
    Future<void> Function()? onFinish,
    Future<void> Function()? onConfirmCash,
    Future<void> Function()? onReleaseJob,
    Future<void> Function(String reason)? onReport,
    Future<void> Function()? onRequestReschedule,
    Future<void> Function()? onApproveReschedule,
    VoidCallback? onPayNow,
    VoidCallback? onReview,
    VoidCallback? onViewEarning,
    VoidCallback? onViewReason,
  }) =>
      BookingActionBar(
        status: status,
        viewerRole: viewerRole,
        isScheduled: isScheduled,
        onChat: onChat ?? () {},
        onGoingThere: onGoingThere ?? () async {},
        onStart: onStart ?? () async {},
        onFinish: onFinish ?? () async {},
        onConfirmCash: onConfirmCash ?? () async {},
        onReleaseJob: onReleaseJob ?? () async {},
        onReport: onReport ?? (_) async {},
        onRequestReschedule: onRequestReschedule ?? () async {},
        onApproveReschedule: onApproveReschedule ?? () async {},
        onPayNow: onPayNow ?? () {},
        onReview: onReview ?? () {},
        onViewEarning: onViewEarning ?? () {},
        onViewReason: onViewReason ?? () {},
      );

  testWidgets(
    '[UT-FE-BOOKACT-01] AwaitingWorker (client) shows only Cancel booking',
    (tester) async {
      var cancelled = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.awaitingWorker,
        viewerRole: UserRole.client,
        onReport: (_) async => cancelled = true,
      )));

      expect(find.text('Cancel booking'), findsOneWidget);
      expect(find.text('Chat'), findsNothing);
      expect(find.text('Going there'), findsNothing);

      await tester.tap(find.text('Cancel booking'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-02] Accepted (worker, scheduled) shows Chat, Going there, Release job, Report, Reschedule',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.accepted,
        viewerRole: UserRole.worker,
      )));

      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Going there'), findsOneWidget);
      expect(find.text('Cancel this job'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Request reschedule'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-03] Accepted (client) shows Chat, Reschedule, Report but no worker-only actions',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.accepted,
        viewerRole: UserRole.client,
      )));

      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Request reschedule'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Going there'), findsNothing);
      expect(find.text('Cancel this job'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-04] Accepted (worker, immediate) hides the reschedule button',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.accepted,
        viewerRole: UserRole.worker,
        isScheduled: false,
      )));

      expect(find.text('Request reschedule'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-05] OnTheWay: worker sees Start job, client does not',
    (tester) async {
      var started = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.onTheWay,
        viewerRole: UserRole.worker,
        onStart: () async => started = true,
      )));

      expect(find.text('Start job'), findsOneWidget);
      await tester.tap(find.text('Start job'));
      await tester.pumpAndSettle();
      expect(started, isTrue);

      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.onTheWay,
        viewerRole: UserRole.client,
      )));
      expect(find.text('Start job'), findsNothing);
      expect(find.text('Chat'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-06] InProgress: worker sees Finish, client does not',
    (tester) async {
      var finished = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.inProgress,
        viewerRole: UserRole.worker,
        onFinish: () async => finished = true,
      )));

      expect(find.text('Finish'), findsOneWidget);
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(finished, isTrue);

      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.inProgress,
        viewerRole: UserRole.client,
      )));
      expect(find.text('Finish'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-07] PendingPayment: client sees Pay now, worker sees Confirm cash received',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.pendingPayment,
        viewerRole: UserRole.client,
      )));
      expect(find.text('Pay now'), findsOneWidget);
      expect(find.text('Confirm cash received'), findsNothing);

      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.pendingPayment,
        viewerRole: UserRole.worker,
      )));
      expect(find.text('Confirm cash received'), findsOneWidget);
      expect(find.text('Pay now'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-08] Completed: client sees Review, worker sees View earning',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.completed,
        viewerRole: UserRole.client,
      )));
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('View earning'), findsNothing);

      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.completed,
        viewerRole: UserRole.worker,
      )));
      expect(find.text('View earning'), findsOneWidget);
      expect(find.text('Review'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-09] Cancelled shows only View reason, no Chat',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.cancelled,
        viewerRole: UserRole.client,
      )));

      expect(find.text('View reason'), findsOneWidget);
      expect(find.text('Chat'), findsNothing);
      expect(find.text('Report'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-10] RescheduleRequested shows Accept new time and Cancel booking for either role',
    (tester) async {
      var approved = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.rescheduleRequested,
        viewerRole: UserRole.client,
        onApproveReschedule: () async => approved = true,
      )));

      expect(find.text('Accept new time'), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);

      await tester.tap(find.text('Accept new time'));
      await tester.pumpAndSettle();
      expect(approved, isTrue);
    },
  );
}
