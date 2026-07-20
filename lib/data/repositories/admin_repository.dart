import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(dioProvider));
});

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getDashboardStats();
});

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('/Admin/dashboard-stats');

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Không thể tải dữ liệu thống kê: $e');
    }
  }
}
