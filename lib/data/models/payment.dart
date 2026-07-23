import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class Payment with _$Payment {
  const Payment._();

  const factory Payment({
    required String id,
    required String bookingId,
    required double amount,
    required String method,
    required String status,
    String? transactionId,
    DateTime? paidAt,
    DateTime? createdAt,
  }) = _Payment;

  bool get isSuccess => status == 'Success';

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: (json['id'] ?? '').toString(),
        bookingId: (json['bookingId'] ?? '').toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        method: json['method']?.toString() ?? 'Cash',
        status: json['status']?.toString() ?? 'Pending',
        transactionId: json['transactionId'] as String?,
        paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? '')?.toLocal(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      );
}
