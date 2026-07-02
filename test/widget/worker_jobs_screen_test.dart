import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/repositories/booking_repository.dart';
import 'package:cleanai/ui/worker/worker_jobs_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_test_app.dart';

void main() {
  testWidgets(
    '[WT-FE-WORKERJOBS-01] Available tab lists dispatched jobs with an Accept button',
    (tester) async {
      await pumpTestApp(
        tester,
        child: const WorkerJobsScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => const [
            Booking(
              id: 'b1',
              serviceName: 'Dọn nhà',
              date: '06/07/2026',
              time: '09:00',
              price: 200000,
              status: 'AwaitingWorker',
            ),
          ]),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Available'));
      await tester.pumpAndSettle();

      expect(find.text('Dọn nhà'), findsOneWidget);
      expect(find.text('Accept Job'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-WORKERJOBS-02] Available tab shows the empty message when there are no jobs',
    (tester) async {
      await pumpTestApp(
        tester,
        child: const WorkerJobsScreen(),
        overrides: [
          workerBookingsProvider.overrideWith((ref) async => <Booking>[]),
          availableBookingsProvider.overrideWith((ref) async => <Booking>[]),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Available'));
      await tester.pumpAndSettle();

      expect(find.text('Không có đơn đặt lịch mới nào.'), findsOneWidget);
    },
  );
}
