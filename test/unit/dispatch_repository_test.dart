import 'package:cleanai/data/repositories/dispatch_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test('[UT-FE-DISPATCH-01] getNearbyWorkerLocations parses a coordinate list', () async {
    final harness = DioTestHarness();
    harness.adapter.onGet(
      '/Bookings/b1/nearby-workers',
      (server) => server.reply(200, {
        'success': true,
        'message': 'ok',
        'data': [
          {'latitude': 10.77, 'longitude': 106.70},
          {'latitude': 10.78, 'longitude': 106.71},
        ],
        'errorCode': null,
      }),
      data: null,
    );
    final repository = ApiDispatchRepository(harness.dio);

    final locations = await repository.getNearbyWorkerLocations('b1');

    expect(locations, hasLength(2));
    expect(locations.first.lat, 10.77);
    expect(locations.first.lng, 106.70);
  });

  test('[UT-FE-DISPATCH-02] getNearbyWorkerLocations returns an empty list on error, not an exception', () async {
    final harness = DioTestHarness();
    harness.adapter.onGet(
      '/Bookings/b1/nearby-workers',
      (server) => server.reply(500, {'message': 'boom'}),
      data: null,
    );
    final repository = ApiDispatchRepository(harness.dio);

    final locations = await repository.getNearbyWorkerLocations('b1');

    expect(locations, isEmpty);
  });
}
