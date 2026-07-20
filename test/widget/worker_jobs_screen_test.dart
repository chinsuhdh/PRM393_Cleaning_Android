import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/data/repositories/dispatch_repository.dart';
import 'package:cleanai/data/services/dispatch_hub_service.dart';
import 'package:cleanai/ui/worker/worker_jobs_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../support/pump_test_app.dart';

void main() {
  testWidgets(
    '[WT-FE-WORKERJOBS-05] A jobPosted push refreshes the Available tab live, no manual refresh needed',
    (tester) async {
      final client = _FakeDispatchHubClient();
      var jobs = <Booking>[];

      await pumpTestApp(
        tester,
        child: const WorkerJobsScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => jobs),
          dispatchHubClientProvider.overrideWithValue(client),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Có sẵn'));
      await tester.pumpAndSettle();

      expect(client.connected, isTrue);
      expect(find.text('Deep clean'), findsNothing);

      jobs = [
        const Booking(
          id: 'new-job', serviceName: 'Deep clean', date: '06/07/2026', time: '09:00',
          price: 200000, status: 'AwaitingWorker',
        ),
      ];
      client.fireJobPosted();
      await tester.pumpAndSettle();

      expect(find.text('Deep clean'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-WORKERJOBS-04] Worker Jobs opens the shared root-level Booking Detail (not a nested '
    'shell-branch route, which used to leave the WorkerShell bottom tabs showing under it) and Back '
    'returns safely',
    (tester) async {
      final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
      final router = GoRouter(
        navigatorKey: rootKey,
        initialLocation: '/worker/jobs',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, __, shell) => shell,
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(path: '/worker/jobs', builder: (_, __) => const WorkerJobsScreen()),
              ]),
            ],
          ),
          GoRoute(
            path: '/booking/:id',
            parentNavigatorKey: rootKey,
            builder: (context, state) => Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Text('DETAIL:${state.pathParameters['id']}'),
            ),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => const [
            Booking(
              id: 'b-open', serviceName: 'Deep clean', status: 'AwaitingWorker',
              date: '06/07/2026', time: '09:00', price: 200000,
            ),
          ]),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Có sẵn'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deep clean'));
      await tester.pumpAndSettle();

      expect(find.text('DETAIL:b-open'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Việc của tôi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '[WT-FE-WORKERJOBS-03] Swiping an available job hides it permanently through dispatch API',
    (tester) async {
      final dispatch = _FakeDispatchRepository();
      await pumpTestApp(
        tester,
        child: const WorkerJobsScreen(),
        overrides: [
          dispatchRepositoryProvider.overrideWithValue(dispatch),
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => const [
            Booking(
              id: 'b-hide', serviceName: 'Deep clean', status: 'AwaitingWorker',
              date: '06/07/2026', time: '09:00', price: 200000,
            ),
          ]),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Có sẵn'));
      await tester.pumpAndSettle();

      await tester.drag(find.text('Deep clean'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(dispatch.hiddenBookingIds, ['b-hide']);
      expect(find.text('Deep clean'), findsNothing);
    },
  );

  testWidgets(
    '[WT-FE-WORKERJOBS-06] An available job card shows both distance and estimated travel time '
    'when the backend provides them',
    (tester) async {
      await pumpTestApp(
        tester,
        child: const WorkerJobsScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => const [
            Booking(
              id: 'b-eta', serviceName: 'Deep clean', status: 'AwaitingWorker',
              date: '06/07/2026', time: '09:00', price: 200000,
              distanceKm: 6.2, estimatedMinutes: 15,
            ),
          ]),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
        ],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Có sẵn'));
      await tester.pumpAndSettle();

      expect(find.text('6.2 km'), findsOneWidget);
      expect(find.textContaining('phút'), findsWidgets);
    },
  );

  testWidgets(
    '[WT-FE-WORKERJOBS-01] Available tab lists dispatched jobs with an Accept button',
    (tester) async {
      await pumpTestApp(
        tester,
        child: const WorkerJobsScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => const [
            Booking(
              id: 'b1',
              serviceName: 'Dọn nhà',
              date: '06/07/2026',
              time: '09:00',
              price: 200000,
              status: 'AwaitingWorker',
            ),
          ]),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Có sẵn'));
      await tester.pumpAndSettle();

      expect(find.text('Dọn nhà'), findsOneWidget);
      expect(find.text('Nhận việc'), findsOneWidget);
      // Prices are VND everywhere in this app (D.2/HOME-001) — never a dollar sign.
      expect(find.textContaining('\$'), findsNothing);
      expect(find.textContaining('₫'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-WORKERJOBS-02] Available tab shows the empty message when there are no jobs',
    (tester) async {
      await pumpTestApp(
        tester,
        child: const WorkerJobsScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Có sẵn'));
      await tester.pumpAndSettle();

      expect(find.text('Không có đơn đặt lịch mới nào.'), findsOneWidget);
    },
  );
}

class _FakeDispatchHubClient implements DispatchHubClient {
  bool connected = false;
  void Function()? _onPosted;

  @override
  Future<void> connect() async => connected = true;

  @override
  Future<void> disconnect() async => connected = false;

  @override
  void onJobPosted(void Function() handler) => _onPosted = handler;

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
  void onNearbyWorkersUpdated(void Function(List<({double lat, double lng})> locations) handler) {}

  @override
  void onReconnected(void Function() handler) {}

  @override
  void onDisconnected(void Function() handler) {}

  @override
  void onReceiveMessage(void Function(Map<String, dynamic> msg) handler) {}

  void fireJobPosted() => _onPosted?.call();
}

class _FakeDispatchRepository implements DispatchRepository {
  final hiddenBookingIds = <String>[];

  @override
  Future<void> hideBooking(String bookingId) async => hiddenBookingIds.add(bookingId);

  @override
  Future<void> retryBroadcast(String bookingId) async {}

  @override
  Future<List<({double lat, double lng})>> getNearbyWorkerLocations(String bookingId) async => [];
}

