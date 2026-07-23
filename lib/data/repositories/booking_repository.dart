import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';
import '../models/booking.dart';

part 'booking_repository.g.dart';

abstract class BookingRepository {
  Future<List<Booking>> getClientBookings();

  Future<List<Booking>> getWorkerBookings();

  Future<List<Booking>> getAvailableBookings();

  Future<Booking> getBookingById(String bookingId);

  Future<Map<String, dynamic>> getAvailability(Map<String, dynamic> data);

  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data);

  Future<Booking> createBooking(
    Map<String, dynamic> data, {
    required String idempotencyKey,
  });

  Future<void> acceptBooking(String bookingId);

  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason});

  Future<void> updateDuration(String bookingId, double hours);

  Future<void> uploadPhotos(String bookingId, List<MultipartFile> photos);

  Future<void> cancelBookingByClient(String bookingId);

  Future<void> workerCancelBooking(String bookingId, String reasonCode, {String? freeText});

  Future<void> clientCancelBooking(String bookingId, String reasonCode, {String? freeText});

  Future<void> reportBooking(String bookingId, String reasonCode, String freeText);

  Future<Booking> proposeReschedule(String bookingId, DateTime newStartTime, {String? message});

  Future<Booking> respondReschedule(String bookingId, String requestId, String action);

  Future<void> switchToCash(String bookingId);
}

class RescheduleActionName {
  const RescheduleActionName._();

  static const String accept = 'Accept';
  static const String reject = 'Reject';
  static const String withdraw = 'Withdraw';
}

class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Booking>> getClientBookings() => guardApiCall(() async {
    final response = await _dio.get('/Bookings/client');
    final raw = response.data;
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(Booking.fromJson).toList();
  });

  @override
  Future<List<Booking>> getWorkerBookings() => guardApiCall(() async {
    final response = await _dio.get('/Bookings/worker');
    final raw = response.data;
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(Booking.fromJson).toList();
  });

  @override
  Future<List<Booking>> getAvailableBookings() => guardApiCall(() async {
    final response = await _dio.get('/Bookings/available');
    final raw = response.data;
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(Booking.fromJson).toList();
  });

  @override
  Future<Booking> getBookingById(String bookingId) => guardApiCall(() async {
    final response = await _dio.get('/Bookings/$bookingId');
    return Booking.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Map<String, dynamic>> getAvailability(Map<String, dynamic> data) => guardApiCall(() async {
    final response = await _dio.post('/Bookings/availability', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  });

  @override
  Future<Booking> createBooking(
    Map<String, dynamic> data, {
    required String idempotencyKey,
  }) =>
  guardApiCall(() async {
    final response = await _dio.post(
      '/Bookings',
      data: data,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return Booking.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data) => guardApiCall(() async {
    final response = await _dio.post('/Bookings/quote', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  });

  @override
  Future<void> uploadPhotos(String bookingId, List<MultipartFile> photos) => guardApiCall(() async {
    if (photos.isEmpty) return;
    await _dio.post(
      '/Bookings/$bookingId/photos',
      data: FormData.fromMap({'photos': photos}),
    );
  });

  @override
  Future<void> cancelBookingByClient(String bookingId) => guardApiCall(() async {
    await _dio.post('/Bookings/$bookingId/cancel');
  });

  @override
  Future<void> workerCancelBooking(String bookingId, String reasonCode, {String? freeText}) =>
    guardApiCall(() async {
      await _dio.post(
        '/Bookings/$bookingId/worker-cancel',
        data: {
          'reasonCode': reasonCode,
          if (freeText != null) 'freeText': freeText,
        },
      );
    });

  @override
  Future<void> clientCancelBooking(String bookingId, String reasonCode, {String? freeText}) =>
    guardApiCall(() async {
      await _dio.post(
        '/Bookings/$bookingId/client-cancel',
        data: {
          'reasonCode': reasonCode,
          if (freeText != null) 'freeText': freeText,
        },
      );
    });

  @override
  Future<void> reportBooking(String bookingId, String reasonCode, String freeText) => guardApiCall(() async {
        await _dio.post(
          '/Bookings/$bookingId/report',
          data: {'reasonCode': reasonCode, 'freeText': freeText},
        );
      });

  @override
  Future<Booking> proposeReschedule(String bookingId, DateTime newStartTime, {String? message}) =>
  guardApiCall(() async {
    final response = await _dio.post(
      '/Bookings/$bookingId/reschedule',
      data: {
        'newStartTime': newStartTime.toUtc().toIso8601String(),
        if (message != null) 'message': message,
      },
    );
    return Booking.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<Booking> respondReschedule(String bookingId, String requestId, String action) =>
  guardApiCall(() async {
    final response = await _dio.patch(
      '/Bookings/$bookingId/reschedule/$requestId',
      data: {'action': action},
    );
    return Booking.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> switchToCash(String bookingId) => guardApiCall(() async {
    await _dio.post('/Bookings/$bookingId/switch-to-cash');
  });

  @override
  Future<void> acceptBooking(String bookingId) => guardApiCall(() async {
    await _dio.patch('/Bookings/$bookingId/accept');
  });

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) =>
    guardApiCall(() async {
      await _dio.patch(
        '/Bookings/$bookingId/status',
        data: {
          'newStatus': newStatus,
          if (reason != null) 'reason': reason,
        },
      );
    });

  @override
  Future<void> updateDuration(String bookingId, double hours) => guardApiCall(() async {
    await _dio.patch(
      '/Bookings/$bookingId/duration',
      data: {'durationHours': hours},
    );
  });
}

@Riverpod(keepAlive: true)
BookingRepository bookingRepository(Ref ref) {
  return ApiBookingRepository(ref.read(dioProvider));
}

@riverpod
Future<List<Booking>> bookings(Ref ref) async {
  return ref.read(bookingRepositoryProvider).getClientBookings();
}

@riverpod
Future<List<Booking>> workerBookings(Ref ref) async {
  return ref.read(bookingRepositoryProvider).getWorkerBookings();
}

@riverpod
Future<List<Booking>> availableBookings(Ref ref) async {
  return ref.read(bookingRepositoryProvider).getAvailableBookings();
}
