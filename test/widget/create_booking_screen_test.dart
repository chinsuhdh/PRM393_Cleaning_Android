import 'package:cleanai/core/network/dio_client.dart';
import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/ui/booking/create_booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import '../support/dio_test_harness.dart';

void main() {
  testWidgets(
    '[UT-FE-BOOK-001-01] Screen renders with addresses and navigates steps to summary',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository();
      await _pumpScreen(tester, harness, repository);

      expect(find.text('Đặt dịch vụ'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      // Address -> Date/Time. With the new flow there is no availability check, so continuing is instant.
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận'), findsWidgets);
    },
  );

  testWidgets(
    '[UT-FE-BOOK-001-08] "Đặt ngay" is disabled when the client already has an active Immediate '
    'booking (one in-flight search at a time)',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository(bookings: const [
        Booking(
          id: 'active-immediate', serviceName: 'Home Cleaning', date: '', time: '',
          price: 200000, status: 'AwaitingWorker', bookingType: 'Immediate',
        ),
      ]);
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      final segmented = tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>));
      final immediateSegment = segmented.segments.firstWhere((s) => s.value == 1);
      expect(immediateSegment.enabled, isFalse);
      expect(find.textContaining('đang có một đơn đặt ngay'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOK-001-06] Empty address list shows add-address prompt',
    (tester) async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/UserAddresses',
        (server) => server.reply(200, <Object>[]),
        data: null,
      );
      harness.adapter.onGet(
        '/ServiceCatalog/services/service-1',
        (server) => server.reply(200, {'id': 'service-1', 'name': 'Apartment cleaning', 'basePrice': 100000}),
        data: null,
      );
      final repository = _FakeBookingRepository();
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn chưa có địa chỉ để đặt dịch vụ.'), findsOneWidget);
      expect(find.text('Thêm địa chỉ'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOK-001-07] Address load error shows retry',
    (tester) async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/UserAddresses',
        (server) => server.reply(500, {'message': 'Address failure'}),
        data: null,
      );
      harness.adapter.onGet(
        '/ServiceCatalog/services/service-1',
        (server) => server.reply(200, {'id': 'service-1', 'name': 'Apartment cleaning', 'basePrice': 100000}),
        data: null,
      );
      final repository = _FakeBookingRepository();
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Không thể tải danh sách địa chỉ'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOK-003-01] Scheduled mode shows a date and time picker (no worker slots)',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository();
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Hẹn giờ'), findsOneWidget);
      expect(find.text('Ngày & giờ hẹn'), findsOneWidget);
      expect(find.textContaining('Khung giờ khả dụng'), findsNothing);
    },
  );

  testWidgets(
    '[UT-FE-BOOK-001-02] Confirmation button is enabled at the summary step',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository();
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // The label appears twice (summary heading + button), so target the button by its ancestor.
      final confirm = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Xác nhận'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(confirm.onPressed, isNotNull);
    },
  );

  testWidgets(
    '[UT-FE-BOOK-001-04] "Thêm địa chỉ mới" button appears when addresses exist',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository();
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm địa chỉ mới'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOK-004-01] The summary step renders the server breakdown lines and total verbatim (D.10)',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository(quote: {
        'serviceVersion': 1,
        'totalPrice': 243000,
        'breakdown': [
          {'label': 'Home Cleaning — base', 'amount': 120000},
          {'label': '3 rooms × 40,000₫', 'amount': 120000},
          {'label': 'Promotion −10%', 'amount': -27000},
        ],
      });
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Home Cleaning — base'), findsOneWidget);
      expect(find.text('3 rooms × 40,000₫'), findsOneWidget);
      expect(find.text('Promotion −10%'), findsOneWidget);
      expect(find.textContaining('243.000'), findsOneWidget);
    },
  );

  testWidgets(
    '[UT-FE-BOOK-004-02] A QUOTE_STALE create response triggers a silent re-quote and retry (D.5/D.11)',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository(failCreateOnce: true);
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();

      expect(find.text('Giá đã thay đổi, đang xác nhận lại.'), findsOneWidget);
      expect(repository.quoteCallCount, 2); // initial summary quote + the re-quote after staleness
      expect(repository.createCallCount, 2); // the retried create must actually succeed
    },
  );

  testWidgets(
    '[UT-FE-PAY-001-01] The create payload carries the chosen payment method by enum name — '
    'Cash by default, without the client ever touching the picker',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository();
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();

      expect(repository.lastCreatePayload?['paymentMethod'], 'Cash');
    },
  );

  testWidgets(
    '[UT-FE-PAY-001-02] Picking VNPay in the picker switches immediately (no linking step needed) '
    'and the create payload sends paymentMethod=Vnpay',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository();
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Open the payment picker sheet and choose VNPay (the picker sits below the fold).
      await tester.ensureVisible(find.text('Thay đổi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thay đổi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VNPay').last);
      await tester.pumpAndSettle();

      // The picker row now shows VNPay as the selected method, no dialog in the way.
      expect(find.text('VNPay'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await tester.pumpAndSettle();
      expect(repository.lastCreatePayload?['paymentMethod'], 'Vnpay');
    },
  );

  testWidgets(
    '[UT-FE-BOOK-001-05] "Quay lại" and "Tiếp tục" buttons have matching minimum heights',
    (tester) async {
      final harness = DioTestHarness();
      _stubBookingData(harness);
      final repository = _FakeBookingRepository();
      await _pumpScreen(tester, harness, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      final outlinedSize = tester.getSize(
        find.ancestor(of: find.text('Quay lại'), matching: find.byType(OutlinedButton)),
      );
      final filledSize = tester.getSize(
        find.ancestor(of: find.text('Tiếp tục'), matching: find.byType(FilledButton)),
      );

      expect(outlinedSize.height, equals(filledSize.height),
          reason: 'Both buttons should have the same rendered height');
      expect(outlinedSize.height, greaterThanOrEqualTo(48.0),
          reason: 'Buttons should be at least 48.0 logical pixels tall');
    },
  );
}

void _stubBookingData(DioTestHarness harness) {
  harness.adapter.onGet(
    '/UserAddresses',
    (server) => server.reply(200, [
      {'id': 'address-1', 'label': 'Home', 'addressText': '1 Test Street', 'isDefault': true},
    ]),
    data: null,
  );
  harness.adapter.onGet(
    '/ServiceCatalog/services/service-1',
    (server) => server.reply(200, {
      'id': 'service-1',
      'name': 'Apartment cleaning',
      'basePrice': 100000,
    }),
    data: null,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester,
  DioTestHarness harness,
  BookingRepository repository,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(harness.dio),
        bookingRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: CreateBookingScreen(serviceId: 'service-1'),
      ),
    ),
  );
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({
    Map<String, dynamic>? quote,
    this.failCreateOnce = false,
    this.bookings = const [],
  }) : _quote = quote ?? {
          'serviceVersion': 1,
          'totalPrice': 100000,
          'breakdown': [{'label': 'Base', 'amount': 100000}],
        };

  final Map<String, dynamic> _quote;
  final bool failCreateOnce;
  final List<Booking> bookings;
  int quoteCallCount = 0;
  int createCallCount = 0;

  @override
  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data) async {
    quoteCallCount++;
    return _quote;
  }

  @override
  Future<void> uploadPhotos(String bookingId, List<MultipartFile> photos) async {}

  @override
  Future<Map<String, dynamic>> getAvailability(Map<String, dynamic> data) async => {'slots': <Object>[]};

  Map<String, dynamic>? lastCreatePayload;

  @override
  Future<Booking> createBooking(Map<String, dynamic> data, {required String idempotencyKey}) async {
    createCallCount++;
    lastCreatePayload = data;
    if (failCreateOnce && createCallCount == 1) throw const QuoteStaleException();
    return const Booking(
      id: 'booking-1',
      serviceName: 'Apartment cleaning',
      date: '01/01/2030',
      time: '09:00',
      price: 100000,
      status: 'AwaitingWorker',
    );
  }

  @override
  Future<Booking?> getBookingById(String bookingId) async => null;

  @override
  Future<void> acceptBooking(String bookingId) async {}

  @override
  Future<void> cancelBookingByClient(String bookingId) async {}

  @override
  Future<void> switchToCash(String bookingId) async {}

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
  Future<List<Booking>> getClientBookings() async => bookings;

  @override
  Future<List<Booking>> getWorkerBookings() async => [];

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {}

  @override
  Future<void> updateDuration(String bookingId, double hours) async {}
}
