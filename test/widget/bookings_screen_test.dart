import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/ui/booking/bookings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    '[WT-FE-BOOKINGS-01] Tapping a booking card opens its booking detail page',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/bookings',
        routes: [
          GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen()),
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) => Text('DETAIL:${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingsProvider.overrideWith((ref) async => const [
            Booking(
              id: 'b-ontheway', serviceName: 'Deep clean', status: 'OnTheWay',
              date: '06/07/2026', time: '09:00', price: 200000,
              worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
            ),
          ]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deep clean'));
      await tester.pumpAndSettle();

      expect(find.text('DETAIL:b-ontheway'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKINGS-02] Prices are VND everywhere, never a dollar sign',
    (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingsProvider.overrideWith((ref) async => const [
            Booking(
              id: 'b1', serviceName: 'Deep clean', status: 'InProgress',
              date: '06/07/2026', time: '09:00', price: 200000,
              worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
            ),
          ]),
        ],
        child: const MaterialApp(home: BookingsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('\$'), findsNothing);
      expect(find.textContaining('₫'), findsWidgets);
    },
  );

  testWidgets(
    '[WT-FE-BOOKINGS-03] A PendingPayment/payOS booking shows the "Cần thanh toán" badge on its card',
    (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingsProvider.overrideWith((ref) async => const [
            Booking(
              id: 'b-payos', serviceName: 'Deep clean', status: 'PendingPayment',
              date: '06/07/2026', time: '09:00', price: 200000, paymentMethod: 'Payos',
              worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
            ),
          ]),
        ],
        child: const MaterialApp(home: BookingsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cần thanh toán'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKINGS-04] A PendingPayment/Cash booking does not show the "Cần thanh toán" badge',
    (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingsProvider.overrideWith((ref) async => const [
            Booking(
              id: 'b-cash', serviceName: 'Deep clean', status: 'PendingPayment',
              date: '06/07/2026', time: '09:00', price: 200000, paymentMethod: 'Cash',
              worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
            ),
          ]),
        ],
        child: const MaterialApp(home: BookingsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cần thanh toán'), findsNothing);
    },
  );
}
