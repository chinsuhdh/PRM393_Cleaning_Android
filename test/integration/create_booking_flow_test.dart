import 'package:cleanai/core/network/dio_client.dart';
import 'package:cleanai/ui/booking/create_booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/dio_test_harness.dart';

void main() {
  testWidgets(
    '[IT-FE-BOOK-CREATE-01] Confirming an immediate booking POSTs to /Bookings and routes to finding-worker',
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
      // The real repository sends this exact payload for an immediate booking; if it does not match,
      // the mock adapter throws, no booking is returned, and navigation never happens.
      harness.adapter.onPost(
        '/Bookings',
        (server) => server.reply(200, {
          'id': 'booking-xyz',
          'serviceName': 'Apartment cleaning',
          'status': 'AwaitingWorker',
          'bookingType': 'Immediate',
          'totalPrice': 200000,
        }),
        data: {
          'serviceId': 'service-1',
          'addressId': 'address-1',
          'bookingType': 1,
          'durationHours': 2,
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
            path: '/finding-worker/:id',
            builder: (_, state) =>
                Scaffold(body: Text('FINDING ${state.pathParameters['id']}')),
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

      // Address step -> Date/Time step, pick immediate, -> Summary step.
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Confirm -> submit through the real ApiBookingRepository over the mocked Dio.
      await tester.tap(
        find.ancestor(of: find.text('Xác nhận'), matching: find.byType(FilledButton)),
      );
      await tester.pumpAndSettle();

      expect(find.text('FINDING booking-xyz'), findsOneWidget);
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
        '/Bookings',
        (server) => server.reply(400, {'message': 'Thời gian nằm ngoài giờ hoạt động.'}),
        data: {
          'serviceId': 'service-1',
          'addressId': 'address-1',
          'bookingType': 1,
          'durationHours': 2,
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
            path: '/finding-worker/:id',
            builder: (_, state) =>
                Scaffold(body: Text('FINDING ${state.pathParameters['id']}')),
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
      await tester.tap(find.text('Đặt ngay'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(of: find.text('Xác nhận'), matching: find.byType(FilledButton)),
      );
      await tester.pumpAndSettle();

      expect(find.text('FINDING booking-xyz'), findsNothing);
      expect(find.textContaining('Thời gian nằm ngoài giờ hoạt động.'), findsOneWidget);
    },
  );
}
