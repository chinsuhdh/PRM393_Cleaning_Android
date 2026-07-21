import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/typed_exceptions.dart';
import '../models/booking.dart';

export '../../core/network/typed_exceptions.dart' show WorkerSuspendedException;

abstract class BookingRepository {
  /// Fetches the list of bookings belonging to the currently authenticated client.
  Future<List<Booking>> getClientBookings();

  /// Fetches the list of bookings assigned to the currently authenticated worker.
  Future<List<Booking>> getWorkerBookings();

  /// Fetches the list of available bookings that the current worker can accept.
  Future<List<Booking>> getAvailableBookings();

  /// Retrieves detailed information for a specific booking by its ID.
  Future<Booking?> getBookingById(String bookingId);

  /// Checks the availability of workers based on the provided criteria.
  Future<Map<String, dynamic>> getAvailability(Map<String, dynamic> data);

  /// Retrieves a price quote for a potential booking based on the provided criteria.
  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data);

  /// Creates a new booking with the specified details.
  Future<Booking> createBooking(
    Map<String, dynamic> data, {
    required String idempotencyKey,
  });

  /// Accepts an available booking on behalf of the current worker.
  Future<void> acceptBooking(String bookingId);

  /// Updates the status of an existing booking.
  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason});

  /// Updates the estimated or actual duration of a booking.
  Future<void> updateDuration(String bookingId, double hours);

  /// Uploads completion photos for a specific booking.
  Future<void> uploadPhotos(String bookingId, List<MultipartFile> photos);

  /// Cancels an existing booking from the client side.
  Future<void> cancelBookingByClient(String bookingId);

  /// Cancels an assigned booking from the worker side, requiring a reason.
  Future<void> workerCancelBooking(String bookingId, String reasonCode, {String? freeText});

  /// Cancels a booking from the client side with a specific reason code.
  Future<void> clientCancelBooking(String bookingId, String reasonCode, {String? freeText});

  /// Submits a report or complaint regarding a specific booking.
  Future<void> reportBooking(String bookingId, String reasonCode, String freeText);

  /// Proposes a new start time for an existing booking.
  Future<Booking> proposeReschedule(String bookingId, DateTime newStartTime, {String? message});

  /// Responds to a proposed reschedule request (accept, reject, or withdraw).
  Future<Booking> respondReschedule(String bookingId, String requestId, String action);

  /// Switches the payment method of a booking to cash.
  Future<void> switchToCash(String bookingId);
}

class QuoteStaleException implements Exception {
  const QuoteStaleException();
}

class BookingNoLongerAvailableException implements Exception {
  const BookingNoLongerAvailableException();
}

