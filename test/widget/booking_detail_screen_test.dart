import 'dart:async';

import 'package:cleanai/core/constants/booking_enums.dart';
import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/repositories/auth_repository.dart';
import 'package:cleanai/data/models/review.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/data/repositories/dispatch_repository.dart';
import 'package:cleanai/data/repositories/review_repository.dart';
import 'package:cleanai/data/services/dispatch_hub_service.dart';
import 'package:cleanai/ui/booking/booking_detail_screen.dart';
import 'package:cleanai/ui/booking/widgets/live_tracking_map.dart';
import 'package:cleanai/ui/booking/widgets/nearby_workers_google_map.dart';
import 'package:cleanai/ui/booking/widgets/star_rating.dart';
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
            dispatchHubClientProvider.overrideWithValue(_NoOpDispatchHubClient()),
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
            dispatchHubClientProvider.overrideWithValue(_NoOpDispatchHubClient()),
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
            dispatchHubClientProvider.overrideWithValue(_NoOpDispatchHubClient()),
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
    List<Override> extraOverrides = const [],
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
          dispatchHubClientProvider.overrideWithValue(_NoOpDispatchHubClient()),
          reviewRepositoryProvider.overrideWithValue(_NoOpReviewRepository()),
          dispatchRepositoryProvider.overrideWithValue(_NoOpDispatchRepository()),
          ...extraOverrides,
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets(
    '[WT-FE-BOOKDETAIL-04] An Immediate AwaitingWorker booking, viewed by its client, shows a '
    'full-bleed map with a draggable sheet (Grab/Uber-style) holding the countdown + the same '
    'BookingActionBar used by every other status',
    (tester) async {
      const booking = Booking(
        id: 'searching', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.immediate,
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pump();

      // No AppBar for map-bearing states — the map fills the screen instead, with a floating back
      // button over it.
      expect(find.text('Booking Detail'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      // Cancel and Retry side by side — no deadline, so Retry is always available, not just after
      // some timeout.
      expect(find.text('Cancel booking'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // The map + elapsed timer appear inline, not as a separate screen/widget.
      expect(find.byType(NearbyWorkersGoogleMap), findsOneWidget);
      expect(find.textContaining('Đang tìm nhân viên'), findsOneWidget);
      // No progress bar / deadline — just an elapsed-time readout.
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-22] The map layout\'s draggable sheet can be dragged all the way to the top '
    'of the screen, and the floating back button stays on top of it (painted last in the Stack) '
    'rather than being hidden once the sheet is fully expanded',
    (tester) async {
      const booking = Booking(
        id: 'searching-full-drag', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.immediate,
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pump();

      final sheet = tester.widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet));
      expect(sheet.maxChildSize, 1.0);

      final stack = tester.widget<Stack>(find.byType(Stack).first);
      final backButtonIndex = stack.children.indexWhere(
        (child) => child is SafeArea,
      );
      final sheetIndex = stack.children.indexWhere(
        (child) => child is DraggableScrollableSheet,
      );
      expect(backButtonIndex, greaterThan(sheetIndex));

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-19] Cancelling while on the searching map layout cleanly switches to the '
    'plain layout (AppBar, cards, sticky footer) instead of corrupting the render — the two layouts '
    'are structurally very different Scaffolds swapped in place on the same still-mounted screen',
    (tester) async {
      var booking = const Booking(
        id: 'cancel-from-map', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.immediate,
      );
      final repo = _FakeBookingRepository();
      final router = GoRouter(
        initialLocation: '/booking/${booking.id}',
        routes: [
          GoRoute(
            path: '/booking/:id',
            // Mirrors app_router.dart's real pageBuilder for '/booking/:id' (like WT-FE-BOOKDETAIL-20
            // does) rather than a plain `builder:` — production stopped using a plain builder for this
            // route specifically to support the transition-skip reload, so a plain builder here no
            // longer exercises what actually ships.
            pageBuilder: (context, state) {
              final child = BookingDetailScreen(bookingId: state.pathParameters['id']!);
              if (state.extra == kBookingDetailSkipTransitionExtra) {
                return NoTransitionPage<void>(key: state.pageKey, child: child);
              }
              return MaterialPage<void>(key: state.pageKey, child: child);
            },
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingDetailProvider(booking.id).overrideWith((ref) async => booking),
          authProvider.overrideWith((ref) => _TestAuthNotifier(Dio(), UserRole.client)),
          dispatchHubClientProvider.overrideWithValue(_NoOpDispatchHubClient()),
          bookingRepositoryProvider.overrideWithValue(repo),
          dispatchRepositoryProvider.overrideWithValue(_NoOpDispatchRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();

      // Starts in the map layout (no AppBar, floating back button instead).
      expect(find.byType(NearbyWorkersGoogleMap), findsOneWidget);
      expect(find.text('Booking Detail'), findsNothing);

      final cancelButton = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Cancel booking'), matching: find.byType(OutlinedButton)),
      );
      cancelButton.onPressed!();
      // The fake repository doesn't mutate the booking itself — mirror what the real backend would
      // return on refetch, exactly like WT-FE-BOOKDETAIL-16 does for the other-party-cancel case.
      booking = const Booking(
        id: 'cancel-from-map', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.cancelled, bookingType: BookingTypeName.immediate,
      );
      // _reloadFresh now tears the live map down under its own rebuild (a non-animating placeholder,
      // `_mapTornDown`) and waits several real frames *before* the route replace — all driven by plain
      // `setState`/`endOfFrame`, so a normal `pumpAndSettle` carries it through like any other rebuild.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repo.cancelledBookingId, 'cancel-from-map');
      // Now the plain layout: AppBar back, no more map, "View reason" is the only footer action left.
      expect(find.text('Booking Detail'), findsOneWidget);
      expect(find.byType(NearbyWorkersGoogleMap), findsNothing);
      expect(find.text('View reason'), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.bottomNavigationBar, isNotNull);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-20] Cancelling while on the searching map layout replaces the route with a '
    'zero-duration/no-transition page, not the default animated MaterialPage transition. This only '
    'proves the transition is gone — it cannot prove the on-device rendering bug is fixed, since '
    'google_maps_flutter never runs a real platform view under flutter test (that gap is exactly why '
    'WT-FE-BOOKDETAIL-19 above already passed despite the real bug: the fix here is that '
    '_reloadFresh now passes kBookingDetailSkipTransitionExtra so the animated transition never '
    'overlaps the outgoing live GoogleMap\'s teardown). Real confirmation is manual, on an emulator.',
    (tester) async {
      var booking = const Booking(
        id: 'cancel-from-map-notransition', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.immediate,
      );
      final repo = _FakeBookingRepository();
      final router = GoRouter(
        initialLocation: '/booking/${booking.id}',
        routes: [
          GoRoute(
            path: '/booking/:id',
            // Mirrors app_router.dart's real pageBuilder for '/booking/:id' so this test exercises
            // the same transition-selection logic that ships to production, not a stand-in for it.
            pageBuilder: (context, state) {
              final child = BookingDetailScreen(bookingId: state.pathParameters['id']!);
              if (state.extra == kBookingDetailSkipTransitionExtra) {
                return NoTransitionPage<void>(key: state.pageKey, child: child);
              }
              return MaterialPage<void>(key: state.pageKey, child: child);
            },
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingDetailProvider(booking.id).overrideWith((ref) async => booking),
          authProvider.overrideWith((ref) => _TestAuthNotifier(Dio(), UserRole.client)),
          dispatchHubClientProvider.overrideWithValue(_NoOpDispatchHubClient()),
          bookingRepositoryProvider.overrideWithValue(repo),
          dispatchRepositoryProvider.overrideWithValue(_NoOpDispatchRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();

      final cancelButton = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Cancel booking'), matching: find.byType(OutlinedButton)),
      );
      cancelButton.onPressed!();
      booking = const Booking(
        id: 'cancel-from-map-notransition', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.cancelled, bookingType: BookingTypeName.immediate,
      );
      // See the equivalent comment in WT-FE-BOOKDETAIL-19: _reloadFresh's map-teardown wait is
      // frame-driven, so a normal `pumpAndSettle` carries it through.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('View reason'), findsOneWidget);
      // The type of Page behind the current route is what actually determines whether the
      // transition animated (MaterialPage, ~300ms) or not (NoTransitionPage, zero-duration) — not
      // whether the animation has finished, which is true for both after pumpAndSettle. This is
      // the assertion that distinguishes the fix from the pre-fix behavior.
      final route = ModalRoute.of(tester.element(find.text('View reason')));
      expect(route!.settings, isA<NoTransitionPage<void>>());
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-21] A brand-new BookingDetailScreen instance whose very first resolution is '
    'already Cancelled (as after _reloadFresh, with nothing ever passing through the map layout) '
    'renders the plain layout correctly on the first real frame — AppBar, and the action bar pinned '
    'as bottomNavigationBar, not floating loose. Passing here proves the Dart widget tree itself is '
    'correct for this transition; it does not cover the on-device rendering bug this same transition '
    'triggers (see WT-FE-BOOKDETAIL-20\'s caveat) — that needs manual, on-device verification.',
    (tester) async {
      const cancelled = Booking(
        id: 'fresh-instance-cancelled', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.cancelled, bookingType: BookingTypeName.immediate,
      );
      final completer = Completer<Booking>();
      final router = GoRouter(
        initialLocation: '/booking/${cancelled.id}',
        routes: [
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingDetailProvider(cancelled.id).overrideWith((ref) => completer.future),
          authProvider.overrideWith((ref) => _TestAuthNotifier(Dio(), UserRole.client)),
          dispatchHubClientProvider.overrideWithValue(_NoOpDispatchHubClient()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();

      // Still loading — AppBar visible, no exception yet.
      expect(find.text('Booking Detail'), findsOneWidget);
      expect(tester.takeException(), isNull);

      completer.complete(cancelled);
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Booking Detail'), findsOneWidget);
      expect(find.text('View reason'), findsOneWidget);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.bottomNavigationBar, isNotNull);
      expect(scaffold.body, isNotNull);
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
    '[WT-FE-BOOKDETAIL-09] Accepted keeps the live tracking map up (with the route line/ETA) — the '
    'map now stays for the whole lifecycle once a worker is assigned, not just OnTheWay',
    (tester) async {
      const booking = Booking(
        id: 'accepted-map', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.accepted,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.worker);
      await tester.pumpAndSettle();

      expect(find.byType(LiveTrackingMap), findsOneWidget);
      expect(tester.widget<LiveTrackingMap>(find.byType(LiveTrackingMap)).showRoute, isTrue);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-09b] InProgress still shows the map (worker has arrived, so no route line/ETA)',
    (tester) async {
      const booking = Booking(
        id: 'no-route-inprogress', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.inProgress,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.byType(LiveTrackingMap), findsOneWidget);
      expect(tester.widget<LiveTrackingMap>(find.byType(LiveTrackingMap)).showRoute, isFalse);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-09c] PendingPayment still shows the map (worker has arrived, so no route '
    'line/ETA)',
    (tester) async {
      const booking = Booking(
        id: 'no-route-pendingpayment', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.pendingPayment,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.byType(LiveTrackingMap), findsOneWidget);
      expect(tester.widget<LiveTrackingMap>(find.byType(LiveTrackingMap)).showRoute, isFalse);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-09d] Completed drops the map entirely, even though a worker is still assigned',
    (tester) async {
      const booking = Booking(
        id: 'no-map-completed', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.completed,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.byType(LiveTrackingMap), findsNothing);
      expect(find.byType(NearbyWorkersGoogleMap), findsNothing);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-09e] Cancelled drops the map entirely, even though a worker was assigned',
    (tester) async {
      const booking = Booking(
        id: 'no-map-cancelled', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.cancelled,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.byType(LiveTrackingMap), findsNothing);
      expect(find.byType(NearbyWorkersGoogleMap), findsNothing);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-23] A Completed booking with an assigned worker and known coordinates shows '
    'a bounded (not full-bleed) location card, still on the plain layout Scaffold, not the map layout',
    (tester) async {
      const booking = Booking(
        id: 'completed-with-location', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.completed,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
        latitude: 10.77, longitude: 106.70,
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('booking-detail-plain-layout')), findsOneWidget);
      expect(find.byKey(const ValueKey('booking-detail-map-layout')), findsNothing);
      expect(find.byKey(const ValueKey('completed-job-location-map')), findsOneWidget);
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byKey(const ValueKey('completed-job-location-map')),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.height, 220);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-24] A Completed booking with no known coordinates renders without the '
    'bounded location card (no crash on null lat/lng)',
    (tester) async {
      const booking = Booking(
        id: 'completed-no-location', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.completed,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('completed-job-location-map')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-25] A Completed booking with an assigned worker shows the inline review '
    'section for the client, and it renders the star input when no review exists yet',
    (tester) async {
      const booking = Booking(
        id: 'completed-review-client', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.completed,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('booking-review-section')), findsOneWidget);
      expect(find.byType(StarRatingInput), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-26] A Completed booking with an assigned worker, viewed by the worker with no '
    "review yet, shows the empty state instead of an input",
    (tester) async {
      const booking = Booking(
        id: 'completed-review-worker', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.completed,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.worker);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('review-empty-state')), findsOneWidget);
      expect(find.byType(StarRatingInput), findsNothing);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-27] A Completed booking with an existing review shows it read-only instead '
    'of the submission form',
    (tester) async {
      const booking = Booking(
        id: 'completed-review-existing', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.completed,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      await pumpDetail(
        tester,
        booking: booking,
        role: UserRole.client,
        extraOverrides: [
          reviewRepositoryProvider.overrideWithValue(_NoOpReviewRepository(
            reviews: [
              Review(
                id: 'r1', bookingId: booking.id, reviewerId: 'client-1', revieweeId: 'w1',
                rating: 5, comment: 'Great!', createdAt: DateTime(2026, 7, 1),
              ),
            ],
          )),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(StarRatingInput), findsNothing);
      expect(find.byType(StarRatingDisplay), findsOneWidget);
      expect(find.text('Great!'), findsOneWidget);
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
      // Completed always shows the chat action in the sticky footer, regardless of role — used
      // here as a stand-in proof the footer actually rendered its content.
      expect(find.byTooltip('Chat'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-12] The elapsed timer is derived from booking.createdAt, not from when the '
    'screen happened to open — so it reflects real elapsed time instead of always restarting at 0 '
    'after leaving and reopening the screen. There is no deadline, so it just keeps counting up.',
    (tester) async {
      final booking = Booking(
        id: 'searching-resumed', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.immediate,
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pump();

      // 4 minutes have already elapsed — the timer reflects that immediately instead of starting
      // from 0 the way a screen-local timer used to.
      final elapsed = find.byWidgetPredicate(
        (widget) => widget is Text && RegExp(r'^\d{2}:\d{2}$').hasMatch(widget.data ?? ''),
      );
      expect(elapsed, findsOneWidget);
      final text = tester.widget<Text>(elapsed).data!;
      expect(text.startsWith('04:') || text.startsWith('03:'), isTrue, reason: 'was $text');
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-13] Even long after the search started with still no worker, the screen stays '
    'on the normal searching map — no auto-cancel, no forced popup, no deadline at all',
    (tester) async {
      final booking = Booking(
        id: 'long-search', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.immediate,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      final repo = _FakeBookingRepository();
      await pumpDetail(
        tester,
        booking: booking,
        role: UserRole.client,
        extraOverrides: [bookingRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.pump();

      expect(find.byType(NearbyWorkersGoogleMap), findsOneWidget);
      expect(find.text('Cancel booking'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(repo.cancelledBookingId, isNull);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-15] Tapping Retry cancels the current booking and sends the client back to '
    'the request-creation screen (the questions step) for the same service, to start over',
    (tester) async {
      final booking = Booking(
        id: 'retry-me', serviceId: 'service-42', serviceName: 'Home Cleaning', date: '', time: '',
        price: 200000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.immediate,
      );
      final repo = _FakeBookingRepository();
      final router = GoRouter(
        initialLocation: '/booking/${booking.id}',
        routes: [
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/booking/create/:serviceId',
            builder: (_, state) => Scaffold(body: Text('CREATE_${state.pathParameters['serviceId']}')),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingDetailProvider(booking.id).overrideWith((ref) async => booking),
          authProvider.overrideWith((ref) => _TestAuthNotifier(Dio(), UserRole.client)),
          dispatchHubClientProvider.overrideWithValue(_NoOpDispatchHubClient()),
          bookingRepositoryProvider.overrideWithValue(repo),
          dispatchRepositoryProvider.overrideWithValue(_NoOpDispatchRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();

      final retryButton = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Retry'), matching: find.byType(OutlinedButton)),
      );
      retryButton.onPressed!();
      await tester.pumpAndSettle();

      expect(repo.cancelledBookingId, booking.id);
      expect(find.text('CREATE_service-42'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-16] If the booking gets cancelled by the other party while this screen is '
    'open, a popup tells the viewer and takes them back to wherever they came from',
    (tester) async {
      var booking = const Booking(
        id: 'live-cancel', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.accepted,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      final client = _FakeLiveUpdateHubClient();
      final router = GoRouter(
        initialLocation: '/selection',
        routes: [
          GoRoute(path: '/selection', builder: (_, __) => const Scaffold(body: Text('SELECTION_SCREEN'))),
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingDetailProvider(booking.id).overrideWith((ref) async => booking),
          authProvider.overrideWith((ref) => _TestAuthNotifier(Dio(), UserRole.worker)),
          dispatchHubClientProvider.overrideWithValue(client),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();
      router.push('/booking/${booking.id}');
      await tester.pumpAndSettle();

      // Simulate the other party cancelling: the next fetch (triggered by the live push, exactly like
      // production) now returns a Cancelled booking.
      booking = Booking(
        id: booking.id,
        serviceName: booking.serviceName,
        date: booking.date,
        time: booking.time,
        price: booking.price,
        status: BookingStatusName.cancelled,
        worker: booking.worker,
      );
      client.fireBookingStatusChanged();
      await tester.pumpAndSettle();

      expect(find.text('Đơn đã bị hủy'), findsOneWidget);
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();

      expect(find.text('SELECTION_SCREEN'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-14] A bookingStatusChanged push while viewing Booking Detail refreshes the '
    'booking live, so a status change made by the other party shows up without a manual refresh',
    (tester) async {
      final client = _FakeLiveUpdateHubClient();
      var fetchCount = 0;
      const booking = Booking(
        id: 'live-update', serviceName: 'Home Cleaning', date: '06/07/2026', time: '09:00',
        price: 200000, status: BookingStatusName.accepted,
        worker: Worker(id: 'w1', name: 'Alex', rating: 4.8),
      );
      final router = GoRouter(
        initialLocation: '/booking/${booking.id}',
        routes: [
          GoRoute(
            path: '/booking/:id',
            builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          bookingDetailProvider(booking.id).overrideWith((ref) async {
            fetchCount++;
            return booking;
          }),
          authProvider.overrideWith((ref) => _TestAuthNotifier(Dio(), UserRole.client)),
          dispatchHubClientProvider.overrideWithValue(client),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      expect(fetchCount, 1);
      expect(client.subscribedBookingIds, [booking.id]);

      client.fireBookingStatusChanged();
      await tester.pumpAndSettle();

      expect(fetchCount, 2);
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-28] The sticky footer hugs the bottom edge instead of stretching over the '
    'whole page. Regression: BookingActionBar\'s Column defaulted to MainAxisSize.max, and Scaffold '
    'offers its bottomNavigationBar slot the full remaining height as a loose constraint — the '
    'footer\'s opaque Material grew to cover the entire screen (AppBar and body hidden under white, '
    'only the action buttons visible, pinned at the top).',
    (tester) async {
      const booking = Booking(
        id: 'b1', serviceName: 'Apartment Cleaning', date: '08/07/2026', time: '09:00',
        price: 320000, status: BookingStatusName.cancelled, bookingType: BookingTypeName.scheduled,
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pumpAndSettle();

      final screen = tester.getSize(find.byType(BookingDetailScreen));
      final footerActionTop = tester.getRect(find.text('View reason')).top;
      // Footer content must sit near the bottom edge, not at the top of the screen.
      expect(footerActionTop, greaterThan(screen.height * 0.7),
          reason: 'sticky footer should be at the bottom of the screen, not stretched to the top');
      // Body content must be laid out in its normal spot right under the app bar.
      expect(tester.getRect(find.text('Apartment Cleaning')).top, lessThan(screen.height * 0.4));
    },
  );

  testWidgets(
    '[WT-FE-BOOKDETAIL-29] A Scheduled AwaitingWorker booking viewed by its client shows the same '
    'full-bleed nearby-workers map layout as an Immediate one — the map stays present through the '
    'whole lifecycle for both booking types — but without the Immediate-only searching countdown '
    'card, and with Cancel as the only footer action (no Retry for Scheduled)',
    (tester) async {
      const booking = Booking(
        id: 'scheduled-waiting', serviceName: 'Home Cleaning', date: '08/07/2026', time: '09:00',
        price: 320000, status: BookingStatusName.awaitingWorker, bookingType: BookingTypeName.scheduled,
      );
      await pumpDetail(tester, booking: booking, role: UserRole.client);
      await tester.pump();

      // Map layout: nearby-workers map + floating back button, no AppBar.
      expect(find.byType(NearbyWorkersGoogleMap), findsOneWidget);
      expect(find.text('Booking Detail'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      // No live-search countdown for Scheduled — that treatment stays Immediate-only.
      expect(find.textContaining('Đang tìm nhân viên'), findsNothing);
      // Scheduled keeps just Cancel (no Retry row).
      expect(find.text('Cancel booking'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    },
  );
}

/// initState() always subscribes to the dispatch hub (E-T3/booking-scoped live updates), even before
/// the booking has loaded — every test that doesn't specifically exercise that hub needs this no-op
/// stand-in, or the real SignalrDispatchHubClient attempts a network connection and leaves a pending
/// timer behind after the widget tree is disposed.
class _NoOpDispatchHubClient implements DispatchHubClient {
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
}

/// Default stand-in so a Completed+worker booking's inline BookingReviewSection (which fetches
/// reviews on watch) never makes a real network call in tests that aren't specifically exercising
/// the review flow. Individual tests can still override reviewRepositoryProvider via extraOverrides.
class _NoOpReviewRepository implements ReviewRepository {
  _NoOpReviewRepository({List<Review> reviews = const []}) : _reviews = reviews;
  final List<Review> _reviews;

  @override
  Future<Review> createReview({
    required String bookingId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Review>> getReviewsForUser(String userId) async =>
      _reviews.where((r) => r.revieweeId == userId).toList();
}

/// Default stand-in so the searching-phase map's nearby-worker polling never makes a real network
/// call in tests that aren't specifically exercising it.
class _NoOpDispatchRepository implements DispatchRepository {
  @override
  Future<void> hideBooking(String bookingId) async {}

  @override
  Future<void> retryBroadcast(String bookingId) async {}

  @override
  Future<List<({double lat, double lng})>> getNearbyWorkerLocations(String bookingId) async => [];
}

class _FakeBookingRepository implements BookingRepository {
  String? cancelledBookingId;
  String? cancelledReason;

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? reason}) async {
    if (newStatus == BookingStatusName.cancelled) {
      cancelledBookingId = bookingId;
      cancelledReason = reason;
    }
  }

  @override
  Future<List<Booking>> getClientBookings() async => [];

  @override
  Future<List<Booking>> getWorkerBookings() async => [];

  @override
  Future<List<Booking>> getAvailableBookings() async => [];

  @override
  Future<Booking?> getBookingById(String bookingId) async => null;

  @override
  Future<Map<String, dynamic>> getAvailability(Map<String, dynamic> data) async => {};

  @override
  Future<Map<String, dynamic>> getQuote(Map<String, dynamic> data) async => {};

  @override
  Future<Booking> createBooking(Map<String, dynamic> data, {required String idempotencyKey}) =>
      throw UnimplementedError();

  @override
  Future<void> cancelBooking(String bookingId) async {}

  @override
  Future<void> acceptBooking(String bookingId) async {}

  @override
  Future<void> uploadPhotos(String bookingId, List<MultipartFile> photos) async {}
}

class _FakeLiveUpdateHubClient implements DispatchHubClient {
  final List<String> subscribedBookingIds = [];
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
  Future<void> subscribeToBooking(String bookingId) async => subscribedBookingIds.add(bookingId);

  @override
  void onBookingStatusChanged(void Function() handler) => _onBookingStatusChanged = handler;

  void fireBookingStatusChanged() => _onBookingStatusChanged?.call();
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(super.dio, UserRole role) {
    state = AuthState(isAuthenticated: true, role: role);
  }
}
