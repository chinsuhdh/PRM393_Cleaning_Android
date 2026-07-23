import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/constants/booking_enums.dart';
import 'worker.dart';

part 'booking.freezed.dart';

const _emptyMapList = <Map<String, dynamic>>[];
const _emptyJsonMap = <String, dynamic>{};
const _emptyRescheduleList = <RescheduleProposal>[];

@Freezed(fromJson: false, toJson: false)
class RescheduleProposal with _$RescheduleProposal {
  const RescheduleProposal._();

  const factory RescheduleProposal({
    required String id,
    required String requestedBy,
    required DateTime oldStartTime,
    required DateTime oldEndTime,
    required DateTime newStartTime,
    required DateTime newEndTime,
    required String status,
    String? reason,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) = _RescheduleProposal;

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

@Freezed(fromJson: false, toJson: false)
class Booking with _$Booking {
  const Booking._();

  const factory Booking({
    required String id,
    @Default('') String serviceId,
    required String serviceName,
    required String date,
    required String time,
    required double price,
    required String status,
    @Default('Cash') String paymentMethod,
    @Default('') String bookingType,
    Worker? worker,
    DateTime? scheduledStartTime,
    DateTime? actualStartTime,
    DateTime? updatedAt,
    DateTime? createdAt,
    @Default(_emptyMapList) List<Map<String, dynamic>> statusTimeline,
    @Default(_emptyMapList) List<Map<String, dynamic>> photos,
    @Default(_emptyMapList) List<Map<String, dynamic>> pricingBreakdown,
    @Default(0) double durationHours,
    @Default(0) double unitPrice,
    @Default(0) double extraFee,
    @Default(0) double discountAmount,
    @Default('') String notes,
    @Default(_emptyJsonMap) Map<String, dynamic> optionAnswers,
    @Default(_emptyMapList) List<Map<String, dynamic>> bookingQuestions,
    String? addressText,
    double? latitude,
    double? longitude,
    double? distanceKm,
    double? estimatedMinutes,
    RescheduleProposal? pendingReschedule,
    @Default(_emptyRescheduleList) List<RescheduleProposal> rescheduleHistory,
  }) = _Booking;

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
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return const {};
}
