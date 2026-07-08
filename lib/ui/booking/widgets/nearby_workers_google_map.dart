import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/dispatch_repository.dart';

const _osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgentPackageName = 'com.example.cleanai';

/// Map shown while broadcasting a booking: the job address, plus anonymous dots for nearby online,
/// non-busy workers (no name/rating/tap target — dispatch is broadcast first-accept-wins, so
/// candidate *identity* is still never exposed to the client, only their rough presence nearby).
class NearbyWorkersGoogleMap extends ConsumerStatefulWidget {
  const NearbyWorkersGoogleMap({
    super.key,
    required this.booking,
  });

  final Booking booking;

  @override
  ConsumerState<NearbyWorkersGoogleMap> createState() => _NearbyWorkersGoogleMapState();
}

class _NearbyWorkersGoogleMapState extends ConsumerState<NearbyWorkersGoogleMap> {
  static const _pollInterval = Duration(seconds: 6);
  Timer? _timer;
  List<({double lat, double lng})> _nearbyWorkers = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final locations = await ref.read(dispatchRepositoryProvider).getNearbyWorkerLocations(widget.booking.id);
    if (mounted) setState(() => _nearbyWorkers = locations);
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
        color: const Color(0xFFEAF0F4),
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

    return FlutterMap(
      key: const ValueKey('nearby-workers-map'),
      options: MapOptions(
        initialCenter: serviceLocation,
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: _osmTileUrlTemplate,
          userAgentPackageName: _osmUserAgentPackageName,
        ),
        MarkerLayer(
          markers: [
            Marker(
              key: const ValueKey('service-location'),
              point: serviceLocation,
              width: 40,
              height: 40,
              child: const Icon(Icons.location_pin, color: kPrimary, size: 40),
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
    );
  }
}
