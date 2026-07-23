import 'package:cleanai/core/auth/auth_state.dart';
import 'package:cleanai/core/auth/token_storage.dart';
import 'package:cleanai/core/network/app_exception.dart';
import 'package:cleanai/core/network/dio_client.dart';
import 'package:cleanai/data/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/dio_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    '[UT-FE-AUTH-01] login parses the token/profile, sets the auth header and marks authenticated',
        () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Auth/login',
            (server) => server.reply(200, {
          'accessToken': 'jwt-123',
          'refreshToken': 'refresh-123',
          'fullName': 'Nguyễn Văn A',
          'profileId': 'p1',
          'role': 'client'
        }),
        data: {'emailOrPhone': 'a@b.com', 'password': 'pw'},
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(ApiAuthRepository(harness.dio)),
          tokenStorageProvider.overrideWithValue(const TokenStorage()),
          dioProvider.overrideWithValue(harness.dio),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.login('a@b.com', 'pw');

      final state = container.read(authNotifierProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.userId, 'p1');
      expect(state.userName, 'Nguyễn Văn A');
      expect(harness.dio.options.headers['Authorization'], 'Bearer jwt-123');
    },
  );

  test(
    '[UT-FE-AUTH-02] login throws AppException and stays unauthenticated on an error response',
        () async {
      final harness = DioTestHarness();
      harness.adapter.onPost(
        '/Auth/login',
            (server) => server.reply(401, {'message': 'Sai thông tin đăng nhập.'}),
        data: {'emailOrPhone': 'a@b.com', 'password': 'wrong'},
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(ApiAuthRepository(harness.dio)),
          tokenStorageProvider.overrideWithValue(const TokenStorage()),
          dioProvider.overrideWithValue(harness.dio),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(authNotifierProvider.notifier);

      await expectLater(
        () => notifier.login('a@b.com', 'wrong'),
        throwsA(isA<AppException>()),
      );
      expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
    },
  );
}
