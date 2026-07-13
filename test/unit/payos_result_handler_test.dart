import 'package:cleanai/data/models/payment.dart';
import 'package:cleanai/data/repositories/payment_repository.dart';
import 'package:cleanai/ui/payment/payos_checkout_screen.dart';
import 'package:cleanai/ui/payment/payos_result_handler.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository(this.responses);
  final List<Payment?> responses;
  int callCount = 0;

  @override
  Future<Payment?> getPaymentByBooking(String bookingId) async {
    final response = responses[callCount.clamp(0, responses.length - 1)];
    callCount++;
    return response;
  }

  @override
  Future<({String paymentId, String paymentUrl})> payNow(String bookingId) async =>
      (paymentId: 'p1', paymentUrl: 'https://pay.payos.vn/web/123456');
}

Payment _payment(String status) => Payment(
      id: 'p1',
      bookingId: 'b1',
      amount: 100000,
      method: 'Payos',
      status: status,
    );

void main() {
  test(
    '[UT-FE-PAYOSRET-01] isPayosReturnUrl matches the return path regardless of host',
    () {
      expect(
        isPayosReturnUrl('https://api.example.com/api/Payments/payos-return?code=00'),
        isTrue,
      );
      expect(isPayosReturnUrl('https://pay.payos.vn/web/123456'), isFalse);
    },
  );

  test(
    '[UT-FE-PAYOSRES-01] awaitVerdict returns success as soon as the payment is Success',
    () async {
      final repository = _FakePaymentRepository([_payment('Success')]);
      final handler = PayosResultHandler(repository, pollDelay: Duration.zero);

      final verdict = await handler.awaitVerdict('b1');

      expect(verdict, PayosPaymentVerdict.success);
      expect(repository.callCount, 1);
    },
  );

  test(
    '[UT-FE-PAYOSRES-02] awaitVerdict returns pending after exhausting all polls without success',
    () async {
      final repository = _FakePaymentRepository([_payment('Pending')]);
      final handler = PayosResultHandler(repository, pollCount: 3, pollDelay: Duration.zero);

      final verdict = await handler.awaitVerdict('b1');

      expect(verdict, PayosPaymentVerdict.pending);
      expect(repository.callCount, 3);
    },
  );

  test(
    '[UT-FE-PAYOSRES-03] awaitVerdict succeeds on a later poll once the webhook has caught up',
    () async {
      final repository = _FakePaymentRepository([_payment('Pending'), _payment('Success')]);
      final handler = PayosResultHandler(repository, pollCount: 3, pollDelay: Duration.zero);

      final verdict = await handler.awaitVerdict('b1');

      expect(verdict, PayosPaymentVerdict.success);
      expect(repository.callCount, 2);
    },
  );
}
