import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

part 'directions_service.g.dart';

String formatDistance(double meters) =>
    meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';

const _assumedAverageSpeedKmh = 25.0;

Duration estimatedTravelDuration(double meters) =>
    Duration(minutes: (meters / 1000 / _assumedAverageSpeedKmh * 60).round());

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

class DirectionsService {
  DirectionsService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;

  Future<DirectionsRoute?> fetchRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
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

String formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes < 1) return '1 phút';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes phút';
  if (minutes == 0) return '$hours giờ';
  return '$hours giờ $minutes phút';
}

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

@Riverpod(keepAlive: true)
DirectionsService directionsService(Ref ref) => DirectionsService();
