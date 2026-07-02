import 'package:cleanai/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test(
    '[UT-FE-AUTH-01] login parses the token/profile, sets the auth header and marks authenticated',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Auth/login',
        (server) => server.reply(200, {
          'accessToken': 'jwt-123',
          'fullName': 'Nguyễn Văn A',
          'profileId': 'p1',
        }),
        data: {'emailOrPhone': 'a@b.com', 'password': 'pw'},
      );
      final notifier = AuthNotifier(harness.dio);

      final ok = await notifier.login('a@b.com', 'pw', UserRole.client);

      expect(ok, isTrue);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.userId, 'p1');
      expect(notifier.state.userName, 'Nguyễn Văn A');
      expect(harness.dio.options.headers['Authorization'], 'Bearer jwt-123');
    },
  );

  test(
    '[UT-FE-AUTH-02] login returns false and stays unauthenticated on an error response',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Auth/login',
        (server) => server.reply(401, {'message': 'Sai thông tin đăng nhập.'}),
        data: {'emailOrPhone': 'a@b.com', 'password': 'wrong'},
      );
      final notifier = AuthNotifier(harness.dio);

      final ok = await notifier.login('a@b.com', 'wrong', UserRole.client);

      expect(ok, isFalse);
      expect(notifier.state.isAuthenticated, isFalse);
    },
  );
}
