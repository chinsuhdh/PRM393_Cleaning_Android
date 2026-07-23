import 'package:cleanai/core/constants/user_role.dart';
import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/dispatch_repository.dart';
import 'package:cleanai/data/services/dispatch_hub_service.dart';
import 'package:cleanai/data/services/directions_service.dart';
import 'package:cleanai/data/services/worker_location_sender.dart';
import 'package:cleanai/ui/client/booking/widgets/maps/nearby_workers_google_map.dart';
import 'package:cleanai/ui/client/booking/widgets/maps/pulsing_location_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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
      expect(serviceMarker.child, isA<PulsingLocationMarker>());
      expect((serviceMarker.child as PulsingLocationMarker).icon, Icons.location_pin);
    },
  );

  testWidgets(
    '[UT-FE-NEARBYMAP-03] Fetches the repository once on mount and does not keep polling — the map '
    'now relies on the ~60s SignalR push (E.9) instead of a REST timer',
    (tester) async {
      final repository = _FakeDispatchRepository(locations: const []);
      await tester.pumpWidget(ProviderScope(
        overrides: [dispatchRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(home: Scaffold(body: NearbyWorkersGoogleMap(booking: booking))),
      ));
      await tester.pump();
      await tester.pump();
      expect(repository.callCount, 1);

      await tester.pump(const Duration(seconds: 90));
      expect(repository.callCount, 1);
    },
  );

  testWidgets(
    '[UT-FE-NEARBYMAP-04] Renders updated markers when a nearbyWorkersUpdated push arrives over SignalR',
    (tester) async {
      final repository = _FakeDispatchRepository(locations: const []);
      final hubClient = _FakeDispatchHubClient();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dispatchRepositoryProvider.overrideWithValue(repository),
          dispatchHubClientProvider.overrideWithValue(hubClient),
        ],
        child: MaterialApp(home: Scaffold(body: NearbyWorkersGoogleMap(booking: booking))),
      ));
      await tester.pump();
      await tester.pump();

      hubClient.pushNearbyWorkers(const [(lat: 10.771, lng: 106.701), (lat: 10.772, lng: 106.702)]);
      await tester.pump();

      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      // 1 service-location pin + 2 pushed nearby-worker dots.
      expect(markerLayer.markers, hasLength(3));
    },
  );

  testWidgets(
    '[UT-FE-NEARBYMAP-05] A worker viewing the job gets the route from their own GPS position to the '
    'job address: polyline, own-position marker, and a distance/ETA chip — independent of the online '
    'toggle (this reads the device location directly, nothing backend-side gates it)',
    (tester) async {
      final repository = _FakeDispatchRepository(locations: const []);
      final locationSource = _FakeLocationSource(position: (latitude: 10.80, longitude: 106.65));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dispatchRepositoryProvider.overrideWithValue(repository),
          deviceLocationSourceProvider.overrideWithValue(locationSource),
          directionsServiceProvider.overrideWithValue(_FakeDirectionsService(
            route: const DirectionsRoute(
              points: [LatLng(10.80, 106.65), LatLng(10.77, 106.70)],
              distanceText: '6.2 km',
              durationText: '14 phút',
              duration: Duration(minutes: 14),
            ),
          )),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NearbyWorkersGoogleMap(booking: booking, viewerRole: UserRole.worker),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PolylineLayer), findsOneWidget);
      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.where((m) => m.key == const ValueKey('worker-self')), hasLength(1));
      expect(find.text('Cách 6.2 km · 14 phút'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-NEARBYMAP-05b] When the OSRM route call fails/never resolves, the chip still pairs a '
    'straight-line distance with an estimated time instead of showing distance alone',
    (tester) async {
      final repository = _FakeDispatchRepository(locations: const []);
      final locationSource = _FakeLocationSource(position: (latitude: 10.80, longitude: 106.65));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dispatchRepositoryProvider.overrideWithValue(repository),
          deviceLocationSourceProvider.overrideWithValue(locationSource),
          directionsServiceProvider.overrideWithValue(_FakeDirectionsService(route: null)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NearbyWorkersGoogleMap(booking: booking, viewerRole: UserRole.worker),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PolylineLayer), findsOneWidget);
      final chipFinder = find.textContaining('Cách');
      expect(chipFinder, findsOneWidget);
      final chipText = tester.widget<Text>(chipFinder).data!;
      expect(chipText, contains('km'));
      expect(chipText, contains('phút'));
    },
  );

  testWidgets(
    '[UT-FE-NEARBYMAP-06] A client never triggers the own-position/route lookup, and a worker with no '
    'GPS fix (permission denied) just gets the plain map — no polyline, no chip, no crash',
    (tester) async {
      final repository = _FakeDispatchRepository(locations: const []);
      final clientLocationSource = _FakeLocationSource(position: (latitude: 10.80, longitude: 106.65));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dispatchRepositoryProvider.overrideWithValue(repository),
          deviceLocationSourceProvider.overrideWithValue(clientLocationSource),
        ],
        child: MaterialApp(
          home: Scaffold(
            // Keyed so the second pump below builds a fresh State (initState) instead of Flutter
            // patching this one in place, which would skip the route lookup being tested.
            body: NearbyWorkersGoogleMap(
              key: const ValueKey('client-map'),
              booking: booking,
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
      expect(clientLocationSource.calls, 0);
      expect(find.byType(PolylineLayer), findsNothing);

      final deniedSource = _FakeLocationSource(position: null);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dispatchRepositoryProvider.overrideWithValue(repository),
          deviceLocationSourceProvider.overrideWithValue(deniedSource),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NearbyWorkersGoogleMap(
              key: const ValueKey('worker-map'),
              booking: booking,
              viewerRole: UserRole.worker,
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
      expect(deniedSource.calls, 1);
      expect(find.byType(PolylineLayer), findsNothing);
      final markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(markerLayer.markers.where((m) => m.key == const ValueKey('worker-self')), isEmpty);
    },
  );
}

class _FakeLocationSource implements DeviceLocationSource {
  _FakeLocationSource({required this.position});
  final ({double latitude, double longitude})? position;
  int calls = 0;

  @override
  Future<({double latitude, double longitude})?> getCurrentPosition() async {
    calls++;
    return position;
  }
}

class _FakeDirectionsService extends DirectionsService {
  _FakeDirectionsService({required this.route});
  final DirectionsRoute? route;

  @override
  Future<DirectionsRoute?> fetchRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async =>
      route;
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

class _FakeDispatchHubClient implements DispatchHubClient {
  void Function(List<({double lat, double lng})>)? _onNearbyWorkersUpdated;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  void onJobPosted(void Function() handler) {}

  @override
  void onJobTaken(void Function() handler) {}

  @override
  void onJobCancelled(void Function() handler) {}

  @override
  Future<void> subscribeToBooking(String bookingId) async {}

  @override
  void onBookingStatusChanged(void Function() handler) {}

  @override
  void onWorkerPosition(void Function(double lat, double lng) handler) {}

  @override
  void onNearbyWorkersUpdated(void Function(List<({double lat, double lng})> locations) handler) {
    _onNearbyWorkersUpdated = handler;
  }

  @override
  void onReconnected(void Function() handler) {}

  @override
  void onDisconnected(void Function() handler) {}

  @override
  void onReceiveMessage(void Function(Map<String, dynamic> msg) handler) {}

  void pushNearbyWorkers(List<({double lat, double lng})> locations) => _onNearbyWorkersUpdated?.call(locations);
}

