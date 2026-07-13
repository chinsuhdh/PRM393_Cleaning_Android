import 'package:cleanai/core/constants/booking_enums.dart';
import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test(
    '[UT-FE-BOOK-DETAIL-01] booking detail retains pricing, notes, answers, and form schema',
    () {
      final booking = Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Deep clean',
        'status': 'AwaitingWorker',
        'durationHours': 3,
        'unitPrice': 100000,
        'extraFee': 25000,
        'discountAmount': 10000,
        'notes': 'Bring pet-safe products',
        'optionAnswers': '{"rooms":3,"pets":true}',
        'bookingFormSchema': '{"questions":[{"id":"rooms","label":"Rooms"},{"id":"pets","label":"Pets"}]}',
      });

      expect(booking.durationHours, 3);
      expect(booking.unitPrice, 100000);
      expect(booking.extraFee, 25000);
      expect(booking.discountAmount, 10000);
      expect(booking.notes, 'Bring pet-safe products');
      expect(booking.optionAnswers['rooms'], 3);
      expect(booking.bookingQuestions.first['label'], 'Rooms');
    },
  );

  test(
    '[UT-FE-BOOK-CANCEL-01] cancelBookingByClient POSTs the dedicated cancel endpoint',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Bookings/b1/cancel',
        (server) => server.reply(200, {'message': 'ok'}),
        data: null,
      );
      final repository = ApiBookingRepository(harness.dio);

      await repository.cancelBookingByClient('b1');
    },
  );

  test(
    '[UT-FE-BOOK-CANCEL-02] workerCancelBooking POSTs the reason code and optional free text',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Bookings/b1/worker-cancel',
        (server) => server.reply(200, {'message': 'ok'}),
        data: {'reasonCode': 'worker_cancel.other', 'freeText': 'Xe hong'},
      );
      final repository = ApiBookingRepository(harness.dio);

      await repository.workerCancelBooking('b1', 'worker_cancel.other', freeText: 'Xe hong');
    },
  );

  test(
    '[UT-FE-BOOK-CANCEL-03] workerCancelBooking maps WORKER_SUSPENDED to WorkerSuspendedException',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Bookings/b1/worker-cancel',
        (server) => server.reply(403, {
          'success': false,
          'message': 'Tài khoản của bạn đã bị tạm khóa.',
          'data': null,
          'errorCode': 'WORKER_SUSPENDED',
        }),
        data: {'reasonCode': 'worker_cancel.too_far'},
      );
      final repository = ApiBookingRepository(harness.dio);

      expect(
        () => repository.workerCancelBooking('b1', 'worker_cancel.too_far'),
        throwsA(isA<WorkerSuspendedException>()),
      );
    },
  );

  test(
    '[UT-FE-PAY-SWC-01] switchToCash POSTs the dedicated switch-to-cash endpoint',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Bookings/b1/switch-to-cash',
        (server) => server.reply(200, {'message': 'ok'}),
        data: null,
      );
      final repository = ApiBookingRepository(harness.dio);

      await repository.switchToCash('b1');
    },
  );

  test(
    '[UT-FE-BOOK-RSC-01] proposeReschedule POSTs the new start time (UTC) and returns the hydrated booking',
    () async {
      final harness = DioTestHarness();
      final newStart = DateTime.utc(2026, 7, 12, 9, 0, 0);
      harness.adapter.onPost(
        '/Bookings/b1/reschedule',
        (server) => server.reply(200, {
          'id': 'b1',
          'serviceName': 'Dọn nhà',
          'status': 'RescheduleRequested',
        }),
        data: {'newStartTime': newStart.toIso8601String(), 'message': 'Xin doi lich'},
      );
      final repository = ApiBookingRepository(harness.dio);

      final booking = await repository.proposeReschedule('b1', newStart, message: 'Xin doi lich');

      expect(booking.status, 'RescheduleRequested');
    },
  );

  test(
    '[UT-FE-BOOK-RSC-02] proposeReschedule maps RESCHEDULE_ALREADY_PENDING to a typed exception',
    () async {
      final harness = DioTestHarness();
      final newStart = DateTime.utc(2026, 7, 12, 9, 0, 0);
      harness.adapter.onPost(
        '/Bookings/b1/reschedule',
        (server) => server.reply(409, {
          'success': false,
          'message': 'Đã có một yêu cầu dời lịch đang chờ phản hồi.',
          'data': null,
          'errorCode': 'RESCHEDULE_ALREADY_PENDING',
        }),
        data: {'newStartTime': newStart.toIso8601String()},
      );
      final repository = ApiBookingRepository(harness.dio);

      expect(
        () => repository.proposeReschedule('b1', newStart),
        throwsA(isA<RescheduleAlreadyPendingException>()),
      );
    },
  );

  test(
    '[UT-FE-BOOK-RSC-03] respondReschedule PATCHes the reschedule/{requestId} endpoint with the action',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPatch(
        '/Bookings/b1/reschedule/r1',
        (server) => server.reply(200, {
          'id': 'b1',
          'serviceName': 'Dọn nhà',
          'status': 'Accepted',
        }),
        data: {'action': RescheduleActionName.accept},
      );
      final repository = ApiBookingRepository(harness.dio);

      final booking = await repository.respondReschedule('b1', 'r1', RescheduleActionName.accept);

      expect(booking.status, 'Accepted');
    },
  );

  test(
    '[UT-FE-BOOK-RPT-01] reportBooking POSTs the reason code and free text',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Bookings/b1/report',
        (server) => server.reply(200, {'message': 'ok'}),
        data: {'reasonCode': 'report.client.worker_no_show', 'freeText': 'Nhan vien khong den dung gio'},
      );
      final repository = ApiBookingRepository(harness.dio);

      await repository.reportBooking('b1', 'report.client.worker_no_show', 'Nhan vien khong den dung gio');
    },
  );

  test(
    '[UT-FE-BOOK-STATUS-03] updateBookingStatus sends an optional reason for report/cancel actions (D.8)',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPatch(
        '/Bookings/b1/status',
        (server) => server.reply(200, {'message': 'ok'}),
        data: {'newStatus': BookingStatusName.cancelled, 'reason': 'Khach vang mat'},
      );
      final repository = ApiBookingRepository(harness.dio);

      await repository.updateBookingStatus('b1', BookingStatusName.cancelled, reason: 'Khach vang mat');
    },
  );

  test(
    '[UT-FE-BOOK-STATUS-04] updateBookingStatus omits the reason field when none is given',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPatch(
        '/Bookings/b1/status',
        (server) => server.reply(200, {'message': 'ok'}),
        data: {'newStatus': BookingStatusName.onTheWay},
      );
      final repository = ApiBookingRepository(harness.dio);

      await repository.updateBookingStatus('b1', BookingStatusName.onTheWay);
    },
  );

  test(
    '[UT-FE-BOOK-ACCEPT-01] acceptBooking PATCHes the accept endpoint',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPatch(
        '/Bookings/b1/accept',
        (server) => server.reply(200, {'message': 'ok'}),
        data: null,
      );
      final repository = ApiBookingRepository(harness.dio);

      await repository.acceptBooking('b1');
    },
  );

  test(
    '[UT-FE-BOOK-GET-01] getBookingById parses the returned booking',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Bookings/b1',
        (server) => server.reply(200, {
          'id': 'b1',
          'serviceName': 'Dọn nhà',
          'status': 'AwaitingWorker',
          'bookingType': 'Immediate',
          'totalPrice': 200000,
        }),
        data: null,
      );
      final repository = ApiBookingRepository(harness.dio);

      final booking = await repository.getBookingById('b1');

      expect(booking, isNotNull);
      expect(booking!.status, 'AwaitingWorker');
      expect(booking.isImmediate, isTrue);
    },
  );

  test(
    '[UT-FE-BOOK-STATUS-01] booking status is parsed by name (API serializes enums by name)',
    () {
      Booking parseWithStatus(Object? code) => Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': code,
      });

      expect(parseWithStatus('Cancelled').status, 'Cancelled');
      expect(parseWithStatus('OnTheWay').status, 'OnTheWay');
      expect(parseWithStatus('AwaitingWorker').status, 'AwaitingWorker');
      expect(parseWithStatus(null).status, 'Unknown');
    },
  );

  test(
    '[UT-FE-BOOK-STATUS-02] string booking status is passed through unchanged',
    () {
      Booking parseWithStatus(String code) => Booking.fromJson({
        'id': 'b1',
        'serviceName': 'Dọn nhà',
        'status': code,
      });

      expect(parseWithStatus('Cancelled').status, 'Cancelled');
      expect(parseWithStatus('AwaitingWorker').status, 'AwaitingWorker');
    },
  );

  test(
    '[UT-FE-BOOK-LIST-01] getClientBookings parses a list of bookings',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Bookings/client',
        (server) => server.reply(200, {
          'success': true,
          'message': 'ok',
          'data': [
            {'id': 'b1', 'serviceName': 'Dọn nhà', 'status': 'AwaitingWorker'},
            {'id': 'b2', 'serviceName': 'Giặt ủi', 'status': 'Completed'},
          ],
          'errorCode': null,
        }),
        data: null,
      );
      final repository = ApiBookingRepository(harness.dio);

      final bookings = await repository.getClientBookings();

      expect(bookings, hasLength(2));
      expect(bookings.first.id, 'b1');
    },
  );

  test(
    '[UT-FE-BOOK-LIST-02] getWorkerBookings returns [] when the body is not a list',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Bookings/worker',
        (server) => server.reply(200, {'unexpected': 'shape'}),
        data: null,
      );
      final repository = ApiBookingRepository(harness.dio);

      final bookings = await repository.getWorkerBookings();

      expect(bookings, isEmpty);
    },
  );

  test(
    '[UT-FE-BOOK-LIST-03] getAvailableBookings surfaces a server error',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Bookings/available',
        (server) => server.reply(500, {'message': 'boom'}),
        data: null,
      );
      final repository = ApiBookingRepository(harness.dio);

      expect(repository.getAvailableBookings(), throwsA(isA<Exception>()));
    },
  );

  test(
    '[UT-FE-BOOK-CREATE-01] createBooking posts the payload and parses the returned booking',
    () async {
      final harness = DioTestHarness();
      final request = {'serviceId': 's1', 'bookingType': 'Immediate', 'durationHours': 2};
      harness.adapter.onPost(
        '/Bookings',
        (server) => server.reply(200, {
          'success': true,
          'message': 'Tạo đơn thành công.',
          'data': {
            'id': 'b9',
            'serviceName': 'Dọn nhà',
            'status': 'AwaitingWorker',
            'bookingType': 'Immediate',
            'totalPrice': 200000,
          },
          'errorCode': null,
        }),
        data: request,
      );
      final repository = ApiBookingRepository(harness.dio);

      final booking = await repository.createBooking(request, idempotencyKey: 'idem-1');

      expect(booking.id, 'b9');
      expect(booking.isImmediate, isTrue);
    },
  );

  test(
    '[UT-FE-BOOK-CREATE-02] createBooking surfaces the backend message on failure',
    () async {
      final harness = DioTestHarness();
      final request = {'serviceId': 's1', 'bookingType': 'Immediate', 'durationHours': 2};
      harness.adapter.onPost(
        '/Bookings',
        (server) => server.reply(400, {'message': 'Thời gian nằm ngoài giờ hoạt động.'}),
        data: request,
      );
      final repository = ApiBookingRepository(harness.dio);

      expect(
        () => repository.createBooking(request, idempotencyKey: 'idem-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Thời gian nằm ngoài giờ hoạt động.'),
          ),
        ),
      );
    },
  );

  test(
    '[UT-FE-BOOK-AVAIL-01] getAvailability passes through the backend emptyMessage',
    () async {
      final harness = DioTestHarness();
      final request = {'serviceId': 's1'};
      harness.adapter.onPost(
        '/Bookings/availability',
        (server) => server.reply(200, {
          'slots': [],
          'emptyMessage': 'Không có nhân viên nào rảnh lúc này.',
        }),
        data: request,
      );
      final repository = ApiBookingRepository(harness.dio);

      final result = await repository.getAvailability(request);

      expect(result['emptyMessage'], 'Không có nhân viên nào rảnh lúc này.');
    },
  );

  test(
    '[UT-FE-BOOK-AVAIL-02] getAvailability throws the mapped message on a DioException',
    () async {
      final harness = DioTestHarness();
      final request = {'serviceId': 's1'};
      harness.adapter.onPost(
        '/Bookings/availability',
        (server) => server.reply(400, {'message': 'Địa chỉ không hợp lệ.'}),
        data: request,
      );
      final repository = ApiBookingRepository(harness.dio);

      expect(
        () => repository.getAvailability(request),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Địa chỉ không hợp lệ.'),
          ),
        ),
      );
    },
  );
}
