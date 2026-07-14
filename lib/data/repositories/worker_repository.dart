import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/typed_exceptions.dart';
import '../models/worker.dart';

export '../../core/network/typed_exceptions.dart' show WorkerSuspendedException;

abstract class WorkerRepository {
  Future<Worker?> getMyWorkerProfile();
  Future<WorkerOnlineStatus> getMyOnlineStatus() async =>
      WorkerOnlineStatus.offline;
  Future<void> updateLocation(double lat, double lng);

  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  });

  Future<void> updateOnlineStatus(bool online);
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
      debugPrint('[WorkerRepository] getMyWorkerProfile failed: $e');
      return null;
    }
  }

  @override
  Future<WorkerOnlineStatus> getMyOnlineStatus() async {
    final response = await _dio.get('/Workers/me');
    final data = response.data as Map<String, dynamic>;
    return WorkerOnlineStatus.fromApi(data['onlineStatus']?.toString());
  }

  @override
  Future<void> updateLocation(double lat, double lng) async {
    try {
      await _dio.patch(
        '/Workers/location',
        data: {'currentLat': lat, 'currentLng': lng},
      );
    } catch (e) {
      debugPrint('[WorkerRepository] updateLocation failed: $e');
      // Bỏ qua lỗi update location ngầm
    }
  }

  @override
  Future<void> updateOnlineStatus(bool online) async {
    try {
      await _dio.patch(
        '/Workers/online-status',
        data: {'onlineStatus': online ? 'Online' : 'Offline'},
      );
    } on DioException catch (e) {
      debugPrint('[WorkerRepository] updateOnlineStatus failed: $e');
      if (backendErrorCodeFromDioException(e) == 'WORKER_SUSPENDED') {
        throw const WorkerSuspendedException();
      }
      throw Exception(
        backendMessageFromDioException(
          e,
          fallback: 'Lỗi khi cập nhật trạng thái hoạt động.',
        ),
      );
    }
  }

  @override
  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  }) async {
    try {
      await _dio.post(
        '/Workers/register',
        data: {'identityCardNumber': identityCardNumber, 'skills': skills},
      );
    } on DioException catch (e) {
      debugPrint('[WorkerRepository] registerAsWorker failed: $e');
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

enum WorkerOnlineStatus {
  offline,
  online,
  busy;

  static WorkerOnlineStatus fromApi(String? value) =>
      switch (value?.toLowerCase()) {
        'online' => online,
        'busy' => busy,
        _ => offline,
      };
}

class WorkerOnlineStatusNotifier extends AsyncNotifier<WorkerOnlineStatus> {
  @override
  Future<WorkerOnlineStatus> build() =>
      ref.read(workerRepositoryProvider).getMyOnlineStatus();

  Future<void> toggle(bool online) async {
    final previous = state.valueOrNull ?? WorkerOnlineStatus.offline;
    state = const AsyncLoading();
    try {
      await ref.read(workerRepositoryProvider).updateOnlineStatus(online);
      state = AsyncData(
        online ? WorkerOnlineStatus.online : WorkerOnlineStatus.offline,
      );
    } catch (e) {
      debugPrint('[WorkerOnlineStatusNotifier] toggle failed: $e');
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final workerOnlineStatusProvider =
    AsyncNotifierProvider<WorkerOnlineStatusNotifier, WorkerOnlineStatus>(
      WorkerOnlineStatusNotifier.new,
    );
