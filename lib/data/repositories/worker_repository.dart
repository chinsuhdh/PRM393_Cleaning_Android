import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';
import '../models/worker.dart';
import '../models/worker_earning.dart';

part 'worker_repository.g.dart';

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
  Future<Worker?> getMyWorkerProfile() => guardApiCall(() async {
        final response = await _dio.get('/Workers/me');
        if (response.data == null) return null;
        return Worker.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<WorkerOnlineStatus> getMyOnlineStatus() => guardApiCall(() async {
        final response = await _dio.get('/Workers/me');
        final data = response.data as Map<String, dynamic>;
        return WorkerOnlineStatus.fromApi(data['onlineStatus']?.toString());
      });

  @override
  Future<void> updateLocation(double lat, double lng) => guardApiCall(() async {
        await _dio.patch(
          '/Workers/location',
          data: {'currentLat': lat, 'currentLng': lng},
        );
      });

  @override
  Future<void> updateSearchRadius(double radiusKm) => guardApiCall(() async {
        await _dio.patch(
          '/Workers/me/radius',
          data: {'serviceRadiusKm': radiusKm},
        );
      });

  @override
  Future<void> updateOnlineStatus(bool online) => guardApiCall(() async {
        await _dio.patch(
          '/Workers/online-status',
          data: {'onlineStatus': online ? 'Online' : 'Offline'},
        );
      });

  @override
  Future<void> registerAsWorker({
    required String identityCardNumber,
    required List<Map<String, dynamic>> skills,
  }) =>
      guardApiCall(() async {
        await _dio.post(
          '/Workers/register',
          data: {'identityCardNumber': identityCardNumber, 'skills': skills},
        );
      });

  @override
  Future<void> updatePayoutAccount({
    required String bankBin,
    required String accountNumber,
    required String accountName,
  }) =>
      guardApiCall(() async {
        await _dio.put(
          '/Workers/me/payout-account',
          data: {
            'bankBin': bankBin,
            'accountNumber': accountNumber,
            'accountName': accountName,
          },
        );
      });

  @override
  Future<List<WorkerEarning>> getMyEarnings() => guardApiCall(() async {
        final response = await _dio.get('/Workers/me/earnings');
        final data = response.data;
        if (data is! List) return [];
        return data.map((item) => WorkerEarning.fromJson(item as Map<String, dynamic>)).toList();
      });
}

@Riverpod(keepAlive: true)
WorkerRepository workerRepository(Ref ref) {
  return ApiWorkerRepository(ref.read(dioProvider));
}

@Riverpod(keepAlive: true)
Future<Worker?> workerProfile(Ref ref) async {
  return ref.read(workerRepositoryProvider).getMyWorkerProfile();
}

@riverpod
Future<List<WorkerEarning>> workerEarnings(Ref ref) async {
  return ref.read(workerRepositoryProvider).getMyEarnings();
}

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

@Riverpod(keepAlive: true)
class WorkerOnlineStatusNotifier extends _$WorkerOnlineStatusNotifier {
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
