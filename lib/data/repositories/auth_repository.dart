import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../core/constants/user_role.dart';
import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';

export '../../core/constants/user_role.dart' show UserRole;

part 'auth_repository.g.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.fullName,
    required this.profileId,
    required this.role,
  });

  final String accessToken;
  final String refreshToken;
  final String fullName;
  final String? profileId;
  final UserRole role;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final roleString = json['role']?.toString().toLowerCase() ?? 'client';
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      fullName: json['fullName']?.toString() ?? 'Người dùng',
      profileId: json['profileId']?.toString(),
      role: switch (roleString) {
        'worker' => UserRole.worker,
        'admin' => UserRole.admin,
        _ => UserRole.client,
      },
    );
  }
}

abstract class AuthRepository {
  Future<AuthTokens> login(String emailOrPhone, String password);

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.client,
  });

  Future<AuthTokens> refreshToken({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> verifyAccount(String email, String otpCode);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String otpCode, String newPassword);
  Future<String> reauthenticate(String password);
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<AuthTokens> login(String emailOrPhone, String password) => guardApiCall(() async {
    final response = await _dio.post(
      '/Auth/login',
      data: {'emailOrPhone': emailOrPhone, 'password': password},
    );
    return AuthTokens.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.client,
  }) =>
  guardApiCall(() async {
    await _dio.post(
      '/Auth/register',
      data: {
        'email': email,
        'phoneNumber': phone,
        'password': password,
        'fullName': name,
        'role': role.apiValue,
      },
    );
  });

  @override
  Future<AuthTokens> refreshToken({
    required String accessToken,
    required String refreshToken,
  }) =>
  guardApiCall(() async {
    final response = await _dio.post(
      '/Auth/refresh-token',
      data: {'accessToken': accessToken, 'refreshToken': refreshToken},
    );
    return AuthTokens.fromJson(response.data as Map<String, dynamic>);
  });

  @override
  Future<void> verifyAccount(String email, String otpCode) => guardApiCall(() async {
    await _dio.post('/Auth/verify', data: {'email': email, 'otpCode': otpCode});
  });

  @override
  Future<void> forgotPassword(String email) => guardApiCall(() async {
    await _dio.post('/Auth/forgot-password', data: {'email': email});
  });

  @override
  Future<void> resetPassword(String email, String otpCode, String newPassword) =>
  guardApiCall(() async {
    await _dio.post('/Auth/reset-password', data: {
      'email': email,
      'otpCode': otpCode,
      'newPassword': newPassword,
    });
  });

  @override
  Future<String> reauthenticate(String password) => guardApiCall(() async {
    final response = await _dio.post('/Auth/reauth', data: {'password': password});
    return (response.data as Map<String, dynamic>)['reauthToken'] as String;
  });
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return ApiAuthRepository(ref.read(dioProvider));
}
