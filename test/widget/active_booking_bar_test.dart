import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/data/services/dispatch_hub_service.dart';
import 'package:cleanai/ui/home/active_booking_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pump(WidgetTester tester, BookingRepository repository) {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(
            bottomNavigationBar: ActiveBookingBar(),
            body: SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/booking/:id',
          builder: (_, state) => Scaffold(
            body: Text('DETAIL_${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(repository),
          dispatchHubClientProvider.overrideWithValue(_FakeDispatchHubClient()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets(
    '[UT-FE-ACTBAR-01] Nothing renders when there is no AwaitingWorker booking',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 100000, status: 'Completed'),
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(ActiveBookingBar), findsOneWidget);
      expect(find.text('Dọn nhà'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-02] An Immediate AwaitingWorker booking shows a searching bar and opens detail on tap',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(
          id: 'b1',
          serviceName: 'Dọn nhà',
          date: '',
          time: '',
          price: 200000,
          status: 'AwaitingWorker',
          bookingType: 'Immediate',
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Dọn nhà'), findsOneWidget);
      expect(find.textContaining('Đang tìm nhân viên'), findsOneWidget);

      await tester.tap(find.byType(ActiveBookingBar));
      await tester.pumpAndSettle();
      expect(find.text('DETAIL_b1'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-03] A Scheduled AwaitingWorker booking shows a distinct waiting message',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(
          id: 'b2',
          serviceName: 'Giặt ủi',
          date: '10/07/2026',
          time: '09:00',
          price: 150000,
          status: 'AwaitingWorker',
          bookingType: 'Scheduled',
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Giặt ủi'), findsOneWidget);
      expect(find.textContaining('chờ nhân viên'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-04] With multiple AwaitingWorker bookings, the soonest one is shown',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: [
        Booking(
          id: 'later',
          serviceName: 'Dọn nhà sau',
          date: '',
          time: '',
          price: 200000,
          status: 'AwaitingWorker',
          bookingType: 'Scheduled',
          scheduledStartTime: DateTime.now().add(const Duration(days: 2)),
        ),
        Booking(
          id: 'sooner',
          serviceName: 'Dọn nhà trước',
          date: '',
          time: '',
          price: 200000,
          status: 'AwaitingWorker',
          bookingType: 'Immediate',
          scheduledStartTime: DateTime.now().add(const Duration(minutes: 15)),
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Dọn nhà trước'), findsOneWidget);
      expect(find.text('Dọn nhà sau'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-06] An OnTheWay booking shows "worker is on the way"',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 200000, status: 'OnTheWay'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Dọn nhà'), findsOneWidget);
      expect(find.textContaining('trên đường'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-07] An InProgress booking shows "job in progress"',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 200000, status: 'InProgress'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Dọn nhà'), findsOneWidget);
      expect(find.textContaining('đang được thực hiện'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-08] A PendingPayment booking is also surfaced',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 200000, status: 'PendingPayment'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Dọn nhà'), findsOneWidget);
      expect(find.textContaining('thanh toán'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-09] An in-progress job takes priority over a still-searching booking',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'searching', serviceName: 'Đang tìm', date: '', time: '', price: 100000, status: 'AwaitingWorker'),
        Booking(id: 'doing', serviceName: 'Đang làm', date: '', time: '', price: 200000, status: 'InProgress'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Đang làm'), findsOneWidget);
      expect(find.text('Đang tìm'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-11] An Immediate AwaitingWorker booking shows an elapsed timer, not just the '
    '"searching" subtitle alone — no progress bar, no deadline, it just counts up',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: [
        Booking(
          id: 'searching-timer',
          serviceName: 'Dọn nhà',
          date: '',
          time: '',
          price: 200000,
          status: 'AwaitingWorker',
          bookingType: 'Immediate',
          createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ]));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      final elapsed = find.byWidgetPredicate(
        (widget) => widget is Text && RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data ?? ''),
      );
      expect(elapsed, findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-12] A bookingStatusChanged push refreshes the bar live, no manual refresh needed',
    (tester) async {
      final client = _FakeDispatchHubClient();
      var bookings = [
        const Booking(
          id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 200000,
          status: 'Accepted',
        ),
      ];
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(
              bottomNavigationBar: ActiveBookingBar(),
              body: SizedBox.shrink(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingsProvider.overrideWith((ref) async => bookings),
            dispatchHubClientProvider.overrideWithValue(client),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('đã nhận đơn'), findsOneWidget);

      bookings = [
        const Booking(
          id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 200000,
          status: 'OnTheWay',
        ),
      ];
      client.fireBookingStatusChanged();
      await tester.pumpAndSettle();

      expect(find.textContaining('trên đường'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-ACTBAR-05] A repository error is swallowed and the bar stays hidden',
    (tester) async {
      await pump(tester, _FailingBookingRepository());
      await tester.pumpAndSettle();

      expect(find.byType(ActiveBookingBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({required this.bookings});
  final List<Booking> bookings;

  @override
  Future<List<Booking>> getClientBookings() async => bookings;

  @override
  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data) async => {};

  @override
  Future<void> uploadPhotos(String bookingId, photos) async {}

  @override
  Future<Booking?> getBookingById(String bookingId) async =>
      bookings.where((b) => b.id == bookingId).firstOrNull;

  @override
  Future<Map<String, dynamic>> getAvailability(Map<String, dynamic> data) async => {};

  @override
  Future<Booking> createBooking(Map<String, dynamic> data, {required String idempotencyKey}) async =>
      bookings.first;

  @override
  Future<void> acceptBooking(String bookingId) async {}

  @override
  Future<void> cancelBookingByClient(String bookingId) async {}

  @override
  Future<void> workerCancelBooking(String bookingId, String reasonCode, {String? freeText}) async {}

  @override
  Future<void> clientCancelBooking(String bookingId, String reasonCode, {String? freeText}) async {}

  @override
  Future<void> reportBooking(String bookingId, String reasonCode, String freeText) async {}

  @override
  Future<Booking> proposeReschedule(String bookingId, DateTime newStartTime, {String? message}) async =>
      const Booking(id: '', serviceName: '', date: '', time: '', price: 0, status: '');

  @override
  Future<Booking> respondReschedule(String bookingId, String requestId, String action) async =>
      const Booking(id: '', serviceName: '', date: '', time: '', price: 0, status: '');

  @override
  Future<List<Booking>> getAvailableBookings() async => [];

  @override
  Future<List<Booking>> getWorkerBookings() async => [];

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {}
}

class _FakeDispatchHubClient implements DispatchHubClient {
  void Function()? _onBookingStatusChanged;

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
  void onBookingStatusChanged(void Function() handler) => _onBookingStatusChanged = handler;

  @override
  void onWorkerPosition(void Function(double lat, double lng) handler) {}

  @override
  void onNearbyWorkersUpdated(void Function(List<({double lat, double lng})> locations) handler) {}

  @override
  void onReconnected(void Function() handler) {}

  void fireBookingStatusChanged() => _onBookingStatusChanged?.call();
}

class _FailingBookingRepository implements BookingRepository {
  @override
  Future<List<Booking>> getClientBookings() async => throw Exception('network down');

  @override
  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data) async => {};

  @override
  Future<void> uploadPhotos(String bookingId, photos) async {}

  @override
  Future<Booking?> getBookingById(String bookingId) async => null;

  @override
  Future<Map<String, dynamic>> getAvailability(Map<String, dynamic> data) async => {};

  @override
  Future<Booking> createBooking(Map<String, dynamic> data, {required String idempotencyKey}) async =>
      throw UnimplementedError();

  @override
  Future<void> acceptBooking(String bookingId) async {}

  @override
  Future<void> cancelBookingByClient(String bookingId) async {}

  @override
  Future<void> workerCancelBooking(String bookingId, String reasonCode, {String? freeText}) async {}

  @override
  Future<void> clientCancelBooking(String bookingId, String reasonCode, {String? freeText}) async {}

  @override
  Future<void> reportBooking(String bookingId, String reasonCode, String freeText) async {}

  @override
  Future<Booking> proposeReschedule(String bookingId, DateTime newStartTime, {String? message}) async =>
      const Booking(id: '', serviceName: '', date: '', time: '', price: 0, status: '');

  @override
  Future<Booking> respondReschedule(String bookingId, String requestId, String action) async =>
      const Booking(id: '', serviceName: '', date: '', time: '', price: 0, status: '');

  @override
  Future<List<Booking>> getAvailableBookings() async => [];

  @override
  Future<List<Booking>> getWorkerBookings() async => [];

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {}
}
