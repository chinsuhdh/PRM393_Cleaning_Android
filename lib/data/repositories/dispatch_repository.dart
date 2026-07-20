import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';

List<({double lat, double lng})> parseNearbyWorkerLocations(Object? raw) {
  if (raw is! List) return [];
  return raw.whereType<Map>().map((json) {
    final lat = (json['latitude'] as num).toDouble();
    final lng = (json['longitude'] as num).toDouble();
    return (lat: lat, lng: lng);
  }).toList();
}

abstract class DispatchRepository {
  Future<void> hideBooking(String bookingId);
  Future<void> retryBroadcast(String bookingId);

  Future<List<({double lat, double lng})>> getNearbyWorkerLocations(String bookingId);
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

  @override
  Future<List<({double lat, double lng})>> getNearbyWorkerLocations(String bookingId) async {
    try {
      final response = await _dio.get('/Bookings/$bookingId/nearby-workers');
      return parseNearbyWorkerLocations(response.data);
    } catch (e) {
      debugPrint('[DispatchRepository] getNearbyWorkerLocations failed: $e');
      return [];
    }
  }

  Future<void> _post(String path, String fallback) async {
    try {
      await _dio.post(path);
    } on DioException catch (error) {
      debugPrint('[DispatchRepository] POST $path failed: $error');
      throw Exception(backendMessageFromDioException(error, fallback: fallback));
    }
  }
}

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return ApiDispatchRepository(ref.read(dioProvider));
});
