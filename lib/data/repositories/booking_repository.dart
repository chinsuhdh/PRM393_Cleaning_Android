import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/booking_enums.dart';
import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';
import '../models/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> getClientBookings();
  Future<List<Booking>> getWorkerBookings();
  Future<List<Booking>> getAvailableBookings();
  Future<Booking?> getBookingById(String bookingId);
  Future<Map<String, dynamic>> getAvailability(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data);
  Future<Booking> createBooking(
    Map<String, dynamic> data, {
    required String idempotencyKey,
  });
  Future<void> cancelBooking(String bookingId);
  Future<void> acceptBooking(String bookingId);
  Future<void> updateBookingStatus(String bookingId, String newStatus);
  Future<void> uploadPhotos(String bookingId, List<MultipartFile> photos);
}

class QuoteStaleException implements Exception {
  const QuoteStaleException();
}

class ApiBookingRepository implements BookingRepository {
  ApiBookingRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Booking>> getClientBookings() async {
    try {
      final response = await _dio.get('/Bookings/client');
      final raw = response.data;
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((json) => Booking.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (error) {
      throw Exception(backendMessageFromDioException(error, fallback: 'Không thể tải lịch đặt.'));
    }
  }

  @override
  Future<List<Booking>> getWorkerBookings() async {
    try {
      final response = await _dio.get('/Bookings/worker');
      final raw = response.data;
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((json) => Booking.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (error) {
      throw Exception(backendMessageFromDioException(error, fallback: 'Không thể tải công việc.'));
    }
  }

  @override
  Future<List<Booking>> getAvailableBookings() async {
    try {
      final response = await _dio.get('/Bookings/available');
      final raw = response.data;
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((json) => Booking.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (error) {
      throw Exception(backendMessageFromDioException(error, fallback: 'Không thể tải công việc khả dụng.'));
    }
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await _dio.get('/Bookings/$bookingId');
      if (response.data is Map<String, dynamic>) {
        return Booking.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getAvailability(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/Bookings/availability', data: data);
      final result = Map<String, dynamic>.from(response.data as Map);
      final rawEmptyMessage = result['emptyMessage'] ?? result['message'];
      final emptyMessage = backendMessageFromResponse(
        rawEmptyMessage,
        fallback: 'Không có nhân viên phù hợp trong thời gian đã chọn.',
      );

      if (emptyMessage.isNotEmpty) {
        result['emptyMessage'] = emptyMessage;
      }

      return result;
    } on DioException catch (error) {
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể kiểm tra thời gian đặt dịch vụ.',
        ),
      );
    }
  }

  @override
  Future<Booking> createBooking(
    Map<String, dynamic> data, {
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post(
        '/Bookings',
        data: data,
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (backendErrorCodeFromDioException(error) == 'QUOTE_STALE') {
        throw const QuoteStaleException();
      }
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể tạo đơn đặt dịch vụ.',
        ),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/Bookings/quote', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      throw Exception(backendMessageFromDioException(error, fallback: 'Không thể lấy báo giá.'));
    }
  }

  @override
  Future<void> uploadPhotos(String bookingId, List<MultipartFile> photos) async {
    if (photos.isEmpty) return;
    await _dio.post(
      '/Bookings/$bookingId/photos',
      data: FormData.fromMap({'photos': photos}),
    );
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _dio.patch(
        '/Bookings/$bookingId/status',
        data: {'newStatus': BookingStatusName.cancelled},
      );
    } on DioException catch (error) {
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể hủy đơn đặt dịch vụ.',
        ),
      );
    }
  }

  @override
  Future<void> acceptBooking(String bookingId) async {
    try {
      await _dio.patch('/Bookings/$bookingId/accept');
    } on DioException catch (error) {
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Lỗi khi nhận đơn.',
        ),
      );
    }
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _dio.patch(
        '/Bookings/$bookingId/status',
        data: {'newStatus': newStatus},
      );
    } on DioException catch (error) {
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Lỗi khi cập nhật trạng thái.',
        ),
      );
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return ApiBookingRepository(ref.read(dioProvider));
});

final bookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  return ref.read(bookingRepositoryProvider).getClientBookings();
});

final workerBookingsProvider = FutureProvider.autoDispose<List<Booking>>((
  ref,
) async {
  return ref.read(bookingRepositoryProvider).getWorkerBookings();
});

final availableBookingsProvider = FutureProvider.autoDispose<List<Booking>>((
  ref,
) async {
  return ref.read(bookingRepositoryProvider).getAvailableBookings();
});
