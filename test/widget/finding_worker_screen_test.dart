import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/data/repositories/worker_repository.dart';
import 'package:cleanai/ui/booking/finding_worker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

void main() {
  testWidgets(
    '[UT-FE-DISPATCH-001-01] Searching times out and offers keep-waiting / cancel',
    (tester) async {
      final repository = _FakeBookingRepository(
        booking: const Booking(
          id: 'b1',
          serviceName: 'Dọn nhà',
          date: '',
          time: '',
          price: 200000,
          status: 'AwaitingWorker',
          bookingType: 'Immediate',
        ),
      );

      await _pump(tester, repository, searchTimeout: const Duration(milliseconds: 50));

      await tester.pump();
      expect(find.text('Đang tìm nhân viên phù hợp…'), findsOneWidget);
      expect(find.textContaining('Không có tọa độ địa chỉ'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có nhân viên nào nhận đơn'), findsOneWidget);
      expect(find.text('Tiếp tục chờ'), findsOneWidget);
      expect(find.text('Hủy đơn'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-DISPATCH-001-02] Shows assigned state once a worker accepts',
    (tester) async {
      final repository = _FakeBookingRepository(
        booking: const Booking(
          id: 'b1',
          serviceName: 'Dọn nhà',
          date: '',
          time: '',
          price: 200000,
          status: 'Accepted',
        ),
      );

      await _pump(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Đã có nhân viên nhận đơn!'), findsOneWidget);
      expect(find.text('Xem chi tiết đơn'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-DISPATCH-001-03] Scheduled bookings show the "request sent" waiting view (no map)',
    (tester) async {
      final repository = _FakeBookingRepository(
        booking: const Booking(
          id: 'b1',
          serviceName: 'Dọn nhà',
          date: '06/07/2026',
          time: '09:00',
          price: 200000,
          status: 'AwaitingWorker',
          bookingType: 'Scheduled',
        ),
      );

      await _pump(tester, repository);
      await tester.pump();

      expect(find.text('Đã gửi yêu cầu thành công!'), findsOneWidget);
      expect(find.text('Đang tìm nhân viên phù hợp…'), findsNothing);

      // Dispose the screen so its polling timer does not leak past the test.
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    '[UT-FE-DISPATCH-001-04] Cancelling sends the cancel request and returns home',
    (tester) async {
      final repository = _FakeBookingRepository(
        booking: const Booking(
          id: 'b1',
          serviceName: 'Dọn nhà',
          date: '06/07/2026',
          time: '09:00',
          price: 200000,
          status: 'AwaitingWorker',
          bookingType: 'Scheduled',
        ),
      );

      final router = GoRouter(
        initialLocation: '/finding',
        routes: [
          GoRoute(
            path: '/finding',
            builder: (_, __) => const FindingWorkerScreen(bookingId: 'b1'),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('HOME_STUB')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingRepositoryProvider.overrideWithValue(repository),
            workerRepositoryProvider.overrideWithValue(_FakeWorkerRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();

      expect(repository.cancelCount, 1);
      expect(find.text('HOME_STUB'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-DISPATCH-001-05] "Tiếp tục chờ" resumes searching after a timeout',
    (tester) async {
      final repository = _FakeBookingRepository(
        booking: const Booking(
          id: 'b1',
          serviceName: 'Dọn nhà',
          date: '',
          time: '',
          price: 200000,
          status: 'AwaitingWorker',
          bookingType: 'Immediate',
        ),
      );

      await _pump(tester, repository, searchTimeout: const Duration(milliseconds: 50));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có nhân viên nào nhận đơn'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục chờ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('Đang tìm nhân viên phù hợp…'), findsOneWidget);
      expect(find.text('Chưa có nhân viên nào nhận đơn'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  BookingRepository repository, {
  Duration searchTimeout = const Duration(seconds: 90),
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        bookingRepositoryProvider.overrideWithValue(repository),
        workerRepositoryProvider.overrideWithValue(_FakeWorkerRepository()),
      ],
      child: MaterialApp(
        home: FindingWorkerScreen(bookingId: 'b1', searchTimeout: searchTimeout),
      ),
    ),
  );
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({required this.booking});

  final Booking booking;
  int cancelCount = 0;

  @override
  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data) async => {};

  @override
  Future<void> uploadPhotos(String bookingId, List<MultipartFile> photos) async {}

  @override
  Future<Booking?> getBookingById(String bookingId) async => booking;

  @override
  Future<Map<String, dynamic>> getAvailability(Map<String, dynamic> data) async => {};

  @override
  Future<Booking> createBooking(Map<String, dynamic> data, {required String idempotencyKey}) async =>
      booking;

  @override
  Future<void> acceptBooking(String bookingId) async {}

  @override
  Future<void> cancelBooking(String bookingId) async {
    cancelCount++;
  }

  @override
  Future<List<Booking>> getAvailableBookings() async => [];

  @override
  Future<List<Booking>> getClientBookings() async => [];

  @override
  Future<List<Booking>> getWorkerBookings() async => [];

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {}
}

class _FakeWorkerRepository implements WorkerRepository {
  @override
  Future<Worker?> getMyWorkerProfile() async => null;

  @override
  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  }) async {}

  @override
  Future<void> updateLocation(double lat, double lng) async {}
}
