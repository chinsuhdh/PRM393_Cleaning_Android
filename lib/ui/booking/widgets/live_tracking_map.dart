import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/user_role.dart';
import '../../../data/models/booking.dart';
import '../../../data/services/worker_location_sender.dart';
import '../booking_detail_screen.dart' show bookingDetailProvider;

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

  const LiveTrackingMap({
    super.key,
    required this.bookingId,
    required this.booking,
    required this.viewerRole,
  });

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap> {
  static const _pollInterval = Duration(seconds: 10);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() => ref.invalidate(bookingDetailProvider(widget.bookingId));

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
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
                      : GoogleMap(
                          key: const ValueKey('live-tracking-google-map'),
                          initialCameraPosition: CameraPosition(
                            target: LatLng(booking.latitude!, booking.longitude!),
                            zoom: 14,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('destination'),
                              position: LatLng(booking.latitude!, booking.longitude!),
                              infoWindow: const InfoWindow(title: 'Địa chỉ'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            ),
                            Marker(
                              markerId: const MarkerId('worker'),
                              position: LatLng(workerLat, workerLng),
                              infoWindow: const InfoWindow(title: 'Nhân viên'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                            ),
                          },
                          myLocationButtonEnabled: false,
                          myLocationEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: false,
                          zoomControlsEnabled: false,
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
                    'Cách ${formatDistance(distance)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
