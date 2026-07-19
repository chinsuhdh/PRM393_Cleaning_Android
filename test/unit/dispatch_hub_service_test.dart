import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/data/services/dispatch_hub_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// E-T3/E-T4 (MASTER_FEATURE_SPEC.md § 4.3, § E.3): the backend already broadcasts jobPosted/jobTaken/
// jobCancelled over the DispatchHub — this is the client half that turns those pushes into a live
// Available Jobs feed instead of requiring a manual pull-to-refresh. Per § E.3's reconnect strategy,
// the feed is "eventually consistent with the REST list, never the source of truth" — so each event is
// just a signal to refetch `availableBookingsProvider`, not a payload to merge client-side.
void main() {
  group('DispatchLiveFeedController', () {
    test('[UT-FE-DISPATCHHUB-01] start() connects the hub client', () async {
      final client = _FakeDispatchHubClient();
      final controller = DispatchLiveFeedController(client, onFeedChanged: () {});

      await controller.start();

      expect(client.connected, isTrue);
    });

    test('[UT-FE-DISPATCHHUB-02] a jobPosted push triggers onFeedChanged', () async {
      final client = _FakeDispatchHubClient();
      var changed = 0;
      final controller = DispatchLiveFeedController(client, onFeedChanged: () => changed++);
      await controller.start();

      client.fireJobPosted();

      expect(changed, 1);
    });

    test('[UT-FE-DISPATCHHUB-03] a jobTaken push triggers onFeedChanged', () async {
      final client = _FakeDispatchHubClient();
      var changed = 0;
      final controller = DispatchLiveFeedController(client, onFeedChanged: () => changed++);
      await controller.start();

      client.fireJobTaken();

      expect(changed, 1);
    });

    test('[UT-FE-DISPATCHHUB-04] a jobCancelled push triggers onFeedChanged', () async {
      final client = _FakeDispatchHubClient();
      var changed = 0;
      final controller = DispatchLiveFeedController(client, onFeedChanged: () => changed++);
      await controller.start();

      client.fireJobCancelled();

      expect(changed, 1);
    });

    test('[UT-FE-DISPATCHHUB-05] stop() disconnects the hub client', () async {
      final client = _FakeDispatchHubClient();
      final controller = DispatchLiveFeedController(client, onFeedChanged: () {});
      await controller.start();

      await controller.stop();

      expect(client.disconnected, isTrue);
    });
  });

  test(
    '[UT-FE-DISPATCHHUB-06] watching dispatchLiveFeedProvider connects the hub and a jobPosted '
    'push causes availableBookingsProvider to refetch',
    () async {
      final client = _FakeDispatchHubClient();
      var fetchCount = 0;
      final container = ProviderContainer(overrides: [
        dispatchHubClientProvider.overrideWithValue(client),
        availableBookingsProvider.overrideWith((ref) async {
          fetchCount++;
          return <Booking>[];
        }),
        workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(dispatchLiveFeedProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(availableBookingsProvider.future);
      expect(fetchCount, 1);
      expect(client.connected, isTrue);

      client.fireJobPosted();
      await container.read(availableBookingsProvider.future);

      expect(fetchCount, 2);
    },
  );

  test(
    '[UT-FE-DISPATCHHUB-08] a jobCancelled push also refreshes workerBookingsProvider, so a worker\'s '
    'own My Jobs / active-job view drops a job that just got cancelled on them',
    () async {
      final client = _FakeDispatchHubClient();
      var workerFetchCount = 0;
      final container = ProviderContainer(overrides: [
        dispatchHubClientProvider.overrideWithValue(client),
        availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
        workerBookingsProvider.overrideWith((ref) async {
          workerFetchCount++;
          return <Booking>[];
        }),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(dispatchLiveFeedProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(workerBookingsProvider.future);
      expect(workerFetchCount, 1);

      client.fireJobCancelled();
      await container.read(workerBookingsProvider.future);

      expect(workerFetchCount, 2);
    },
  );

  test(
    '[UT-FE-DISPATCHHUB-07] disposing the container disconnects the hub client',
    () async {
      final client = _FakeDispatchHubClient();
      final container = ProviderContainer(overrides: [
        dispatchHubClientProvider.overrideWithValue(client),
        availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
      ]);

      final sub = container.listen(dispatchLiveFeedProvider, (_, __) {});
      await container.read(availableBookingsProvider.future);
      sub.close();
      container.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(client.disconnected, isTrue);
    },
  );
}

class _FakeDispatchHubClient implements DispatchHubClient {
  bool connected = false;
  bool disconnected = false;
  final List<String> subscribedBookingIds = [];
  void Function()? _onPosted;
  void Function()? _onTaken;
  void Function()? _onCancelled;
  void Function()? _onBookingStatusChanged;

  @override
  Future<void> connect() async => connected = true;

  @override
  Future<void> disconnect() async => disconnected = true;

  @override
  void onJobPosted(void Function() handler) => _onPosted = handler;

  @override
  void onJobTaken(void Function() handler) => _onTaken = handler;

  @override
  void onJobCancelled(void Function() handler) => _onCancelled = handler;

  @override
  Future<void> subscribeToBooking(String bookingId) async => subscribedBookingIds.add(bookingId);

  @override
  void onBookingStatusChanged(void Function() handler) => _onBookingStatusChanged = handler;

  @override
  void onWorkerPosition(void Function(double lat, double lng) handler) {}

  @override
  void onNearbyWorkersUpdated(void Function(List<({double lat, double lng})> locations) handler) {}

  @override
  void onReconnected(void Function() handler) {}

  @override
  void onReceiveMessage(void Function(Map<String, dynamic> msg) handler) {}

  void fireJobPosted() => _onPosted?.call();
  void fireJobTaken() => _onTaken?.call();
  void fireJobCancelled() => _onCancelled?.call();
  void fireBookingStatusChanged() => _onBookingStatusChanged?.call();
}

