import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/typed_exceptions.dart';
import '../models/worker.dart';
import '../models/worker_earning.dart';

export '../../core/network/typed_exceptions.dart' show WorkerSuspendedException;

/// Abstract definition for the Worker repository.
/// Handles operations related to the worker's profile, location, status, and earnings.
abstract class WorkerRepository {
  /// Fetches the authenticated worker's profile data.
  Future<Worker?> getMyWorkerProfile();
  
  /// Fetches the current online status of the worker.
  Future<WorkerOnlineStatus> getMyOnlineStatus() async =>
      WorkerOnlineStatus.offline;
      
  /// Updates the worker's GPS location.
  Future<void> updateLocation(double lat, double lng);
  
  /// Updates the service radius within which the worker accepts jobs.
  Future<void> updateSearchRadius(double radiusKm);

  /// Registers a normal user as a worker by submitting their ID and skills.
  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  });

  /// Toggles the worker's online status (Online/Offline).
  Future<void> updateOnlineStatus(bool online);

  /// Updates the worker's bank account information for payouts.
  Future<void> updatePayoutAccount({
    required String bankBin,
    required String accountNumber,
    required String accountName,
  });

  Future<List<WorkerEarning>> getMyEarnings();
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
    }
  }

  @override
  Future<void> updateSearchRadius(double radiusKm) async {
    try {
      await _dio.patch(
        '/Workers/me/radius',
        data: {'serviceRadiusKm': radiusKm},
      );
    } on DioException catch (e) {
      debugPrint('[WorkerRepository] updateSearchRadius failed: $e');
      throw Exception(
        backendMessageFromDioException(
          e,
          fallback: 'Không thể cập nhật bán kính tìm việc.',
        ),
      );
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

  @override
  Future<void> updatePayoutAccount({
    required String bankBin,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      await _dio.put(
        '/Workers/me/payout-account',
        data: {
          'bankBin': bankBin,
          'accountNumber': accountNumber,
          'accountName': accountName,
        },
      );
    } on DioException catch (e) {
      debugPrint('[WorkerRepository] updatePayoutAccount failed: $e');
      throw Exception(
        backendMessageFromDioException(
          e,
          fallback: 'Không thể cập nhật tài khoản nhận tiền.',
        ),
      );
    }
  }

  @override
  Future<List<WorkerEarning>> getMyEarnings() async {
    try {
      final response = await _dio.get('/Workers/me/earnings');
      final data = response.data;
      if (data is List) {
        return data
            .map((item) => WorkerEarning.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[WorkerRepository] getMyEarnings failed: $e');
      throw Exception(
        backendMessageFromDioException(e, fallback: 'Không thể tải lịch sử thu nhập.'),
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

final workerEarningsProvider = FutureProvider.autoDispose<List<WorkerEarning>>((ref) async {
  return ref.read(workerRepositoryProvider).getMyEarnings();
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
