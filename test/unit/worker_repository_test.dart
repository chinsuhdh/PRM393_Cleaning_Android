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

  test(
    '[UT-FE-WORKERREPO-04] updateOnlineStatus maps WORKER_SUSPENDED to WorkerSuspendedException (H.2)',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPatch(
        '/Workers/online-status',
        (server) => server.reply(403, {
          'success': false,
          'message': 'Tài khoản của bạn đã bị tạm khóa.',
          'data': null,
          'errorCode': 'WORKER_SUSPENDED',
        }),
        data: {'onlineStatus': 'Online'},
      );
      final repository = ApiWorkerRepository(harness.dio);

      expect(
        () => repository.updateOnlineStatus(true),
        throwsA(isA<WorkerSuspendedException>()),
      );
    },
  );

  test(
    '[UT-FE-WORKERREPO-05] updateLocation posts currentLat/currentLng, matching UpdateLocationDto '
    '(regression: previously sent latitude/longitude, which the backend silently bound to 0/0)',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPatch(
        '/Workers/location',
        (server) => server.reply(200, {'success': true, 'message': 'ok', 'data': null, 'errorCode': null}),
        data: {'currentLat': 10.7769, 'currentLng': 106.7009},
      );
      final repository = ApiWorkerRepository(harness.dio);

      await repository.updateLocation(10.7769, 106.7009);
    },
  );
}
