import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/booking.dart';
import '../../../data/models/worker.dart';

class NearbyWorkersGoogleMap extends StatelessWidget {
  const NearbyWorkersGoogleMap({
    super.key,
    required this.booking,
    required this.workers,
  });

  final Booking booking;
  final List<Worker> workers;

  bool get _hasBookingLocation =>
      booking.latitude != null &&
      booking.longitude != null &&
      booking.latitude!.isFinite &&
      booking.longitude!.isFinite;

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

    final serviceLocation = LatLng(booking.latitude!, booking.longitude!);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('service-location'),
        position: serviceLocation,
        infoWindow: const InfoWindow(title: 'Địa chỉ của bạn'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndexInt: 2,
      ),
      for (final worker in workers)
        if (worker.latitude != null &&
            worker.longitude != null &&
            worker.latitude!.isFinite &&
            worker.longitude!.isFinite)
          Marker(
            markerId: MarkerId('worker-${worker.id}'),
            position: LatLng(worker.latitude!, worker.longitude!),
            infoWindow: InfoWindow(
              title: worker.name,
              snippet: worker.distance.isEmpty ? 'Nhân viên ở gần' : worker.distance,
            ),
          ),
    };

    return GoogleMap(
      key: const ValueKey('nearby-workers-google-map'),
      initialCameraPosition: CameraPosition(target: serviceLocation, zoom: 14),
      markers: markers,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
