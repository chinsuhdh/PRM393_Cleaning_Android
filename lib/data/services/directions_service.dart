import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../ui/booking/widgets/live_tracking_map.dart' show formatDistance;

/// A driving route between two points, decoded from an OSRM route response: the polyline to draw
/// plus the distance/duration it quoted for that specific route.
class DirectionsRoute {
  final List<LatLng> points;
  final String distanceText;
  final String durationText;
  final Duration duration;

  const DirectionsRoute({
    required this.points,
    required this.distanceText,
    required this.durationText,
    required this.duration,
  });
}

/// Fetches a driving route from OSRM's free, key-less public routing server for the live-tracking
/// map's route line/ETA (`LiveTrackingMap`). Deliberately on its own bare `Dio` — this talks straight
/// to OSRM, not CleanAI's backend, so it has none of `DioClient`'s base URL, auth header, or response
/// envelope.
class DirectionsService {
  DirectionsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;

  /// Returns null on any failure (no network, no route found) — callers fall back to the
  /// straight-line distance they already have, same tolerance as the rest of this screen's
  /// best-effort location plumbing (`WorkerLocationSender`, `WorkerRepository.updateLocation`).
  Future<DirectionsRoute?> fetchRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      // OSRM's coordinate order is lng,lat (opposite of this method's own lat/lng-named params).
      final response = await _dio.get<Map<String, dynamic>>(
        'https://router.project-osrm.org/route/v1/driving/'
        '$originLng,$originLat;$destLng,$destLat',
        queryParameters: {
          'overview': 'full',
          'geometries': 'polyline',
        },
      );
      final data = response.data;
      if (data == null || data['code'] != 'Ok') return null;

      final routes = data['routes'] as List?;
      final route = routes?.isNotEmpty == true ? routes!.first as Map<String, dynamic> : null;
      final encoded = route?['geometry'] as String?;
      final distanceMeters = (route?['distance'] as num?)?.toDouble();
      final durationSeconds = (route?['duration'] as num?)?.toInt();
      if (encoded == null || distanceMeters == null || durationSeconds == null) return null;

      return DirectionsRoute(
        points: decodePolyline(encoded),
        distanceText: formatDistance(distanceMeters),
        durationText: formatDuration(Duration(seconds: durationSeconds)),
        duration: Duration(seconds: durationSeconds),
      );
    } catch (_) {
      return null;
    }
  }
}

/// OSRM gives only raw seconds, no localized string — a small Vietnamese-language formatter to match
/// the rest of this screen's copy.
String formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes < 1) return '1 phút';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes phút';
  if (minutes == 0) return '$hours giờ';
  return '$hours giờ $minutes phút';
}

/// Standard Google/OSRM encoded-polyline decoder (precision 5): turns the compact string OSRM
/// returns (`routes[0].geometry` with `geometries=polyline`) back into the list of lat/lng points
/// that make up the route.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  while (index < encoded.length) {
    var shift = 0;
    var result = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

final directionsServiceProvider = Provider<DirectionsService>((ref) => DirectionsService());
