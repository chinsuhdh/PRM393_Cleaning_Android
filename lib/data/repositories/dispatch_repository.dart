import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';

part 'dispatch_repository.g.dart';

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
  Future<void> hideBooking(String bookingId) => guardApiCall(() async {
    await _dio.post('/Bookings/$bookingId/hide');
  });

  @override
  Future<void> retryBroadcast(String bookingId) => guardApiCall(() async {
    await _dio.post('/Bookings/$bookingId/retry');
  });

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
}

@Riverpod(keepAlive: true)
DispatchRepository dispatchRepository(Ref ref) {
  return ApiDispatchRepository(ref.read(dioProvider));
}
