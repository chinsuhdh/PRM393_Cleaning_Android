import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/dispatch_repository.dart';
import '../../../data/services/directions_service.dart';
import '../../../data/services/dispatch_hub_service.dart';
import '../../../data/services/worker_location_sender.dart';
import 'animated_map_camera.dart';
import 'live_tracking_map.dart' show formatDistance, estimatedTravelDuration;
import 'pulsing_location_marker.dart';

const _osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgentPackageName = 'com.example.cleanai';

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

  @override
  void initState() {
    super.initState();
    // Eagerly created here (not as a lazy `late final` field initializer) — the FlutterMap branch
    // that reads `_camera` in build() may never run before dispose() if `_hasBookingLocation` is
    // false, which would otherwise defer creation (and its vsync/Ticker lookup) until dispose(),
    // when the element is no longer mounted.
    _camera = AnimatedMapCamera(vsync: this);
    _refresh();
    // E.6/E.9: the booking-detail screen already connects and joins `booking:{id}` — this only
    // needs to listen for the ~60s position pushes on that shared connection.
    ref.read(dispatchHubClientProvider).onNearbyWorkersUpdated((locations) {
      if (!mounted) return;
      setState(() => _nearbyWorkers = locations);
      _fitCameraToVisibleMarkers();
    });
    if (widget.viewerRole == UserRole.worker) _loadWorkerRoute();
  }

  @override
  void dispose() {
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

  /// Keeps the job location, the worker's own position (if known), and every nearby-worker dot
  /// comfortably in frame — like a navigation app, instead of a fixed zoom level.
  void _fitCameraToVisibleMarkers() {
    if (!_hasBookingLocation) return;
    final points = [
      LatLng(widget.booking.latitude!, widget.booking.longitude!),
      if (_myPosition != null) _myPosition!,
      for (final worker in _nearbyWorkers) LatLng(worker.lat, worker.lng),
    ];
    unawaited(_camera.animateFit(points));
  }

  /// Straight-line fallback so the worker always sees a distance/line even when the OSRM route
  /// call hasn't resolved yet (or fails) — mirrors LiveTrackingMap's `_distanceMeters`.
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
                // Immediate straight-line preview between the worker and the job while the real
                // driving route is still loading (or unavailable) — replaced by the routed
                // polyline above as soon as it resolves.
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
