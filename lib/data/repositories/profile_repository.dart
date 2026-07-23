import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';
import '../models/profile.dart';

<<<<<<< Updated upstream
/// Repository responsible for handling user profile operations via the backend API.
/// Utilizes Dio for network requests.
=======
part 'profile_repository.g.dart';

>>>>>>> Stashed changes
class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

<<<<<<< Updated upstream
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
=======
  Future<Profile> getMyProfile() => guardApiCall(() async {
    final response = await _dio.get('/Profiles/me');
    return Profile.fromJson(response.data as Map<String, dynamic>);
  });
>>>>>>> Stashed changes

  Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) =>
  guardApiCall(() async {
    await _dio.put(
      '/Profiles/me',
      data: {
        'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
  });

  Future<String> uploadAvatar(String filePath, String filename) => guardApiCall(() async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final response = await _dio.post('/Profiles/me/avatar', data: formData);
    return (response.data as Map<String, dynamic>)['avatarUrl'] as String;
  });

  Future<void> sendPhoneVerificationOtp() => guardApiCall(() async {
    await _dio.post('/Auth/send-phone-otp');
  });

  Future<void> verifyPhone({required String phoneNumber, required String otpCode}) => guardApiCall(() async {
    await _dio.post('/Auth/verify-phone', data: {
      'phoneNumber': phoneNumber,
      'otpCode': otpCode,
    });
  });

  Future<void> changePassword({required String oldPassword, required String newPassword}) => guardApiCall(() async {
    await _dio.post('/Auth/change-password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  });

  Future<void> deleteAccount(String reauthToken) => guardApiCall(() async {
    await _dio.delete(
      '/Profiles/delete-account',
      options: Options(headers: {'X-Reauth-Token': reauthToken}),
    );
  });
}

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepository(ref.read(dioProvider));
}

@Riverpod(keepAlive: true)
Future<Profile> myProfile(Ref ref) async {
  final repo = ref.read(profileRepositoryProvider);
  return repo.getMyProfile();
}
