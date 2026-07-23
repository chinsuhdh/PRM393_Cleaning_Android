import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';
import '../models/service_category.dart';

part 'service_catalog_repository.g.dart';

class ServiceCatalogRepository {
  ServiceCatalogRepository(this._dio);

  final Dio _dio;

  Future<List<ServiceCategory>> getCategories() => guardApiCall(() async {
    final response = await _dio.get('/ServiceCatalog/categories');
    final raw = response.data;
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(ServiceCategory.fromJson).toList();
  });

  Future<List<Map<String, dynamic>>> getServicesByCategory(String categoryId) => guardApiCall(() async {
    final response = await _dio.get('/ServiceCatalog/categories/$categoryId/services');
    return List<Map<String, dynamic>>.from(response.data as List);
  });

  Future<Map<String, dynamic>> getServiceById(String id) async {
    try {
      final response = await _dio.get('/ServiceCatalog/services/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      final res = await _dio.get('/ServiceCatalog/services');
      final list = List<Map<String, dynamic>>.from(res.data as List);
      return list.firstWhere((s) => s['id'] == id);
    }
  }
}

@Riverpod(keepAlive: true)
ServiceCatalogRepository serviceCatalogRepository(Ref ref) {
  return ServiceCatalogRepository(ref.read(dioProvider));
}

@Riverpod(keepAlive: true)
Future<List<ServiceCategory>> categories(Ref ref) async {
  final repo = ref.read(serviceCatalogRepositoryProvider);
  return repo.getCategories();
}

@riverpod
Future<Map<String, dynamic>> serviceDetail(Ref ref, String id) async {
  return ref.read(serviceCatalogRepositoryProvider).getServiceById(id);
}
