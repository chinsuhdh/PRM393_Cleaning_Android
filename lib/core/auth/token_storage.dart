import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'token_storage.g.dart';

const _accessTokenKey = 'accessToken';
const _refreshTokenKey = 'refreshToken';

/// Thin wrapper over [SharedPreferences] for auth tokens, isolating the
/// storage mechanism so [AuthNotifier] doesn't call `SharedPreferences.getInstance()` directly.
class TokenStorage {
  const TokenStorage();

  Future<String?> getAccessToken() async =>
      (await SharedPreferences.getInstance()).getString(_accessTokenKey);

  Future<String?> getRefreshToken() async =>
      (await SharedPreferences.getInstance()).getString(_refreshTokenKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => const TokenStorage();
