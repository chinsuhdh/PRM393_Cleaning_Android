import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/auth_repository.dart';
import '../network/dio_client.dart';
import 'token_storage.dart';

export '../../data/repositories/auth_repository.dart' show UserRole;

part 'auth_state.g.dart';

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.userName,
    this.role = UserRole.client,
  });

  final bool isAuthenticated;
  final String? userId;
  final String? userName;
  final UserRole role;

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? userName,
    UserRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
    );
  }
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late final AuthRepository _repository;
  late final TokenStorage _tokenStorage;
  late final Dio _dio;

  /// In-flight refresh, shared by concurrent callers (the 401 [AuthInterceptor]
  /// and [DispatchHubService]) so simultaneous failures trigger one refresh
  /// call instead of one per failed request.
  Future<bool>? _refreshInFlight;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _tokenStorage = ref.read(tokenStorageProvider);
    _dio = ref.read(dioProvider);
    return const AuthState();
  }

  /// Authenticates with email/phone + password. Throws [AppException] on
  /// failure — callers get the backend's real message instead of a generic one.
  Future<void> login(String emailOrPhone, String password) async {
    final tokens = await _repository.login(emailOrPhone, password);
    await _applyTokens(tokens);
  }

  /// Registers a new account. Throws [AppException] on failure (e.g. email/phone
  /// already taken).
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.client,
  }) =>
      _repository.register(name: name, email: email, phone: phone, password: password, role: role);

  Future<String?> reauthenticate(String password) async {
    try {
      return await _repository.reauthenticate(password);
    } catch (e) {
      debugPrint('[AuthNotifier] reauthenticate failed: $e');
      return null;
    }
  }

  /// Refreshes the access token. Returns `false` (and logs out) on failure,
  /// used by [AuthInterceptor] and [DispatchHubService] as a plain success flag.
  Future<bool> refreshToken() {
    return _refreshInFlight ??= _doRefreshToken().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefreshToken() async {
    final currentRefreshToken = await _tokenStorage.getRefreshToken();
    final currentAccessToken = await _tokenStorage.getAccessToken();

    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      await logout();
      return false;
    }

    try {
      final tokens = await _repository.refreshToken(
        accessToken: currentAccessToken ?? '',
        refreshToken: currentRefreshToken,
      );
      await _tokenStorage.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      DioClient.setAuthToken(_dio, tokens.accessToken);
      return true;
    } catch (e) {
      debugPrint('[AuthNotifier] refreshToken failed: $e');
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    DioClient.clearAuthToken(_dio);
    state = const AuthState();
  }

  Future<void> _applyTokens(AuthTokens tokens) async {
    await _tokenStorage.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    DioClient.setAuthToken(_dio, tokens.accessToken);
    state = AuthState(
      isAuthenticated: true,
      userId: tokens.profileId,
      userName: tokens.fullName,
      role: tokens.role,
    );
  }
}
