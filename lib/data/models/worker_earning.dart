import 'package:freezed_annotation/freezed_annotation.dart';

part 'worker_earning.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class WorkerEarning with _$WorkerEarning {
  const WorkerEarning._();

  const factory WorkerEarning({
    required String id,
    required String bookingId,
    required double amount,
    required String status,
    DateTime? earnedAt,
    DateTime? paidAt,
    String? payoutFailureReason,
  }) = _WorkerEarning;

  bool get isPaid => status == 'paid' || status == 'settled';

  factory WorkerEarning.fromJson(Map<String, dynamic> json) => WorkerEarning(
        id: (json['id'] ?? '').toString(),
        bookingId: (json['bookingId'] ?? '').toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        status: json['status']?.toString() ?? 'pending',
        earnedAt: DateTime.tryParse(json['earnedAt']?.toString() ?? '')?.toLocal(),
        paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? '')?.toLocal(),
        payoutFailureReason: json['payoutFailureReason'] as String?,
      );
}
