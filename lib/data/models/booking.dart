import 'dart:convert';

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
  final DateTime? scheduledStartTime;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final List<Map<String, dynamic>> statusTimeline;
  final List<Map<String, dynamic>> photos;
  final List<Map<String, dynamic>> pricingBreakdown;
  final double durationHours;
  final double unitPrice;
  final double extraFee;
  final double discountAmount;
  final String notes;
  final Map<String, dynamic> optionAnswers;
  final List<Map<String, dynamic>> bookingQuestions;

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
    this.scheduledStartTime,
    this.updatedAt,
    this.createdAt,
    this.statusTimeline = const [],
    this.photos = const [],
    this.pricingBreakdown = const [],
    this.durationHours = 0,
    this.unitPrice = 0,
    this.extraFee = 0,
    this.discountAmount = 0,
    this.notes = '',
    this.optionAnswers = const {},
    this.bookingQuestions = const [],
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
    final answers = _jsonMap(json['optionAnswers']);
    final schema = _jsonMap(json['bookingFormSchema']);
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
      scheduledStartTime: rawScheduled == null ? null : DateTime.tryParse(rawScheduled)?.toLocal(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      statusTimeline: List<Map<String, dynamic>>.from(json['statusTimeline'] as List? ?? const []),
      photos: List<Map<String, dynamic>>.from(json['photos'] as List? ?? const []),
      pricingBreakdown: List<Map<String, dynamic>>.from(
        (json['pricingBreakdown'] as Map?)?['breakdown'] as List? ?? const [],
      ),
      durationHours: (json['durationHours'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      extraFee: (json['extraFee'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString() ?? '',
      optionAnswers: answers,
      bookingQuestions: List<Map<String, dynamic>>.from(schema['questions'] as List? ?? const []),

      addressText: json['addressText'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  static Map<String, dynamic> _jsonMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const {};
  }
}
