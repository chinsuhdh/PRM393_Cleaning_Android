import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/backend_error_message.dart';
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

  /// Toggles the worker's dispatch visibility. Unlike [updateLocation]'s best-effort silent catch,
  /// this is a deliberate, visible user action (a toggle in the UI) — errors (e.g. the backend's
  /// "can't go Online while Busy" guard) must surface so the UI can revert and show why.
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
  Future<void> updateOnlineStatus(bool online) async {
    try {
      await _dio.patch(
        '/Workers/online-status',
        data: {'onlineStatus': online ? 'Online' : 'Offline'},
      );
    } on DioException catch (e) {
      throw Exception(backendMessageFromDioException(e, fallback: 'Lỗi khi cập nhật trạng thái hoạt động.'));
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

/// Local optimistic online/offline state for the worker dashboard toggle. Deliberately NOT derived
/// from [workerProfileProvider] / [Worker.fromJson] — `GET /Workers/me` actually returns the
/// backend's `WorkerProfileDto` shape (no `name` field), which `Worker.fromJson` cannot parse
/// (pre-existing mismatch, out of scope here) — so there is no safe way to read the worker's real
/// current online status back from that provider today. This starts Offline and only reflects
/// this device's own toggle actions for the current session.
class WorkerOnlineStatusNotifier extends StateNotifier<bool> {
  WorkerOnlineStatusNotifier(this._ref) : super(false);
  final Ref _ref;

  Future<void> toggle(bool online) async {
    final previous = state;
    state = online;
    try {
      await _ref.read(workerRepositoryProvider).updateOnlineStatus(online);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final workerOnlineStatusProvider = StateNotifierProvider<WorkerOnlineStatusNotifier, bool>((ref) {
  return WorkerOnlineStatusNotifier(ref);
});
