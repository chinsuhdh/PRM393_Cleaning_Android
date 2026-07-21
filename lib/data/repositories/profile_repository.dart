import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../models/profile.dart';

/// Repository responsible for handling user profile operations via the backend API.
/// Utilizes Dio for network requests.
class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  /// Fetches the profile data of the currently authenticated user.
  /// Throws an exception if the data format is invalid or if the network request fails.
  Future<Profile> getMyProfile() async {
    try {
      final response = await _dio.get('/Profiles/me');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Profile.fromJson(data);
      }
      throw Exception('Format dữ liệu Profile không đúng');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi khi tải Profile');
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    try {
      await _dio.put(
        '/Profiles/me',
        data: {
          'fullName': fullName,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi cập nhật Profile',
      );
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(dioProvider));
});

final myProfileProvider = FutureProvider<Profile>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getMyProfile();
});