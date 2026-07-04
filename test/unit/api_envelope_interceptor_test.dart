import 'package:cleanai/core/network/backend_error_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test(
    '[UT-FE-ENVELOPE-01] a success envelope is unwrapped to its data payload',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/thing',
        (server) => server.reply(200, {
          'success': true,
          'message': 'Thành công.',
          'data': {'id': 'x'},
          'errorCode': null,
        }),
        data: null,
      );

      final response = await harness.dio.get('/thing');

      expect(response.data, {'id': 'x'});
      expect(response.extra['message'], 'Thành công.');
    },
  );

  test(
    '[UT-FE-ENVELOPE-02] an error envelope surfaces message and errorCode',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/thing',
        (server) => server.reply(404, {
          'success': false,
          'message': 'Không tìm thấy dữ liệu yêu cầu.',
          'data': null,
          'errorCode': 'NOT_FOUND',
        }),
        data: null,
      );

      try {
        await harness.dio.get('/thing');
        fail('expected a DioException');
      } on DioException catch (error) {
        expect(backendErrorCodeFromDioException(error), 'NOT_FOUND');
        expect(
          backendMessageFromDioException(error, fallback: 'fallback'),
          'Không tìm thấy dữ liệu yêu cầu.',
        );
      }
    },
  );

  test(
    '[UT-FE-ENVELOPE-03] a non-envelope body is passed through unchanged',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/thing',
        (server) => server.reply(200, [1, 2, 3]),
        data: null,
      );

      final response = await harness.dio.get('/thing');

      expect(response.data, [1, 2, 3]);
    },
  );
}
