import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/ui/worker/worker_active_job_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pump(WidgetTester tester, BookingRepository repository) {
    final router = GoRouter(
      initialLocation: '/worker/dashboard',
      routes: [
        GoRoute(
          path: '/worker/dashboard',
          builder: (_, __) => const Scaffold(
            bottomNavigationBar: WorkerActiveJobBar(),
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
        overrides: [bookingRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets(
    '[UT-FE-WORKERACTBAR-01] Nothing renders when the worker has no active job',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 100000, status: 'Completed'),
      ]));
      await tester.pumpAndSettle();

      expect(find.byType(WorkerActiveJobBar), findsOneWidget);
      expect(find.text('Dọn nhà'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-WORKERACTBAR-02] An Accepted job is shown and opens detail on tap',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 200000, status: 'Accepted'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Dọn nhà'), findsOneWidget);

      await tester.tap(find.byType(WorkerActiveJobBar));
      await tester.pumpAndSettle();
      expect(find.text('DETAIL_b1'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-WORKERACTBAR-03] An OnTheWay job shows that the worker is heading over',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 200000, status: 'OnTheWay'),
      ]));
      await tester.pumpAndSettle();

      expect(find.textContaining('trên đường'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-WORKERACTBAR-04] An InProgress job shows the work is currently being done',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'b1', serviceName: 'Dọn nhà', date: '', time: '', price: 200000, status: 'InProgress'),
      ]));
      await tester.pumpAndSettle();

      expect(find.textContaining('đang thực hiện'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-WORKERACTBAR-05] An in-progress job takes priority over a merely-accepted one',
    (tester) async {
      await pump(tester, _FakeBookingRepository(bookings: const [
        Booking(id: 'accepted', serviceName: 'Đơn đã nhận', date: '', time: '', price: 100000, status: 'Accepted'),
        Booking(id: 'doing', serviceName: 'Đơn đang làm', date: '', time: '', price: 200000, status: 'InProgress'),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('Đơn đang làm'), findsOneWidget);
      expect(find.text('Đơn đã nhận'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-WORKERACTBAR-06] A repository error is swallowed and the bar stays hidden',
    (tester) async {
      await pump(tester, _FailingBookingRepository());
      await tester.pumpAndSettle();

      expect(find.byType(WorkerActiveJobBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({required this.bookings});
  final List<Booking> bookings;

  @override
  Future<List<Booking>> getWorkerBookings() async => bookings;

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
  Future<void> switchToCash(String bookingId) async {}

  @override
  Future<void> workerCancelBooking(String bookingId, String reasonCode, {String? freeText}) async {}

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
  Future<List<Booking>> getClientBookings() async => [];

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {}
}

class _FailingBookingRepository implements BookingRepository {
  @override
  Future<List<Booking>> getWorkerBookings() async => throw Exception('network down');

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
  Future<void> switchToCash(String bookingId) async {}

  @override
  Future<void> workerCancelBooking(String bookingId, String reasonCode, {String? freeText}) async {}

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
  Future<List<Booking>> getClientBookings() async => [];

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {}
}
