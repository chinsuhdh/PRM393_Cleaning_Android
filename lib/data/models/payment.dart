class Payment {
  final String id;
  final String bookingId;
  final double amount;
  final String method;
  final String status;
  final String? transactionId;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.paidAt,
    this.createdAt,
  });

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
