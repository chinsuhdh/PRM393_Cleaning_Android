import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../repositories/worker_repository.dart';

/// Wraps the geolocator plugin behind an interface so WorkerLocationSender is testable without a
/// real device/emulator location fix.
abstract class DeviceLocationSource {
  Future<({double latitude, double longitude})?> getCurrentPosition();
}

class GeolocatorLocationSource implements DeviceLocationSource {
  @override
  Future<({double latitude, double longitude})?> getCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition();
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }
}

/// F-T5: while a worker is OnTheWay, pushes their position to the backend on an interval so the
/// client's live map has something real to track. Best-effort — a denied permission or GPS-off just
/// means no update gets sent this tick, same tolerance as WorkerRepository.updateLocation itself.
class WorkerLocationSender {
  WorkerLocationSender(this._locationSource, this._workerRepository);

  final DeviceLocationSource _locationSource;
  final WorkerRepository _workerRepository;
  Timer? _timer;

  void start({Duration interval = const Duration(seconds: 10)}) {
    _tick();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  Future<void> _tick() async {
    final position = await _locationSource.getCurrentPosition();
    if (position == null) return;
    await _workerRepository.updateLocation(position.latitude, position.longitude);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

final deviceLocationSourceProvider = Provider<DeviceLocationSource>((ref) => GeolocatorLocationSource());

/// Watch this from the worker's Booking Detail screen only while status is OnTheWay and the viewer
/// is the assigned worker; disposed (and the timer stopped) once nothing watches it anymore.
final workerLocationSenderProvider = Provider.autoDispose<void>((ref) {
  final sender = WorkerLocationSender(
    ref.watch(deviceLocationSourceProvider),
    ref.watch(workerRepositoryProvider),
  );
  sender.start();
  ref.onDispose(sender.stop);
});
