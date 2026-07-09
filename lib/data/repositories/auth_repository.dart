import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [THÊM MỚI] Để lưu token cục bộ

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

  // ==========================================
  // 1. LOGIN API
  // ==========================================
  Future<bool> login(String emailOrPhone, String password) async {
    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {"emailOrPhone": emailOrPhone, "password": password},
      );

      final data = response.data;
      final token = data['accessToken'];
      final refreshToken = data['refreshToken']; // Lấy refreshToken từ API
      final fullName = data['fullName'] ?? 'Người dùng';
      final profileId = data['profileId'];

      // Lấy Role từ API trả về và chuyển đổi sang Enum
      final roleString = data['role']?.toString().toLowerCase() ?? 'client';
      UserRole parsedRole = UserRole.client;
      if (roleString == 'worker') parsedRole = UserRole.worker;
      if (roleString == 'admin') parsedRole = UserRole.admin;

      // [BỔ SUNG] Lưu token vào SharedPreferences để dùng cho việc refresh sau này
      final prefs = await SharedPreferences.getInstance();
      if (token != null) await prefs.setString('accessToken', token);
      if (refreshToken != null) await prefs.setString('refreshToken', refreshToken);

      // Inject Token into Dio for subsequent requests
      DioClient.setAuthToken(_dio, token);

      // Update App State
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

  // ==========================================
  // 2. REGISTER API
  // ==========================================
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

  // ==========================================
  // 3. REAUTH API
  // ==========================================
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

  // ==========================================
  // 4. REFRESH TOKEN API [THÊM MỚI]
  // ==========================================
  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentRefreshToken = prefs.getString('refreshToken');
      final currentAccessToken = prefs.getString('accessToken');

      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        logout();
        return false;
      }

      // Dùng một instance Dio MỚI hoàn toàn, lấy baseUrl từ _dio hiện tại
      // KHÔNG dùng _dio có gắn AuthInterceptor để tránh bị lặp vô hạn (Infinite Loop)
      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));

      final response = await refreshDio.post(
        '/Auth/refresh-token', // Thay bằng endpoint thực tế của Backend C# nếu khác
        data: {
          'accessToken': currentAccessToken,
          'refreshToken': currentRefreshToken,
        },
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];

        // Cập nhật lại vào Local Storage
        await prefs.setString('accessToken', newAccessToken);
        await prefs.setString('refreshToken', newRefreshToken);

        // Cập nhật token mới vào DioClient đang dùng
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

  // ==========================================
  // 5. LOGOUT
  // ==========================================
  Future<void> logout() async {
    // [BỔ SUNG] Xóa token khỏi bộ nhớ cục bộ khi đăng xuất
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

// Các hàm tiện ích độc lập (không cần lưu state nội bộ)
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