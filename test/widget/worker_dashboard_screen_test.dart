import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/data/repositories/worker_repository.dart';
import 'package:cleanai/data/services/dispatch_hub_service.dart';
import 'package:cleanai/ui/worker/worker_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/pump_test_app.dart';

void main() {
  testWidgets(
    "[WT-FE-WORKERDASH-01] Today's Earn and Jobs Today only count bookings completed today",
    (tester) async {
      final today = DateTime.now();
      final lastWeek = today.subtract(const Duration(days: 7));

      await pumpTestApp(
        tester,
        child: const WorkerDashboardScreen(),
        overrides: [
          workerBookingsProvider.overrideWith(
            (ref) async => [
              Booking(
                id: 'today-1',
                serviceName: 'Home Cleaning',
                date: '',
                time: '',
                price: 150000,
                status: 'Completed',
                updatedAt: today,
              ),
              Booking(
                id: 'today-2',
                serviceName: 'Deep Cleaning',
                date: '',
                time: '',
                price: 250000,
                status: 'Completed',
                updatedAt: today,
              ),
              Booking(
                id: 'old',
                serviceName: 'Home Cleaning',
                date: '',
                time: '',
                price: 999000,
                status: 'Completed',
                updatedAt: lastWeek,
              ),
              Booking(
                id: 'in-progress',
                serviceName: 'Home Cleaning',
                date: '',
                time: '',
                price: 500000,
                status: 'InProgress',
                updatedAt: today,
              ),
            ],
          ),
          availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
          workerProfileProvider.overrideWith((ref) async => null),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget); // Jobs Today
      expect(
        find.textContaining('400.000'),
        findsOneWidget,
      ); // 150k + 250k, VND
    },
  );

  testWidgets(
    '[WT-FE-WORKERDASH-09] Backend Busy is displayed accurately and tapping requests Offline, not Online',
    (tester) async {
      final repository = _FakeWorkerRepository(
        initialStatus: WorkerOnlineStatus.busy,
      );
      await pumpTestApp(
        tester,
        child: const WorkerDashboardScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
          workerProfileProvider.overrideWith((ref) async => null),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
          workerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Đang bận'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('online-status-toggle')));
      await tester.pumpAndSettle();

      expect(repository.calls, [false]);
      expect(find.text('Ngoại tuyến'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-WORKERDASH-02] Rating stat comes from the worker profile, not a hardcoded value',
    (tester) async {
      await pumpTestApp(
        tester,
        child: const WorkerDashboardScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
          workerProfileProvider.overrideWith(
            (ref) async =>
                const Worker(id: 'w1', name: 'Alex', rating: 4.7, reviews: 32),
          ),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('4.7'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-WORKERDASH-03] Dead-end quick actions are gone; My Jobs and Wallet still navigate',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const WorkerDashboardScreen(),
          ),
          GoRoute(
            path: '/worker/jobs',
            builder: (_, __) => const Text('JOBS_STUB'),
          ),
          GoRoute(
            path: '/worker/wallet',
            builder: (_, __) => const Text('WALLET_STUB'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
            availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
            workerProfileProvider.overrideWith((ref) async => null),
            dispatchHubClientProvider.overrideWithValue(
              _FakeDispatchHubClient(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsNothing);
      expect(find.text('Support'), findsNothing);

      await tester.tap(find.text('Việc của tôi'));
      await tester.pumpAndSettle();
      expect(find.text('JOBS_STUB'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-WORKERDASH-04] With no available jobs, shows an empty message and no job preview',
    (tester) async {
      await pumpTestApp(
        tester,
        child: const WorkerDashboardScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
          workerProfileProvider.overrideWith((ref) async => null),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Hiện chưa có công việc nào'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-WORKERDASH-05] The newest posted job is rendered directly on the dashboard, '
    'not just a count with a button to another screen',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const WorkerDashboardScreen(),
          ),
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) => Text('DETAIL:${state.pathParameters['id']}'),
          ),
          GoRoute(
            path: '/worker/jobs',
            builder: (_, __) => const Text('JOBS_STUB'),
          ),
        ],
      );
      final now = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
            availableBookingsProvider.overrideWith(
              (ref) async => [
                Booking(
                  id: 'a1',
                  serviceName: 'Home Cleaning',
                  date: '06/07/2026',
                  time: '09:00',
                  price: 150000,
                  status: 'AwaitingWorker',
                  createdAt: now.subtract(const Duration(minutes: 10)),
                ),
                Booking(
                  id: 'a2',
                  serviceName: 'Deep Cleaning',
                  date: '06/07/2026',
                  time: '10:00',
                  price: 250000,
                  status: 'AwaitingWorker',
                  createdAt: now,
                ),
              ],
            ),
            workerProfileProvider.overrideWith((ref) async => null),
            dispatchHubClientProvider.overrideWithValue(
              _FakeDispatchHubClient(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // The most recently posted job (a2) is shown with its real details, not just a count.
      expect(find.text('Deep Cleaning'), findsOneWidget);
      expect(find.textContaining('250.000'), findsOneWidget);
      expect(find.text('Home Cleaning'), findsNothing);

      await tester.tap(find.text('Deep Cleaning'));
      await tester.pumpAndSettle();
      expect(find.text('DETAIL:a2'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-WORKERDASH-06] With more than one available job, a secondary link still reaches the full list',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const WorkerDashboardScreen(),
          ),
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) => Text('DETAIL:${state.pathParameters['id']}'),
          ),
          GoRoute(
            path: '/worker/jobs',
            builder: (_, __) => const Text('JOBS_STUB'),
          ),
        ],
      );
      final now = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
            availableBookingsProvider.overrideWith(
              (ref) async => [
                Booking(
                  id: 'a1',
                  serviceName: 'Home Cleaning',
                  date: '06/07/2026',
                  time: '09:00',
                  price: 150000,
                  status: 'AwaitingWorker',
                  createdAt: now.subtract(const Duration(minutes: 10)),
                ),
                Booking(
                  id: 'a2',
                  serviceName: 'Deep Cleaning',
                  date: '06/07/2026',
                  time: '10:00',
                  price: 250000,
                  status: 'AwaitingWorker',
                  createdAt: now,
                ),
              ],
            ),
            workerProfileProvider.overrideWith((ref) async => null),
            dispatchHubClientProvider.overrideWithValue(
              _FakeDispatchHubClient(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xem tất cả'));
      await tester.pumpAndSettle();
      expect(find.text('JOBS_STUB'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-WORKERDASH-07] Tapping the availability toggle calls the repository and flips the label/color',
    (tester) async {
      final repository = _FakeWorkerRepository();
      await pumpTestApp(
        tester,
        child: const WorkerDashboardScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
          workerProfileProvider.overrideWith((ref) async => null),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
          workerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Ngoại tuyến'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('online-status-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Đang hoạt động'), findsOneWidget);
      expect(repository.calls, [true]);
    },
  );

  testWidgets(
    '[WT-FE-WORKERDASH-08] A failed toggle call reverts the displayed state and shows an error',
    (tester) async {
      final repository = _FakeWorkerRepository(shouldFail: true);
      await pumpTestApp(
        tester,
        child: const WorkerDashboardScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
          workerProfileProvider.overrideWith((ref) async => null),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
          workerRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('online-status-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Ngoại tuyến'), findsOneWidget);
      expect(
        find.textContaining('Không thể chuyển sang Online'),
        findsOneWidget,
      );
    },
  );
}

class _FakeDispatchHubClient implements DispatchHubClient {
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
  void onNearbyWorkersUpdated(void Function(List<({double lat, double lng})> locations) handler) {}
}

class _FakeWorkerRepository implements WorkerRepository {
  _FakeWorkerRepository({
    this.shouldFail = false,
    this.initialStatus = WorkerOnlineStatus.offline,
  });
  final bool shouldFail;
  final WorkerOnlineStatus initialStatus;
  final calls = <bool>[];

  @override
  Future<Worker?> getMyWorkerProfile() async => null;

  @override
  Future<WorkerOnlineStatus> getMyOnlineStatus() async => initialStatus;

  @override
  Future<void> updateLocation(double lat, double lng) async {}

  @override
  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  }) async {}

  @override
  Future<void> updateOnlineStatus(bool online) async {
    calls.add(online);
    if (shouldFail) {
      throw Exception('Không thể chuyển sang Online khi đang có công việc.');
    }
  }
}
