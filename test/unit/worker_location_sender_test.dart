import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/repositories/worker_repository.dart';
import 'package:cleanai/data/services/worker_location_sender.dart';
import 'package:flutter_test/flutter_test.dart';

// F-T5: while a worker is OnTheWay, their device pushes its position every ~10s so the client's
// live map has something real to show. This is the pure timer/dispatch logic, decoupled from the
// actual geolocator plugin (which can't run in a unit test) via DeviceLocationSource.
void main() {
  test('[UT-FE-WORKERLOC-01] start() sends an immediate position update, then again on each tick', () async {
    final locationSource = _FakeLocationSource(position: (lat: 10.77, lng: 106.70));
    final workerRepo = _FakeWorkerRepository();
    final sender = WorkerLocationSender(locationSource, workerRepo);

    sender.start(interval: const Duration(milliseconds: 20));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(workerRepo.updates, [(10.77, 106.70)]);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(workerRepo.updates.length, greaterThanOrEqualTo(2));

    sender.stop();
  });

  test('[UT-FE-WORKERLOC-02] stop() cancels the timer — no further updates after stopping', () async {
    final locationSource = _FakeLocationSource(position: (lat: 10.77, lng: 106.70));
    final workerRepo = _FakeWorkerRepository();
    final sender = WorkerLocationSender(locationSource, workerRepo);

    sender.start(interval: const Duration(milliseconds: 15));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    sender.stop();
    final countAtStop = workerRepo.updates.length;

    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(workerRepo.updates.length, countAtStop);
  });

  test('[UT-FE-WORKERLOC-03] a null position (permission denied / GPS off) is skipped, not sent as 0,0', () async {
    final locationSource = _FakeLocationSource(position: null);
    final workerRepo = _FakeWorkerRepository();
    final sender = WorkerLocationSender(locationSource, workerRepo);

    sender.start(interval: const Duration(milliseconds: 15));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    sender.stop();

    expect(workerRepo.updates, isEmpty);
  });
}

class _FakeLocationSource implements DeviceLocationSource {
  _FakeLocationSource({required this.position});
  final ({double lat, double lng})? position;

  @override
  Future<({double latitude, double longitude})?> getCurrentPosition() async {
    final p = position;
    if (p == null) return null;
    return (latitude: p.lat, longitude: p.lng);
  }
}

class _FakeWorkerRepository implements WorkerRepository {
  final List<(double, double)> updates = [];

  @override
  Future<void> updateLocation(double lat, double lng) async => updates.add((lat, lng));

  @override
  Future<Worker?> getMyWorkerProfile() async => null;

  @override
  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  }) async {}

  @override
  Future<void> updateOnlineStatus(bool online) async {}
}
