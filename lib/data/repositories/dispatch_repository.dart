import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';

abstract class DispatchRepository {
  Future<void> hideBooking(String bookingId);
  Future<void> retryBroadcast(String bookingId);
}

class ApiDispatchRepository implements DispatchRepository {
  ApiDispatchRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> hideBooking(String bookingId) => _post(
        '/Bookings/$bookingId/hide',
        'Không thể ẩn công việc.',
      );

  @override
  Future<void> retryBroadcast(String bookingId) => _post(
        '/Bookings/$bookingId/retry',
        'Không thể tìm lại nhân viên.',
      );

  Future<void> _post(String path, String fallback) async {
    try {
      await _dio.post(path);
    } on DioException catch (error) {
      throw Exception(backendMessageFromDioException(error, fallback: fallback));
    }
  }
}

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return ApiDispatchRepository(ref.read(dioProvider));
});
