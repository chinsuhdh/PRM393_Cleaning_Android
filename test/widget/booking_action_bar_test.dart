import 'package:cleanai/core/constants/booking_enums.dart';
import 'package:cleanai/core/constants/payment_methods.dart';
import 'package:cleanai/core/constants/user_role.dart';
import 'package:cleanai/ui/booking/widgets/booking_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  BookingActionBar bar({
    required String status,
    required UserRole viewerRole,
    bool isScheduled = true,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    DateTime? scheduledStartTime,
    List<Map<String, dynamic>> statusTimeline = const [],
    VoidCallback? onChat,
    Future<void> Function()? onGoingThere,
    Future<void> Function()? onAccept,
    Future<void> Function()? onHideJob,
    Future<void> Function()? onStart,
    Future<void> Function()? onFinish,
    Future<void> Function()? onConfirmCash,
    Future<void> Function()? onCancelByClient,
    Future<void> Function(String reasonCode, String? freeText)? onWorkerCancel,
    Future<void> Function(String reasonCode, String freeText)? onReport,
    Future<void> Function(DateTime newStartTime, String? message)? onProposeReschedule,
    VoidCallback? onRetryAsNewBooking,
    VoidCallback? onReview,
    VoidCallback? onViewEarning,
    VoidCallback? onViewReason,
  }) =>
      BookingActionBar(
        status: status,
        viewerRole: viewerRole,
        isScheduled: isScheduled,
        paymentMethod: paymentMethod,
        scheduledStartTime: scheduledStartTime ?? DateTime.now().add(const Duration(hours: 3)),
        statusTimeline: statusTimeline,
        onChat: onChat ?? () {},
        onGoingThere: onGoingThere ?? () async {},
        onAccept: onAccept,
        onHideJob: onHideJob,
        onStart: onStart ?? () async {},
        onFinish: onFinish ?? () async {},
        onConfirmCash: onConfirmCash ?? () async {},
        onCancelByClient: onCancelByClient ?? () async {},
        onWorkerCancel: onWorkerCancel ?? (_, __) async {},
        onReport: onReport ?? (_, __) async {},
        onProposeReschedule: onProposeReschedule ?? (_, __) async {},
        onRetryAsNewBooking: onRetryAsNewBooking ?? () {},
        onReview: onReview ?? () {},
        onViewEarning: onViewEarning ?? () {},
        onViewReason: onViewReason ?? () {},
      );

  /// Opens the overflow menu and taps the named entry.
  Future<void> tapOverflow(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip('Thêm thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    '[UT-FE-BOOKACT-01] AwaitingWorker (client) shows only Cancel booking, no chat or overflow; '
    'cancelling is a plain confirm — no reason field, per H.1 pre-accept cancel',
    (tester) async {
      var cancelled = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.awaitingWorker,
        viewerRole: UserRole.client,
        onCancelByClient: () async => cancelled = true,
      )));

      expect(find.text('Hủy đặt lịch'), findsOneWidget);
      expect(find.byTooltip('Trò chuyện'), findsNothing);
      expect(find.byTooltip('Thêm thao tác'), findsNothing);

      await tester.tap(find.text('Hủy đặt lịch'));
      await tester.pumpAndSettle();

      expect(cancelled, isFalse);
      expect(find.text('Hủy đơn đặt lịch này?'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Xác nhận hủy'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-18] Backing out of the cancel confirm dialog does not cancel',
    (tester) async {
      var cancelled = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.awaitingWorker,
        viewerRole: UserRole.client,
        onCancelByClient: () async => cancelled = true,
      )));

      await tester.tap(find.text('Hủy đặt lịch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(cancelled, isFalse);
      expect(find.text('Hủy đơn đặt lịch này?'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-15] AwaitingWorker (client, Immediate/not scheduled) shows Cancel booking and '
    'Retry side by side — Retry starts a whole new request instead of re-broadcasting this one',
    (tester) async {
      var retried = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.awaitingWorker,
        viewerRole: UserRole.client,
        isScheduled: false,
        onRetryAsNewBooking: () => retried = true,
      )));

      expect(find.text('Hủy đặt lịch'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-02] Accepted (worker, scheduled): Going there is the sole primary action; '
    'Chat/Reschedule are icons; Cancel this job opens the reason sheet from the overflow menu',
    (tester) async {
      String? cancelledReasonCode;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.accepted,
        viewerRole: UserRole.worker,
        onWorkerCancel: (reasonCode, freeText) async => cancelledReasonCode = reasonCode,
      )));

      expect(find.widgetWithText(FilledButton, 'Đang di chuyển'), findsOneWidget);
      expect(find.byTooltip('Trò chuyện'), findsOneWidget);
      expect(find.byTooltip('Yêu cầu đổi lịch'), findsOneWidget);
      expect(find.text('Hủy công việc này'), findsNothing);
      expect(find.text('Báo cáo'), findsNothing);

      await tapOverflow(tester, 'Hủy công việc này');
      expect(find.text('Hủy nhận việc này?'), findsOneWidget);

      await tester.tap(find.text('Địa chỉ quá xa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận hủy'));
      await tester.pumpAndSettle();

      expect(cancelledReasonCode, 'worker_cancel.too_far');
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-03] Accepted (client): no primary action; Chat/Reschedule icons; Report in overflow',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.accepted,
        viewerRole: UserRole.client,
      )));

      expect(find.byTooltip('Trò chuyện'), findsOneWidget);
      expect(find.byTooltip('Yêu cầu đổi lịch'), findsOneWidget);
      expect(find.text('Đang di chuyển'), findsNothing);
      expect(find.text('Hủy công việc này'), findsNothing);

      await tester.tap(find.byTooltip('Thêm thao tác'));
      await tester.pumpAndSettle();
      expect(find.text('Báo cáo'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-04] Accepted (worker, immediate) hides the reschedule icon',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.accepted,
        viewerRole: UserRole.worker,
        isScheduled: false,
      )));

      expect(find.byTooltip('Yêu cầu đổi lịch'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-05] OnTheWay: worker sees a primary Start job action, client does not',
    (tester) async {
      var started = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.onTheWay,
        viewerRole: UserRole.worker,
        onStart: () async => started = true,
      )));

      final startButton = find.widgetWithText(FilledButton, 'Bắt đầu công việc');
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.pumpAndSettle();
      expect(started, isTrue);

      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.onTheWay,
        viewerRole: UserRole.client,
      )));
      expect(find.text('Bắt đầu công việc'), findsNothing);
      expect(find.byTooltip('Trò chuyện'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-06] InProgress: worker sees a primary Finish action, client does not',
    (tester) async {
      var finished = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.inProgress,
        viewerRole: UserRole.worker,
        onFinish: () async => finished = true,
      )));

      final finishButton = find.widgetWithText(FilledButton, 'Hoàn thành');
      expect(finishButton, findsOneWidget);
      await tester.tap(finishButton);
      await tester.pumpAndSettle();
      expect(finished, isTrue);

      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.inProgress,
        viewerRole: UserRole.client,
      )));
      expect(find.text('Hoàn thành'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-07] PendingPayment (Cash): the client has no Pay now anymore (auto-payment) — '
    'just a pay-the-worker hint; the worker keeps the primary Confirm cash received',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.pendingPayment,
        viewerRole: UserRole.client,
      )));
      expect(find.text('Pay now'), findsNothing);
      expect(find.text('Xác nhận đã nhận tiền mặt'), findsNothing);
      expect(find.text('Vui lòng thanh toán tiền mặt cho nhân viên.'), findsOneWidget);

      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.pendingPayment,
        viewerRole: UserRole.worker,
      )));
      expect(find.widgetWithText(FilledButton, 'Xác nhận đã nhận tiền mặt'), findsOneWidget);
      expect(find.text('Pay now'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-16] PendingPayment (VNPay): nobody gets a button — both roles see the transient '
    'auto-charge hint while the backend completes the booking on its own',
    (tester) async {
      for (final role in [UserRole.client, UserRole.worker]) {
        await tester.pumpWidget(wrap(bar(
          status: BookingStatusName.pendingPayment,
          viewerRole: role,
          paymentMethod: PaymentMethod.vnpay,
        )));
        expect(find.text('Pay now'), findsNothing, reason: '$role');
        expect(find.text('Xác nhận đã nhận tiền mặt'), findsNothing, reason: '$role');
        expect(find.text('Đang xử lý thanh toán VNPay…'), findsOneWidget, reason: '$role');
      }
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-08] Completed: client sees no secondary action (review is now inline on the page), '
    'worker sees View earning, no overflow menu',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.completed,
        viewerRole: UserRole.client,
      )));
      expect(find.text('Review'), findsNothing);
      expect(find.text('Xem thu nhập'), findsNothing);
      expect(find.byTooltip('Thêm thao tác'), findsNothing);

      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.completed,
        viewerRole: UserRole.worker,
      )));
      expect(find.text('Xem thu nhập'), findsOneWidget);
      expect(find.text('Review'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-09] Cancelled shows only View reason, no chat or overflow',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.cancelled,
        viewerRole: UserRole.client,
      )));

      expect(find.text('Xem lý do'), findsOneWidget);
      expect(find.byTooltip('Trò chuyện'), findsNothing);
      expect(find.byTooltip('Thêm thao tác'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-11] AwaitingWorker worker can accept an eligible booking',
    (tester) async {
      var accepted = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.awaitingWorker,
        viewerRole: UserRole.worker,
        onAccept: () async => accepted = true,
      )));

      final acceptButton = find.widgetWithText(FilledButton, 'Nhận việc');
      expect(acceptButton, findsOneWidget);
      await tester.tap(acceptButton);
      await tester.pumpAndSettle();
      expect(accepted, isTrue);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-19] AwaitingWorker worker can hide the job from the overflow menu, from the '
    'Booking Detail screen (not only the swipe action on the Available Jobs list)',
    (tester) async {
      var hidden = false;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.awaitingWorker,
        viewerRole: UserRole.worker,
        onAccept: () async {},
        onHideJob: () async => hidden = true,
      )));

      expect(find.byTooltip('Thêm thao tác'), findsOneWidget);
      await tapOverflow(tester, 'Ẩn công việc này');
      expect(hidden, isTrue);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-10] RescheduleRequested: the action bar only keeps Chat — RescheduleBanner '
    '(rendered separately on the screen) owns Accept/Reject/Withdraw for this status',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.rescheduleRequested,
        viewerRole: UserRole.client,
      )));

      expect(find.widgetWithText(FilledButton, 'Chấp nhận giờ mới'), findsNothing);
      expect(find.text('Hủy đặt lịch'), findsNothing);
      expect(find.byTooltip('Trò chuyện'), findsOneWidget);
      expect(find.byTooltip('Thêm thao tác'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-12] Report sheet reaches onReport with the picked reason code and free text',
    (tester) async {
      String? reportedCode;
      String? reportedText;
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.onTheWay,
        viewerRole: UserRole.worker,
        onReport: (reasonCode, freeText) async {
          reportedCode = reasonCode;
          reportedText = freeText;
        },
      )));

      await tester.tap(find.byTooltip('Thêm thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Báo cáo').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Khách hàng vắng mặt'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Khach khong co mat tai dia diem hen');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pumpAndSettle();

      expect(reportedCode, 'report.worker.client_absent');
      expect(reportedText, 'Khach khong co mat tai dia diem hen');
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-13] A non-empty status timeline shows a History icon that opens it in a sheet, '
    'with each entry dated dd/MM/yyyy HH:mm in local time',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.completed,
        viewerRole: UserRole.client,
        statusTimeline: const [
          {'newStatus': 'Accepted', 'reason': '', 'createdAt': '2026-07-08T09:30:00.000'},
          {'newStatus': 'Completed', 'reason': 'Đã xong', 'createdAt': '2026-07-08T11:05:00.000'},
        ],
      )));

      final historyIcon = find.byTooltip('Lịch sử');
      expect(historyIcon, findsOneWidget);

      await tester.tap(historyIcon);
      await tester.pumpAndSettle();

      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('08/07/2026 09:30'), findsOneWidget);
      // Timestamp and reason share the subtitle, newline-separated.
      expect(find.text('08/07/2026 11:05\nĐã xong'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-17] History entries without a parseable createdAt still render, just undated',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.completed,
        viewerRole: UserRole.client,
        statusTimeline: const [
          {'newStatus': 'Accepted', 'reason': ''},
        ],
      )));

      await tester.tap(find.byTooltip('Lịch sử'));
      await tester.pumpAndSettle();

      expect(find.text('Accepted'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOKACT-14] No History icon when the status timeline is empty',
    (tester) async {
      await tester.pumpWidget(wrap(bar(
        status: BookingStatusName.completed,
        viewerRole: UserRole.client,
      )));

      expect(find.byTooltip('Lịch sử'), findsNothing);
    },
  );
}
