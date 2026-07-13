import 'package:cleanai/data/models/payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '[UT-FE-PAY-MODEL-01] Payment.fromJson parses all fields',
    () {
      final payment = Payment.fromJson({
        'id': 'p1',
        'bookingId': 'b1',
        'amount': 250000,
        'method': 'Payos',
        'status': 'Success',
        'transactionId': '14000123',
        'paidAt': '2026-07-11T09:00:00.000Z',
        'createdAt': '2026-07-11T08:00:00.000Z',
      });

      expect(payment.id, 'p1');
      expect(payment.bookingId, 'b1');
      expect(payment.amount, 250000);
      expect(payment.method, 'Payos');
      expect(payment.status, 'Success');
      expect(payment.transactionId, '14000123');
      expect(payment.isSuccess, isTrue);
      expect(payment.paidAt, isNotNull);
      expect(payment.createdAt, isNotNull);
    },
  );

  test(
    '[UT-FE-PAY-MODEL-02] Payment.fromJson defaults missing fields',
    () {
      final payment = Payment.fromJson({'id': 'p1', 'bookingId': 'b1', 'amount': 100000});

      expect(payment.method, 'Cash');
      expect(payment.status, 'Pending');
      expect(payment.isSuccess, isFalse);
      expect(payment.transactionId, isNull);
      expect(payment.paidAt, isNull);
    },
  );
}
