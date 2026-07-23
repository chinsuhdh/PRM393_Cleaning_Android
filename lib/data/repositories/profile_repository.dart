import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';
import '../models/profile.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<Profile> getMyProfile() => guardApiCall(() async {
    final response = await _dio.get('/Profiles/me');
    return Profile.fromJson(response.data as Map<String, dynamic>);
  });

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
