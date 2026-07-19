import 'package:cleanai/data/repositories/payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test(
    '[UT-FE-PAY-001] payNow POSTs the booking id and parses the returned payment URL',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Payments',
        (server) => server.reply(200, {
          'success': true,
          'message': 'ok',
          'data': {
            'paymentId': 'p1',
            'paymentUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_TxnRef=123456',
          },
          'errorCode': null,
        }),
        data: {'bookingId': 'b1'},
      );
      final repository = ApiPaymentRepository(harness.dio);

      final result = await repository.payNow('b1');

      expect(result.paymentId, 'p1');
      expect(result.paymentUrl, contains('vnpayment.vn'));
    },
  );

  test(
    '[UT-FE-PAY-002] payNow surfaces the backend message on failure',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Payments',
        (server) => server.reply(400, {'message': 'Đơn này không dùng thanh toán trực tuyến VNPay.'}),
        data: {'bookingId': 'b1'},
      );
      final repository = ApiPaymentRepository(harness.dio);

      expect(
        () => repository.payNow('b1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Đơn này không dùng thanh toán trực tuyến VNPay.'),
          ),
        ),
      );
    },
  );

  test(
    '[UT-FE-PAY-003] getPaymentByBooking parses the returned payment',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Payments/booking/b1',
        (server) => server.reply(200, {
          'success': true,
          'message': 'ok',
          'data': {'id': 'p1', 'bookingId': 'b1', 'amount': 100000, 'status': 'Success'},
          'errorCode': null,
        }),
        data: null,
      );
      final repository = ApiPaymentRepository(harness.dio);

      final payment = await repository.getPaymentByBooking('b1');

      expect(payment, isNotNull);
      expect(payment!.isSuccess, isTrue);
    },
  );

  test(
    '[UT-FE-PAY-004] getPaymentByBooking returns null on a 404',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Payments/booking/b1',
        (server) => server.reply(404, {
          'success': false,
          'message': 'Không tìm thấy thông tin thanh toán cho đơn này.',
          'data': null,
          'errorCode': 'PAYMENT_NOT_FOUND',
        }),
        data: null,
      );
      final repository = ApiPaymentRepository(harness.dio);

      final payment = await repository.getPaymentByBooking('b1');

      expect(payment, isNull);
    },
  );

  test(
    '[UT-FE-PAY-005] confirmVnpayReturn forwards the return URL query params and reports success',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Payments/vnpay-confirm',
        (server) => server.reply(200, {
          'success': true,
          'message': 'ok',
          'data': {'success': true, 'outcome': 'Success'},
          'errorCode': null,
        }),
        queryParameters: {'vnp_TxnRef': '123456', 'vnp_ResponseCode': '00'},
      );
      final repository = ApiPaymentRepository(harness.dio);

      final success = await repository.confirmVnpayReturn(
        'https://api.example.com/api/Payments/vnpay-return?vnp_TxnRef=123456&vnp_ResponseCode=00',
      );

      expect(success, isTrue);
    },
  );

  test(
    '[UT-FE-PAY-006] confirmVnpayReturn returns false when the backend reports a non-success outcome',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Payments/vnpay-confirm',
        (server) => server.reply(200, {
          'success': true,
          'message': 'ok',
          'data': {'success': false, 'outcome': 'InvalidSignature'},
          'errorCode': null,
        }),
        queryParameters: {'vnp_TxnRef': '123456', 'vnp_ResponseCode': '24'},
      );
      final repository = ApiPaymentRepository(harness.dio);

      final success = await repository.confirmVnpayReturn(
        'https://api.example.com/api/Payments/vnpay-return?vnp_TxnRef=123456&vnp_ResponseCode=24',
      );

      expect(success, isFalse);
    },
  );

  test(
    '[UT-FE-PAY-007] confirmVnpayReturn returns false on a network error instead of throwing',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Payments/vnpay-confirm',
        (server) => server.reply(500, {'message': 'Lỗi hệ thống.'}),
        queryParameters: {'vnp_TxnRef': '123456'},
      );
      final repository = ApiPaymentRepository(harness.dio);

      final success = await repository.confirmVnpayReturn(
        'https://api.example.com/api/Payments/vnpay-return?vnp_TxnRef=123456',
      );

      expect(success, isFalse);
    },
  );
}
