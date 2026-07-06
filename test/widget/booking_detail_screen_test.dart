import 'package:cleanai/core/constants/booking_enums.dart';
import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/repositories/auth_repository.dart';
import 'package:cleanai/ui/booking/booking_detail_screen.dart';
import 'package:cleanai/ui/booking/widgets/live_tracking_map.dart';
import 'package:cleanai/ui/booking/widgets/nearby_workers_google_map.dart';
import 'package:cleanai/ui/chat/chat_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// Regression for a real crash: Booking Detail's Chat button used to push the
// bare '/chat' path, which is a StatefulShellRoute branch (the AI-assistant
// tab), not a standalone route. Pushing a shell-branch path from a root route
// while that shell is already mounted elsewhere in the stack reuses the
// branch's static NavigatorState GlobalKey for a second Navigator, which
// throws go_router's "_debugCheckDuplicatedPageKeys" assertion.
void main() {
  testWidgets(
    '[WT-FE-BOOKDETAIL-01] Chat button opens a chat screen without duplicating the shell navigator',
    (tester) async {
      final shellChatKey = GlobalKey<NavigatorState>(debugLabel: 'shellChat');
      final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

      const booking = Booking(
        id: 'b1',
        serviceName: 'Home Cleaning',
        date: '06/07/2026',
        time: '09:00',
        price: 200000,
        status: BookingStatusName.accepted,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );

      final router = GoRouter(
        navigatorKey: rootKey,
        initialLocation: '/chat',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => Scaffold(body: shell),
            branches: [
              StatefulShellBranch(
                navigatorKey: shellChatKey,
                routes: [
                  GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/booking/:id',
            parentNavigatorKey: rootKey,
            builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/chat/:id',
            parentNavigatorKey: rootKey,
            builder: (_, __) => const ChatScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingDetailProvider('b1').overrideWith((ref) async => booking),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      router.push('/booking/b1');
      await tester.pumpAndSettle();

      final chatButton = find.byTooltip('Chat');
      await tester.ensureVisible(chatButton);
      await tester.pumpAndSettle();
      await tester.tap(chatButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CleanAI Assistant'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-02] A 403 (job no longer viewable — e.g. cancelled before this worker '
    'saw it disappear) shows a friendly "no longer available" message, not a raw DioException dump',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/booking/gone',
        routes: [
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingDetailProvider('gone').overrideWith((ref) async => throw DioException(
                  requestOptions: RequestOptions(path: '/Bookings/gone'),
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: RequestOptions(path: '/Bookings/gone'),
                    statusCode: 403,
                    data: {
                      'success': false,
                      'message': 'Bạn không có quyền thực hiện thao tác này.',
                      'errorCode': 'FORBIDDEN',
                    },
                  ),
                )),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('không còn khả dụng'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-03] Any other load error shows a friendly retry message, not a raw exception dump',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/booking/flaky',
        routes: [
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingDetailProvider('flaky').overrideWith((ref) async => throw DioException(
                  requestOptions: RequestOptions(path: '/Bookings/flaky'),
                  type: DioExceptionType.connectionError,
                )),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('DioException'), findsNothing);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  Future<void> pumpDetail(
    WidgetTester tester, {
    required Booking booking,
    UserRole role = UserRole.client,
  }) {
    final router = GoRouter(
      initialLocation: '/booking/${booking.id}',
      routes: [
        GoRoute(
          path: '/booking/:id',
          builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
        ),
      ],
    );
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingDetailProvider(booking.id).overrideWith((ref) async => booking),
          authProvider.overrideWith((ref) => _TestAuthNotifier(Dio(), role)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets(
    '[WT-FE-BOOKDETAIL-04] An Immediate AwaitingWorker booking, viewed by its client, shows the '
    'searching map + countdown inline, using the exact same app bar/sticky footer chrome as every '
    'other status — not a separate full-screen experience',
    (tester) async {
      const booking = Booking(
        id: 'searching', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.immediate,
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pump();

      // Same chrome as every other state: same app bar title, same sticky BookingActionBar footer.
      expect(find.text('Booking Detail'), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);
      // The map + countdown appear inline, not as a separate screen/widget.
      expect(find.byType(NearbyWorkersGoogleMap), findsOneWidget);
      expect(find.textContaining('Đang tìm nhân viên'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-05] A Scheduled AwaitingWorker booking still shows the plain detail page, '
    'not the searching map (only Immediate gets the live countdown treatment)',
    (tester) async {
      const booking = Booking(
        id: 'scheduled-awaiting', serviceName: 'Home Cleaning', date: '10/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.scheduled,
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.textContaining('Đang tìm nhân viên'), findsNothing);
      expect(find.text('Booking Details'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-06] A worker viewing an AwaitingWorker booking (any type) sees the job '
    'location on a map, before they have accepted it',
    (tester) async {
      const booking = Booking(
        id: 'not-accepted', serviceName: 'Home Cleaning', date: '10/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.scheduled,
      );
      await pumpDetail(tester, booking: booking, role: UserRole.worker);
      await tester.pumpAndSettle();

      expect(find.byType(NearbyWorkersGoogleMap), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-07] An OnTheWay booking shows the live tracking map for the client',
    (tester) async {
      const booking = Booking(
        id: 'ontheway-client', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.onTheWay,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.byType(LiveTrackingMap), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-08] An OnTheWay booking shows the same live tracking map for the worker '
    '("show direction and such" once they are heading there)',
    (tester) async {
      const booking = Booking(
        id: 'ontheway-worker', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.onTheWay,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.worker);
      await tester.pumpAndSettle();

      expect(find.byType(LiveTrackingMap), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-09] Accepted (not yet OnTheWay) shows neither map — only OnTheWay gets '
    'live tracking',
    (tester) async {
      const booking = Booking(
        id: 'accepted-no-map', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.accepted,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.worker);
      await tester.pumpAndSettle();

      expect(find.byType(LiveTrackingMap), findsNothing);
      expect(find.byType(NearbyWorkersGoogleMap), findsNothing);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-10] Status history is no longer shown inline — it moved into the sticky '
    "footer's History icon",
    (tester) async {
      const booking = Booking(
        id: 'with-history', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.completed,
        statusTimeline: [
          {'newStatus': 'Accepted', 'reason': ''},
          {'newStatus': 'Completed', 'reason': ''},
        ],
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.text('Status timeline'), findsNothing);
      expect(find.byTooltip('History'), findsOneWidget);

      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets); // once as the status badge, once in the history sheet
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-11] The action bar is pinned as the scaffold\'s bottom navigation bar (sticky), '
    'not part of the scrollable content',
    (tester) async {
      const booking = Booking(
        id: 'sticky-check', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.completed,
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.bottomNavigationBar, isNotNull);
      expect(find.text('Review'), findsOneWidget);
    },
  );
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(super.dio, UserRole role) {
    state = AuthState(isAuthenticated: true, role: role);
  }
}
