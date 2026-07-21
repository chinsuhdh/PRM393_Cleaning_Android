import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/user_role.dart';
import '../../core/network/dio_client.dart';

export '../../core/constants/user_role.dart' show UserRole;

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? userName;
  final UserRole role;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.userName,
    this.role = UserRole.client,
  });

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

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._dio) : super(const AuthState());

  final Dio _dio;

  /// Authenticates a user using their email or phone number and password.
  /// 
  /// Upon successful authentication, it stores the access and refresh tokens locally
  /// and updates the application's authentication state.
  /// Returns [true] if login was successful, [false] otherwise.
  Future<bool> login(String emailOrPhone, String password) async {
    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {"emailOrPhone": emailOrPhone, "password": password},
      );

      final data = response.data;
      final token = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final fullName = data['fullName'] ?? 'Người dùng';
      final profileId = data['profileId'];

      final roleString = data['role']?.toString().toLowerCase() ?? 'client';
      UserRole parsedRole = UserRole.client;
      if (roleString == 'worker') parsedRole = UserRole.worker;
      if (roleString == 'admin') parsedRole = UserRole.admin;

      final prefs = await SharedPreferences.getInstance();
      if (token != null) await prefs.setString('accessToken', token);
      if (refreshToken != null) await prefs.setString('refreshToken', refreshToken);

      DioClient.setAuthToken(_dio, token);

      state = AuthState(
        isAuthenticated: true,
        userId: profileId,
        userName: fullName,
        role: parsedRole,
      );

      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      String errorMsg = "Lỗi đăng nhập";

      if (data is Map<String, dynamic> && data['message'] != null) {
        errorMsg = data['message'];
      } else {
        errorMsg = "Tài khoản chưa xác thực hoặc sai thông tin.";
      }

      print("Login Error: $errorMsg");
      return false;
    }
  }

  /// Registers a new user account with the specified role.
  /// 
  /// The default role is [UserRole.client] if not provided.
  /// Returns [true] if the registration API returns successfully.
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.client,
  }) async {
    try {
      final response = await _dio.post(
        '/Auth/register',
        data: {
          "email": email,
          "phoneNumber": phone,
          "password": password,
          "fullName": name,
          "role": role.apiValue,
        },
      );

      if (response.statusCode == 200) {
        print("Registration successful. Please verify OTP.");
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Registration Error: ${e.response?.data ?? e.message}");
      return false;
    }
  }

  Future<String?> reauthenticate(String password) async {
    try {
      final response = await _dio.post(
        '/Auth/reauth',
        data: {"password": password},
      );

      if (response.statusCode == 200) {
        return response.data['reauthToken'];
      }
      return null;
    } on DioException catch (e) {
      print("Reauth Error: ${e.response?.data['message'] ?? e.message}");
      return null;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentRefreshToken = prefs.getString('refreshToken');
      final currentAccessToken = prefs.getString('accessToken');

      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        logout();
        return false;
      }

      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));

      final response = await refreshDio.post(
        '/Auth/refresh-token',
        data: {
          'accessToken': currentAccessToken,
          'refreshToken': currentRefreshToken,
        },
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];

        await prefs.setString('accessToken', newAccessToken);
        await prefs.setString('refreshToken', newRefreshToken);

        DioClient.setAuthToken(_dio, newAccessToken);

        return true;
      } else {
        logout();
        return false;
      }
    } catch (e) {
      logout();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');

    DioClient.clearAuthToken(_dio);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(dioProvider));
});

Future<bool> verifyAccount(String email, String otpCode) async {
  try {
    final response = await DioClient.instance.post(
      '/Auth/verify',
      data: {"email": email, "otpCode": otpCode},
    );
    return response.statusCode == 200;
  } on DioException catch (e) {
    print("Lỗi xác thực: ${e.response?.data['message'] ?? e.message}");
    return false;
  }
}

Future<bool> forgotPassword(String email) async {
  try {
    final response = await DioClient.instance.post(
      '/Auth/forgot-password',
      data: {"email": email},
    );
    return response.statusCode == 200;
  } on DioException catch (e) {
    print("Lỗi quên MK: ${e.response?.data['message'] ?? e.message}");
    return false;
  }
}

Future<bool> resetPassword(
    String email,
    String otpCode,
    String newPassword,
    ) async {
  try {
    final response = await DioClient.instance.post(
      '/Auth/reset-password',
      data: {"email": email, "otpCode": otpCode, "newPassword": newPassword},
    );
    return response.statusCode == 200;
  } on DioException catch (e) {
    print("Lỗi đổi MK: ${e.response?.data['message'] ?? e.message}");
    return false;
  }
}