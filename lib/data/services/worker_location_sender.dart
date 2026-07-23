import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../repositories/worker_repository.dart';

part 'worker_location_sender.g.dart';

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
    try {
      await _workerRepository.updateLocation(position.latitude, position.longitude);
    } catch (e) {
      // Best-effort background ping — a transient failure here shouldn't
      // surface to the user or crash the periodic timer.
      debugPrint('[WorkerLocationSender] updateLocation failed: $e');
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

@Riverpod(keepAlive: true)
DeviceLocationSource deviceLocationSource(Ref ref) => GeolocatorLocationSource();

@riverpod
void workerLocationSender(Ref ref) {
  final sender = WorkerLocationSender(
    ref.watch(deviceLocationSourceProvider),
    ref.watch(workerRepositoryProvider),
  );
  sender.start();
  ref.onDispose(sender.stop);
}
