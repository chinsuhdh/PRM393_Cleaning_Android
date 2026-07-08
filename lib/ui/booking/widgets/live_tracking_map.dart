import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/services/directions_service.dart';
import '../../../data/services/worker_location_sender.dart';
import '../booking_detail_screen.dart' show bookingDetailProvider;

const _osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgentPackageName = 'com.example.cleanai';

/// Straight-line distance in meters between the worker's last-reported position and the job
/// address, or null if either side is missing. Pulled out as a pure function so it's testable
/// without needing a map widget or a device GPS fix.
double? onTheWayDistanceMeters(Booking booking) {
  final worker = booking.worker;
  if (worker?.latitude == null || worker?.longitude == null) return null;
  if (booking.latitude == null || booking.longitude == null) return null;
  return Geolocator.distanceBetween(
    worker!.latitude!,
    worker.longitude!,
    booking.latitude!,
    booking.longitude!,
  );
}

String formatDistance(double meters) =>
    meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';

/// OnTheWay live map, shown to both roles on Booking Detail: the worker's last-reported position
/// (from WorkerRepository.updateLocation, sent every ~10s via WorkerLocationSender while OnTheWay)
/// plus the job address, with a distance readout. Polls the booking on the same cadence so the
/// worker's marker actually moves as they get closer.
class LiveTrackingMap extends ConsumerStatefulWidget {
  final String bookingId;
  final Booking booking;
  final UserRole viewerRole;

  /// When true, fills whatever space its parent gives it (a full-screen `Positioned.fill` background)
  /// instead of the fixed-height rounded card used inline elsewhere.
  final bool fullBleed;

  /// Whether to fetch/draw the driving route + ETA from the worker's position to the job address.
  /// Only meaningful up through `OnTheWay` — once `InProgress` the worker has already arrived, so
  /// there's nothing left to route to (the map still shows, just without a line — see
  /// `BookingDetailScreen._fullBleedMapFor`).
  final bool showRoute;

  const LiveTrackingMap({
    super.key,
    required this.bookingId,
    required this.booking,
    required this.viewerRole,
    this.fullBleed = false,
    this.showRoute = false,
  });

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap> {
  static const _pollInterval = Duration(seconds: 10);
  Timer? _timer;
  DirectionsRoute? _route;
  double? _routedForWorkerLat;
  double? _routedForWorkerLng;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
    _maybeFetchRoute();
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeFetchRoute();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() => ref.invalidate(bookingDetailProvider(widget.bookingId));

  /// Re-fetches the route whenever the worker's reported position has actually moved (each
  /// `_refresh()` tick pulls a fresh `booking.worker` from the backend) — not on every rebuild, so a
  /// stationary worker doesn't spam the Directions API every 10s for the same unchanged route.
  void _maybeFetchRoute() {
    if (!widget.showRoute) return;
    final workerLat = widget.booking.worker?.latitude;
    final workerLng = widget.booking.worker?.longitude;
    final destLat = widget.booking.latitude;
    final destLng = widget.booking.longitude;
    if (workerLat == null || workerLng == null || destLat == null || destLng == null) return;
    if (workerLat == _routedForWorkerLat && workerLng == _routedForWorkerLng) return;
    _routedForWorkerLat = workerLat;
    _routedForWorkerLng = workerLng;

    ref.read(directionsServiceProvider).fetchRoute(
      originLat: workerLat,
      originLng: workerLng,
      destLat: destLat,
      destLng: destLng,
    ).then((route) {
      if (!mounted || route == null) return;
      setState(() => _route = route);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keeps this worker's own position updates flowing to the backend for as long as this map is
    // visible on their side — that's what the client's marker above is actually reading.
    if (widget.viewerRole == UserRole.worker) {
      ref.watch(workerLocationSenderProvider);
    }

    final theme = Theme.of(context);
    final booking = widget.booking;
    final distance = onTheWayDistanceMeters(booking);
    final hasDestination = booking.latitude != null && booking.longitude != null;
    final workerLat = booking.worker?.latitude;
    final workerLng = booking.worker?.longitude;
    final hasWorkerFix = workerLat != null && workerLng != null;

    final content = Stack(
          children: [
            Positioned.fill(
              child: !hasDestination
                  ? ColoredBox(
                      color: const Color(0xFFEAF0F4),
                      child: Center(
                        child: Text(
                          'Không có tọa độ để hiển thị bản đồ.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : !hasWorkerFix
                      ? ColoredBox(
                          color: const Color(0xFFEAF0F4),
                          child: Center(
                            child: Text(
                              widget.viewerRole == UserRole.worker
                                  ? 'Đang lấy vị trí của bạn…'
                                  : 'Đang chờ vị trí của nhân viên…',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        )
                      : FlutterMap(
                          key: const ValueKey('live-tracking-map'),
                          options: MapOptions(
                            initialCenter: LatLng(booking.latitude!, booking.longitude!),
                            initialZoom: 14,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: _osmTileUrlTemplate,
                              userAgentPackageName: _osmUserAgentPackageName,
                            ),
                            if (widget.showRoute && _route != null)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _route!.points,
                                    color: theme.colorScheme.primary,
                                    strokeWidth: 4,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  key: const ValueKey('destination'),
                                  point: LatLng(booking.latitude!, booking.longitude!),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_pin, color: kPrimary, size: 40),
                                ),
                                Marker(
                                  key: const ValueKey('worker'),
                                  point: LatLng(workerLat, workerLng),
                                  width: 36,
                                  height: 36,
                                  child: const Icon(Icons.local_shipping, color: kSecondary, size: 36),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
            if (distance != null)
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
                    // Prefers the Directions route's own driving distance/ETA over the straight-line
                    // fallback once it's back — the route call only ever fires when `showRoute` is set,
                    // so outside Accepted/OnTheWay this always reads as the plain straight-line text.
                    widget.showRoute && _route != null
                        ? 'Cách ${_route!.distanceText} · ${_route!.durationText}'
                        : 'Cách ${formatDistance(distance)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
          ],
        );

    if (widget.fullBleed) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(height: 220, child: content),
    );
  }
}
