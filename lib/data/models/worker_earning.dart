class WorkerEarning {
  final String id;
  final String bookingId;
  final double amount;
  final String status;
  final DateTime? earnedAt;
  final DateTime? paidAt;
  final String? payoutFailureReason;

  const WorkerEarning({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    this.earnedAt,
    this.paidAt,
    this.payoutFailureReason,
  });

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