class RescheduleAlreadyPendingException implements Exception {
  const RescheduleAlreadyPendingException();
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
      debugPrint('[BookingRepository] getClientBookings failed: $error');
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
      debugPrint('[BookingRepository] getWorkerBookings failed: $error');
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
      debugPrint('[BookingRepository] getAvailableBookings failed: $error');
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
    } catch (e) {
      debugPrint('[BookingRepository] getBookingById failed: $e');
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
      debugPrint('[BookingRepository] getAvailability failed: $error');
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
      debugPrint('[BookingRepository] createBooking failed: $error');
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
      debugPrint('[BookingRepository] getQuote failed: $error');
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
  Future<void> cancelBookingByClient(String bookingId) async {
    try {
      await _dio.post('/Bookings/$bookingId/cancel');
    } on DioException catch (error) {
      debugPrint('[BookingRepository] cancelBookingByClient failed: $error');
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể hủy đơn đặt dịch vụ.',
        ),
      );
    }
  }

  @override
  Future<void> workerCancelBooking(String bookingId, String reasonCode, {String? freeText}) async {
    try {
      await _dio.post(
        '/Bookings/$bookingId/worker-cancel',
        data: {
          'reasonCode': reasonCode,
          if (freeText != null) 'freeText': freeText,
        },
      );
    } on DioException catch (error) {
      debugPrint('[BookingRepository] workerCancelBooking failed: $error');
      if (backendErrorCodeFromDioException(error) == 'WORKER_SUSPENDED') {
        throw const WorkerSuspendedException();
      }
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể hủy nhận việc.',
        ),
      );
    }
  }

  @override
  Future<void> clientCancelBooking(String bookingId, String reasonCode, {String? freeText}) async {
    try {
      await _dio.post(
        '/Bookings/$bookingId/client-cancel',
        data: {
          'reasonCode': reasonCode,
          if (freeText != null) 'freeText': freeText,
        },
      );
    } on DioException catch (error) {
      debugPrint('[BookingRepository] clientCancelBooking failed: $error');
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể hủy đơn đặt dịch vụ.',
        ),
      );
    }
  }

  @override
  Future<void> reportBooking(String bookingId, String reasonCode, String freeText) async {
    try {
      await _dio.post(
        '/Bookings/$bookingId/report',
        data: {'reasonCode': reasonCode, 'freeText': freeText},
      );
    } on DioException catch (error) {
      debugPrint('[BookingRepository] reportBooking failed: $error');
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể gửi báo cáo.',
        ),
      );
    }
  }

  @override
  Future<Booking> proposeReschedule(String bookingId, DateTime newStartTime, {String? message}) async {
    try {
      final response = await _dio.post(
        '/Bookings/$bookingId/reschedule',
        data: {
          'newStartTime': newStartTime.toUtc().toIso8601String(),
          if (message != null) 'message': message,
        },
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      debugPrint('[BookingRepository] proposeReschedule failed: $error');
      if (backendErrorCodeFromDioException(error) == 'RESCHEDULE_ALREADY_PENDING') {
        throw const RescheduleAlreadyPendingException();
      }
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể đề nghị dời lịch.',
        ),
      );
    }
  }

  @override
  Future<Booking> respondReschedule(String bookingId, String requestId, String action) async {
    try {
      final response = await _dio.patch(
        '/Bookings/$bookingId/reschedule/$requestId',
        data: {'action': action},
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      debugPrint('[BookingRepository] respondReschedule failed: $error');
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể phản hồi yêu cầu dời lịch.',
        ),
      );
    }
  }

  @override
  Future<void> switchToCash(String bookingId) async {
    try {
      await _dio.post('/Bookings/$bookingId/switch-to-cash');
    } on DioException catch (error) {
      debugPrint('[BookingRepository] switchToCash failed: $error');
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể chuyển sang thanh toán tiền mặt.',
        ),
      );
    }
  }

  @override
  Future<void> acceptBooking(String bookingId) async {
    try {
      await _dio.patch('/Bookings/$bookingId/accept');
    } on DioException catch (error) {
      debugPrint('[BookingRepository] acceptBooking failed: $error');
      if (backendErrorCodeFromDioException(error) == 'BOOKING_ACCEPT_FAILED') {
        throw const BookingNoLongerAvailableException();
      }
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Lỗi khi nhận đơn.',
        ),
      );
    }
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {
    try {
      await _dio.patch(
        '/Bookings/$bookingId/status',
        data: {
          'newStatus': newStatus,
          if (reason != null) 'reason': reason,
        },
      );
    } on DioException catch (error) {
      debugPrint('[BookingRepository] updateBookingStatus failed: $error');
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Lỗi khi cập nhật trạng thái.',
        ),
      );
    }
  }

  @override
  Future<void> updateDuration(String bookingId, double hours) async {
    try {
      await _dio.patch(
        '/Bookings/$bookingId/duration',
        data: {'durationHours': hours},
      );
    } on DioException catch (error) {
      debugPrint('[BookingRepository] updateDuration failed: $error');
      throw Exception(
        backendMessageFromDioException(
          error,
          fallback: 'Không thể cập nhật thời lượng công việc.',
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
