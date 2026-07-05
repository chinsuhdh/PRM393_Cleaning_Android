import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../models/worker.dart';

abstract class WorkerRepository {
  Future<Worker?> getMyWorkerProfile();
  Future<void> updateLocation(double lat, double lng);

  /// Đăng ký thông tin định danh và kỹ năng cho thợ
  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  });
}

class ApiWorkerRepository implements WorkerRepository {
  ApiWorkerRepository(this._dio);

  final Dio _dio;

  @override
  Future<Worker?> getMyWorkerProfile() async {
    try {
      final response = await _dio.get('/Workers/me');
      if (response.data != null) {
        return Worker.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateLocation(double lat, double lng) async {
    try {
      await _dio.patch(
        '/Workers/location',
        data: {'latitude': lat, 'longitude': lng},
      );
    } catch (e) {
      // Bỏ qua lỗi update location ngầm
    }
  }

  @override
  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  }) async {
    try {
      // Backend sẽ mapping dữ liệu vào bảng worker_profiles và worker_skills
      await _dio.post(
        '/Workers/register',
        data: {'identityCardNumber': identityCardNumber, 'skills': skills},
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi khi đăng ký thông tin thợ.',
      );
    }
  }
}

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return ApiWorkerRepository(ref.read(dioProvider));
});

final workerProfileProvider = FutureProvider<Worker?>((ref) async {
  return ref.read(workerRepositoryProvider).getMyWorkerProfile();
});
