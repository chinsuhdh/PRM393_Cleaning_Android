import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/dispatch_repository.dart';
import 'package:cleanai/ui/booking/widgets/nearby_workers_google_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const booking = Booking(
    id: 'b1', serviceName: 'x', date: '', time: '', price: 1,
    status: 'AwaitingWorker', bookingType: 'Immediate',
    latitude: 10.77, longitude: 106.70,
  );

  testWidgets(
    '[UT-FE-NEARBYMAP-01] Renders anonymous markers for nearby workers returned by the repository',
    (tester) async {
      final repository = _FakeDispatchRepository(locations: [
        (lat: 10.771, lng: 106.701),
        (lat: 10.772, lng: 106.702),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [dispatchRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: Scaffold(body: NearbyWorkersGoogleMap(booking: booking))),
      ));
      await tester.pump();
      await tester.pump();

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      // 1 service-location pin + 2 nearby-worker dots.
      expect(markerLayer.markers, hasLength(3));
    },
  );

  testWidgets(
    '[UT-FE-NEARBYMAP-02] Nearby-worker markers are plain, non-interactive dots — anonymous, unlike '
    'the service-location pin, which is rendered as a distinguishable pin icon. flutter_map markers '
    'have no InfoWindow/tap-events concept at all (unlike GoogleMap), so "anonymous" here means: no '
    'gesture wrapper, no label, just a plain circle widget.',
    (tester) async {
      final repository = _FakeDispatchRepository(locations: [(lat: 10.771, lng: 106.701)]);
      await tester.pumpWidget(ProviderScope(
        overrides: [dispatchRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: Scaffold(body: NearbyWorkersGoogleMap(booking: booking))),
      ));
      await tester.pump();
      await tester.pump();

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      final workerMarker = markerLayer.markers.firstWhere((m) => m.key == const ValueKey('nearby-worker-0'));
      final serviceMarker = markerLayer.markers.firstWhere((m) => m.key == const ValueKey('service-location'));

      // A worker marker's child being exactly a Container (not a GestureDetector/InkWell wrapping
      // one, and not an Icon/label) proves it's a plain, non-interactive, unlabeled dot.
      expect(workerMarker.child, isA<Container>());
      expect(serviceMarker.child, isA<Icon>());
    },
  );

  testWidgets(
    '[UT-FE-NEARBYMAP-03] Polls the repository on mount and again on the next tick',
    (tester) async {
      final repository = _FakeDispatchRepository(locations: const []);
      await tester.pumpWidget(ProviderScope(
        overrides: [dispatchRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: Scaffold(body: NearbyWorkersGoogleMap(booking: booking))),
      ));
      await tester.pump();
      await tester.pump();
      expect(repository.callCount, 1);

      await tester.pump(const Duration(seconds: 6));
      expect(repository.callCount, 2);
    },
  );

  testWidgets(
    '[UT-FE-NEARBYMAP-04] Stops polling once the widget is disposed',
    (tester) async {
      final repository = _FakeDispatchRepository(locations: const []);
      await tester.pumpWidget(ProviderScope(
        overrides: [dispatchRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: Scaffold(body: NearbyWorkersGoogleMap(booking: booking))),
      ));
      await tester.pump();
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));
      final countAtDispose = repository.callCount;
      await tester.pump(const Duration(seconds: 12));

      expect(repository.callCount, countAtDispose);
    },
  );
}

class _FakeDispatchRepository implements DispatchRepository {
  _FakeDispatchRepository({required List<({double lat, double lng})> locations}) : _locations = locations;
  final List<({double lat, double lng})> _locations;
  int callCount = 0;

  @override
  Future<void> hideBooking(String bookingId) async {}

  @override
  Future<void> retryBroadcast(String bookingId) async {}

  @override
  Future<List<({double lat, double lng})>> getNearbyWorkerLocations(String bookingId) async {
    callCount++;
    return _locations;
  }
}
