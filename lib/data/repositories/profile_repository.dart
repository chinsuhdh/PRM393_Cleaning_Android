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

  // Sửa Future<Profile> thành Future<void>
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
      // Xóa đoạn check Map<String, dynamic> và Profile.fromJson
      // Vì API PUT chỉ trả về object thông báo thành công, không trả về object Profile
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi cập nhật Profile',
      );
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  // Giả định dioProvider đã được khởi tạo trong core/network/dio_client.dart
  return ProfileRepository(ref.read(dioProvider));
});

final myProfileProvider = FutureProvider<Profile>((ref) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getMyProfile();
});