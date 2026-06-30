import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

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

  Future<Profile> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.put(
        '/Profiles/me',
        data: {
          'fullName': fullName,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Profile.fromJson(data);
      }
      throw Exception('Format dữ liệu trả về không đúng');
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
