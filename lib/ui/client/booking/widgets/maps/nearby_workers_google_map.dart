import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/constants/user_role.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/booking.dart';
import '../../../../../data/repositories/dispatch_repository.dart';
import '../../../../../data/services/directions_service.dart';
import '../../../../../data/services/dispatch_hub_service.dart';
import '../../../../../data/services/worker_location_sender.dart';
import 'animated_map_camera.dart';
import 'pulsing_location_marker.dart';

const _osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgentPackageName = 'com.example.cleanai';
const _workerPositionRefreshInterval = Duration(seconds: 10);

class NearbyWorkersGoogleMap extends ConsumerStatefulWidget {
  const NearbyWorkersGoogleMap({
    super.key,
    required this.booking,
    this.viewerRole = UserRole.client,
  });

  final Booking booking;
  final UserRole viewerRole;

  @override
  ConsumerState<NearbyWorkersGoogleMap> createState() => _NearbyWorkersGoogleMapState();
}

class _NearbyWorkersGoogleMapState extends ConsumerState<NearbyWorkersGoogleMap>
    with SingleTickerProviderStateMixin {
  List<({double lat, double lng})> _nearbyWorkers = [];
  LatLng? _myPosition;
  DirectionsRoute? _route;
  late final AnimatedMapCamera _camera;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _camera = AnimatedMapCamera(vsync: this);
    _refresh();
    ref.read(dispatchHubClientProvider).onNearbyWorkersUpdated((locations) {
      if (!mounted) return;
      setState(() => _nearbyWorkers = locations);
      _fitCameraToVisibleMarkers();
    });
    if (widget.viewerRole == UserRole.worker) {
      _loadWorkerRoute();
      _positionTimer = Timer.periodic(_workerPositionRefreshInterval, (_) => _loadWorkerRoute());
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _camera.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final locations = await ref.read(dispatchRepositoryProvider).getNearbyWorkerLocations(widget.booking.id);
    if (!mounted) return;
    setState(() => _nearbyWorkers = locations);
    _fitCameraToVisibleMarkers();
  }

  Future<void> _loadWorkerRoute() async {
    if (!_hasBookingLocation) return;
    final position = await ref.read(deviceLocationSourceProvider).getCurrentPosition();
    if (position == null || !mounted) return;
    setState(() => _myPosition = LatLng(position.latitude, position.longitude));
    _fitCameraToVisibleMarkers();

    final route = await ref.read(directionsServiceProvider).fetchRoute(
          originLat: position.latitude,
          originLng: position.longitude,
          destLat: widget.booking.latitude!,
          destLng: widget.booking.longitude!,
        );
    if (route == null || !mounted) return;
    setState(() => _route = route);
  }

  void _fitCameraToVisibleMarkers() {
    if (!_hasBookingLocation) return;
    final points = [
      LatLng(widget.booking.latitude!, widget.booking.longitude!),
      if (_myPosition != null) _myPosition!,
      for (final worker in _nearbyWorkers) LatLng(worker.lat, worker.lng),
    ];
    unawaited(_camera.animateFit(points));
  }

  double? get _straightLineDistanceMeters {
    if (_myPosition == null || !_hasBookingLocation) return null;
    return Geolocator.distanceBetween(
      _myPosition!.latitude,
      _myPosition!.longitude,
      widget.booking.latitude!,
      widget.booking.longitude!,
    );
  }

  bool get _hasBookingLocation =>
      widget.booking.latitude != null &&
      widget.booking.longitude != null &&
      widget.booking.latitude!.isFinite &&
      widget.booking.longitude!.isFinite;

  @override
  Widget build(BuildContext context) {
    if (!_hasBookingLocation) {
      return ColoredBox(
        color: kMapPlaceholderBg,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    'Không có tọa độ địa chỉ để hiển thị bản đồ. Hệ thống vẫn đang tìm nhân viên cho bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final serviceLocation = LatLng(widget.booking.latitude!, widget.booking.longitude!);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            key: const ValueKey('nearby-workers-map'),
            mapController: _camera.mapController,
            options: MapOptions(
              initialCenter: serviceLocation,
              initialZoom: 14,
              onMapReady: () {
                _camera.onMapReady();
                _fitCameraToVisibleMarkers();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _osmTileUrlTemplate,
                userAgentPackageName: _osmUserAgentPackageName,
              ),
              if (_route != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!.points,
                      color: theme.colorScheme.primary,
                      strokeWidth: 4,
                    ),
                  ],
                )
              else if (_myPosition != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_myPosition!, serviceLocation],
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    key: const ValueKey('service-location'),
                    point: serviceLocation,
                    width: 80,
                    height: 80,
                    child: const PulsingLocationMarker(icon: Icons.location_pin, color: kPrimary),
                  ),
                  if (_myPosition != null)
                    Marker(
                      key: const ValueKey('worker-self'),
                      point: _myPosition!,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.person_pin_circle, color: kSecondary, size: 36),
                    ),
                  for (var i = 0; i < _nearbyWorkers.length; i++)
                    Marker(
                      key: ValueKey('nearby-worker-$i'),
                      point: LatLng(_nearbyWorkers[i].lat, _nearbyWorkers[i].lng),
                      width: 16,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kTertiary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_route != null || _straightLineDistanceMeters != null)
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
              ),
              child: Text(
                _route != null
                    ? 'Cách ${_route!.distanceText} · ${_route!.durationText}'
                    : 'Cách ${formatDistance(_straightLineDistanceMeters!)} · '
                        '${formatDuration(estimatedTravelDuration(_straightLineDistanceMeters!))}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
