import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/repositories/worker_repository.dart';
import 'package:cleanai/ui/worker/widgets/worker_suspension_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Worker? profile) => ProviderScope(
        overrides: [
          workerProfileProvider.overrideWith((ref) async => profile),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WorkerSuspensionBanner()),
        ),
      );

  testWidgets('[UT-FE-WSB-01] Renders nothing when the worker is not suspended', (tester) async {
    await tester.pumpWidget(wrap(Worker.fromJson({'userId': 'w1', 'averageRating': 4.5})));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('worker-suspension-banner')), findsNothing);
  });

  testWidgets('[UT-FE-WSB-02] Renders nothing when the profile has not resolved yet', (tester) async {
    await tester.pumpWidget(wrap(null));
    await tester.pump();

    expect(find.byKey(const ValueKey('worker-suspension-banner')), findsNothing);
  });

  testWidgets('[UT-FE-WSB-03] Renders the persistent red banner when suspended', (tester) async {
    await tester.pumpWidget(wrap(Worker.fromJson({
      'userId': 'w1',
      'averageRating': 4.5,
      'suspendedAt': '2026-07-10T08:00:00Z',
    })));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('worker-suspension-banner')), findsOneWidget);
    expect(find.textContaining('tạm khóa'), findsOneWidget);
  });
}
