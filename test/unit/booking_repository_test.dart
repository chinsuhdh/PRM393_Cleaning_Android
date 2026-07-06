import 'package:cleanai/core/constants/booking_enums.dart';
import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test(
    '[UT-FE-BOOK-CANCEL-01] cancelBooking sends the Cancelled status name, not InProgress',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPatch(
        '/Bookings/b1/status',
        (server) => server.reply(200, {'message': 'ok'}),
        data: {'newStatus': BookingStatusName.cancelled},
      );
      final repository = ApiBookingRepository(harness.dio);

      await repository.cancelBooking('b1');

      expect(BookingStatusName.cancelled, 'Cancelled');
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
