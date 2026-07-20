import 'dart:convert';

import '../../core/constants/booking_enums.dart';
import 'worker.dart';

class RescheduleProposal {
  final String id;
  final String requestedBy;
  final DateTime oldStartTime;
  final DateTime oldEndTime;
  final DateTime newStartTime;
  final DateTime newEndTime;
  final String status;
  final String? reason;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  const RescheduleProposal({
    required this.id,
    required this.requestedBy,
    required this.oldStartTime,
    required this.oldEndTime,
    required this.newStartTime,
    required this.newEndTime,
    required this.status,
    this.reason,
    this.createdAt,
    this.respondedAt,
  });

  bool get isPending => status == 'Pending';

  factory RescheduleProposal.fromJson(Map<String, dynamic> json) => RescheduleProposal(
        id: (json['id'] ?? '').toString(),
        requestedBy: (json['requestedBy'] ?? '').toString(),
        oldStartTime: DateTime.tryParse(json['oldStartTime']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        oldEndTime: DateTime.tryParse(json['oldEndTime']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        newStartTime: DateTime.tryParse(json['newStartTime']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        newEndTime: DateTime.tryParse(json['newEndTime']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        status: json['status']?.toString() ?? 'Unknown',
        reason: json['reason'] as String?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
        respondedAt: DateTime.tryParse(json['respondedAt']?.toString() ?? '')?.toLocal(),
      );
}

class Booking {
  final String id;
  final String serviceId;
  final String serviceName;
  final String date;
  final String time;
  final double price;
  final String status;
  final String paymentMethod;
  final String bookingType;
  final Worker? worker;
  final DateTime? scheduledStartTime;
  final DateTime? actualStartTime;
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
  final double? distanceKm;
  final double? estimatedMinutes;

  final RescheduleProposal? pendingReschedule;
  final List<RescheduleProposal> rescheduleHistory;

  const Booking({
    required this.id,
    this.serviceId = '',
    required this.serviceName,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    this.paymentMethod = 'Cash',
    this.bookingType = '',
    this.worker,
    this.scheduledStartTime,
    this.actualStartTime,
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
    this.distanceKm,
    this.estimatedMinutes,
    this.pendingReschedule,
    this.rescheduleHistory = const [],
  });

  bool get isImmediate => bookingType == BookingTypeName.immediate;

  bool get isAwaitingWorker => status == BookingStatusName.awaitingWorker;

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

    final statusStr = json['status']?.toString() ?? 'Unknown';

    String serviceName = (json['serviceName'] as String?) ?? '';
    if (serviceName.isEmpty) {
      final serviceObj = json['service'] as Map<String, dynamic>?;
      serviceName = (serviceObj?['name'] as String?) ?? 'Dịch vụ #${json['serviceId'].toString().substring(0, 8)}';
    }

    return Booking(
      id: (json['id'] ?? '').toString(),
      serviceId: (json['serviceId'] ?? '').toString(),
      serviceName: serviceName,
      date: date,
      time: time,
      price: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: statusStr,
      paymentMethod: (json['paymentMethod'] as String?) ?? 'Cash',
      bookingType: (json['bookingType'] as String?) ?? '',
      worker: json['worker'] != null ? Worker.fromJson(json['worker'] as Map<String, dynamic>) : null,
      scheduledStartTime: rawScheduled == null ? null : DateTime.tryParse(rawScheduled)?.toLocal(),
      actualStartTime: DateTime.tryParse(json['actualStartTime']?.toString() ?? '')?.toLocal(),
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
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toDouble(),

      pendingReschedule: json['pendingReschedule'] != null
          ? RescheduleProposal.fromJson(json['pendingReschedule'] as Map<String, dynamic>)
          : null,
      rescheduleHistory: (json['rescheduleHistory'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RescheduleProposal.fromJson)
          .toList(),
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
