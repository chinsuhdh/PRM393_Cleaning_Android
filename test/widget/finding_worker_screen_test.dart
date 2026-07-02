import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/data/repositories/worker_repository.dart';
import 'package:cleanai/ui/booking/finding_worker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

      // Initially searching.
      await tester.pump();
      expect(find.text('Đang tìm nhân viên phù hợp…'), findsOneWidget);
      expect(find.textContaining('Không có tọa độ địa chỉ'), findsOneWidget);

      // Advance past the timeout so the next poll flips into the timed-out state.
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
  Future<void> cancelBooking(String bookingId) async {}

  @override
  Future<List<Booking>> getAvailableBookings() async => [];

  @override
  Future<List<Booking>> getClientBookings() async => [];

  @override
  Future<List<Booking>> getWorkerBookings() async => [];

  @override
  Future<void> updateBookingStatus(String bookingId, int newStatus) async {}
}

class _FakeWorkerRepository implements WorkerRepository {
  @override
  Future<List<Worker>> getRecommendedWorkers(String bookingId) async => [];

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
