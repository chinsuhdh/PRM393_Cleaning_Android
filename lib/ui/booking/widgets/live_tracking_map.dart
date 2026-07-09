import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/services/directions_service.dart';
import '../../../data/services/dispatch_hub_service.dart';
import '../../../data/services/worker_location_sender.dart';

const _osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgentPackageName = 'com.example.cleanai';

double? _distanceMeters(double? lat, double? lng, double? destLat, double? destLng) {
  if (lat == null || lng == null || destLat == null || destLng == null) return null;
  return Geolocator.distanceBetween(lat, lng, destLat, destLng);
}

double? onTheWayDistanceMeters(Booking booking) => _distanceMeters(
      booking.worker?.latitude,
      booking.worker?.longitude,
      booking.latitude,
      booking.longitude,
    );

String formatDistance(double meters) =>
    meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';

class LiveTrackingMap extends ConsumerStatefulWidget {
  final String bookingId;
  final Booking booking;
  final UserRole viewerRole;

  final bool fullBleed;

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
  double? _liveWorkerLat;
  double? _liveWorkerLng;
  bool _receivedLivePosition = false;
  DirectionsRoute? _route;
  double? _routedForWorkerLat;
  double? _routedForWorkerLng;

  @override
  void initState() {
    super.initState();
    _liveWorkerLat = widget.booking.worker?.latitude;
    _liveWorkerLng = widget.booking.worker?.longitude;
    // F.2/F.3: the booking-detail screen already connects and joins `booking:{id}` — this only
    // needs to listen for the worker's live position pushes on that shared connection.
    ref.read(dispatchHubClientProvider).onWorkerPosition((lat, lng) {
      if (!mounted) return;
      setState(() {
        _liveWorkerLat = lat;
        _liveWorkerLng = lng;
        _receivedLivePosition = true;
      });
      _maybeFetchRoute();
    });
    _maybeFetchRoute();
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_receivedLivePosition) {
      _liveWorkerLat = widget.booking.worker?.latitude;
      _liveWorkerLng = widget.booking.worker?.longitude;
    }
    _maybeFetchRoute();
  }

  void _maybeFetchRoute() {
    if (!widget.showRoute) return;
    final workerLat = _liveWorkerLat;
    final workerLng = _liveWorkerLng;
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
    if (widget.viewerRole == UserRole.worker) {
      ref.watch(workerLocationSenderProvider);
    }

    final theme = Theme.of(context);
    final booking = widget.booking;
    final workerLat = _liveWorkerLat;
    final workerLng = _liveWorkerLng;
    final distance = _distanceMeters(workerLat, workerLng, booking.latitude, booking.longitude);
    final hasDestination = booking.latitude != null && booking.longitude != null;
    final hasWorkerFix = workerLat != null && workerLng != null;

    final content = Stack(
          children: [
            Positioned.fill(
              child: !hasDestination
                  ? ColoredBox(
                      color: kMapPlaceholderBg,
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
                          color: kMapPlaceholderBg,
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
