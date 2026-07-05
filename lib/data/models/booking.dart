import '../../core/constants/booking_enums.dart';
import 'worker.dart';

class Booking {
  final String id;
  final String serviceName;
  final String date;
  final String time;
  final double price;
  final String status;
  final String bookingType;
  final Worker? worker;

  final String? addressText;
  final double? latitude;
  final double? longitude;

  const Booking({
    required this.id,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    this.bookingType = '',
    this.worker,
    this.addressText,
    this.latitude,
    this.longitude,
  });

  bool get isImmediate => bookingType == BookingTypeName.immediate;

  bool get isAwaitingWorker => status == BookingStatusName.awaitingWorker;

  // PendingPayment is post-job (pay-after-job): the worker is still attached.
  bool get hasWorkerAssigned =>
      status == BookingStatusName.accepted ||
      status == BookingStatusName.onTheWay ||
      status == BookingStatusName.inProgress ||
      status == BookingStatusName.pendingPayment ||
      status == BookingStatusName.completed;

  factory Booking.fromJson(Map<String, dynamic> json) {
    String date = '';
    String time = '';
    final rawScheduled =
        (json['scheduledStartTime'] ?? json['scheduledTime']) as String?;

    if (rawScheduled != null && rawScheduled.isNotEmpty) {
      final dt = DateTime.tryParse(rawScheduled)?.toLocal();
      if (dt != null) {
        date = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        date = rawScheduled;
      }
    }

    // The API serializes enums by name (e.g. "AwaitingWorker").
    final statusStr = json['status']?.toString() ?? 'Unknown';

    String serviceName = (json['serviceName'] as String?) ?? '';
    if (serviceName.isEmpty) {
      final serviceObj = json['service'] as Map<String, dynamic>?;
      serviceName = (serviceObj?['name'] as String?) ?? 'Dịch vụ #${json['serviceId'].toString().substring(0, 8)}';
    }

    return Booking(
      id: (json['id'] ?? '').toString(),
      serviceName: serviceName,
      date: date,
      time: time,
      price: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: statusStr,
      bookingType: (json['bookingType'] as String?) ?? '',
      worker: json['worker'] != null ? Worker.fromJson(json['worker'] as Map<String, dynamic>) : null,

      addressText: json['addressText'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}