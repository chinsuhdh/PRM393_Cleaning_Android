import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../repositories/worker_repository.dart';

abstract class DeviceLocationSource {
  Future<({double latitude, double longitude})?> getCurrentPosition();
}

class GeolocatorLocationSource implements DeviceLocationSource {
  @override
  Future<({double latitude, double longitude})?> getCurrentPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
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

final workerLocationSenderProvider = Provider.autoDispose<void>((ref) {
  final sender = WorkerLocationSender(
    ref.watch(deviceLocationSourceProvider),
    ref.watch(workerRepositoryProvider),
  );
  sender.start();
  ref.onDispose(sender.stop);
});
