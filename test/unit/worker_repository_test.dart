import 'package:cleanai/data/repositories/worker_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test('[UT-FE-WORKERREPO-01] updateOnlineStatus(true) posts the expected payload', () async {
    final harness = DioTestHarness();
    harness.adapter.onPatch(
      '/Workers/online-status',
      (server) => server.reply(200, {'success': true, 'message': 'ok', 'data': null, 'errorCode': null}),
      data: {'onlineStatus': 'Online'},
    );
    final repository = ApiWorkerRepository(harness.dio);

    await repository.updateOnlineStatus(true);
  });

  test('[UT-FE-WORKERREPO-02] updateOnlineStatus(false) posts Offline', () async {
    final harness = DioTestHarness();
    harness.adapter.onPatch(
      '/Workers/online-status',
      (server) => server.reply(200, {'success': true, 'message': 'ok', 'data': null, 'errorCode': null}),
      data: {'onlineStatus': 'Offline'},
    );
    final repository = ApiWorkerRepository(harness.dio);

    await repository.updateOnlineStatus(false);
  });

  test('[UT-FE-WORKERREPO-03] A 400 (Busy-guard) error message propagates rather than being swallowed', () async {
    final harness = DioTestHarness();
    harness.adapter.onPatch(
      '/Workers/online-status',
      (server) => server.reply(400, {'message': 'Không thể chuyển sang Online khi đang có công việc.'}),
      data: {'onlineStatus': 'Online'},
    );
    final repository = ApiWorkerRepository(harness.dio);

    expect(
      () => repository.updateOnlineStatus(true),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Không thể chuyển sang Online khi đang có công việc.'),
        ),
      ),
    );
  });
}
