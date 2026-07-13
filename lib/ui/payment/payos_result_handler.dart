import '../../data/repositories/payment_repository.dart';

enum PayosPaymentVerdict { success, pending }

class PayosResultHandler {
  const PayosResultHandler(this._paymentRepository, {this.pollCount = 3, this.pollDelay = const Duration(seconds: 2)});

  final PaymentRepository _paymentRepository;
  final int pollCount;
  final Duration pollDelay;

  Future<PayosPaymentVerdict> awaitVerdict(String bookingId) async {
    for (var attempt = 0; attempt < pollCount; attempt++) {
      final payment = await _paymentRepository.getPaymentByBooking(bookingId);
      if (payment != null && payment.isSuccess) return PayosPaymentVerdict.success;
      if (attempt < pollCount - 1) await Future.delayed(pollDelay);
    }
    return PayosPaymentVerdict.pending;
  }
}
