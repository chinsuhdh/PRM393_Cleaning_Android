import 'package:cleanai/core/network/dio_client.dart';
import 'package:cleanai/ui/client/booking/create_booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/dio_test_harness.dart';

void main() {
  testWidgets(
    '[IT-FE-BOOK-CREATE-01] Confirming an immediate booking POSTs to /Bookings and routes straight to Booking Detail',
    (tester) async {
      final harness = DioTestHarness();

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
      harness.adapter.onPost(
        '/Bookings/quote',
        (server) => server.reply(200, {
          'serviceVersion': 1,
          'totalPrice': 200000,
          'breakdown': [{'label': 'Base', 'amount': 200000}],
        }),
        data: {'serviceId': 'service-1', 'optionAnswers': <String, dynamic>{}},
      );
      harness.adapter.onPost(
        '/Bookings',
        (server) => server.reply(200, {
          'success': true,
          'message': 'Tạo đơn thành công.',
          'data': {
            'id': 'booking-xyz',
            'serviceName': 'Apartment cleaning',
            'status': 'AwaitingWorker',
            'bookingType': 'Immediate',
            'totalPrice': 200000,
          },
          'errorCode': null,
        }),
        data: {
          'serviceId': 'service-1',
          'addressId': 'address-1',
          'bookingType': 'Immediate',
          'serviceVersion': 1,
          'optionAnswers': <String, dynamic>{},
          'notes': 'Không có ghi chú',
        },
      );

      final router = GoRouter(
        initialLocation: '/book',
        routes: [
          GoRoute(
            path: '/book',
            builder: (_, __) => const CreateBookingScreen(serviceId: 'service-1'),
          ),
          GoRoute(
            path: '/bookings',
            builder: (_, __) => const Scaffold(body: Text('BOOKINGS_STUB')),
          ),
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) =>
                Scaffold(body: Text('DETAIL ${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: '/address',
            builder: (_, __) => const Scaffold(body: Text('ADDRESS_STUB')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(harness.dio)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.ancestor(of: find.text('Xác nhận'), matching: find.byType(FilledButton)),
      );
      await tester.pumpAndSettle();

      expect(find.text('DETAIL booking-xyz'), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('BOOKINGS_STUB'), findsOneWidget);
    },
  );

  testWidgets(
    '[IT-FE-BOOK-CREATE-02] A backend failure shows an error and stays on the booking screen',
    (tester) async {
      final harness = DioTestHarness();

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
      harness.adapter.onPost(
        '/Bookings/quote',
        (server) => server.reply(200, {
          'serviceVersion': 1,
          'totalPrice': 200000,
          'breakdown': [{'label': 'Base', 'amount': 200000}],
        }),
        data: {'serviceId': 'service-1', 'optionAnswers': <String, dynamic>{}},
      );
      harness.adapter.onPost(
        '/Bookings',
        (server) => server.reply(400, {
          'success': false,
          'message': 'Thời gian nằm ngoài giờ hoạt động.',
          'data': null,
          'errorCode': 'BOOKING_OUTSIDE_OPERATING_HOURS',
        }),
        data: {
          'serviceId': 'service-1',
          'addressId': 'address-1',
          'bookingType': 'Immediate',
          'serviceVersion': 1,
          'optionAnswers': <String, dynamic>{},
          'notes': 'Không có ghi chú',
        },
      );

      final router = GoRouter(
        initialLocation: '/book',
        routes: [
          GoRoute(
            path: '/book',
            builder: (_, __) => const CreateBookingScreen(serviceId: 'service-1'),
          ),
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) =>
                Scaffold(body: Text('DETAIL ${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(harness.dio)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(of: find.text('Xác nhận'), matching: find.byType(FilledButton)),
      );
      await tester.pumpAndSettle();

      expect(find.text('DETAIL booking-xyz'), findsNothing);
      expect(find.textContaining('Thời gian nằm ngoài giờ hoạt động.'), findsOneWidget);
    },
  );
}
