import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../models/service_category.dart';

class ServiceCatalogRepository {
  ServiceCatalogRepository(this._dio);

  final Dio _dio;

  Future<List<ServiceCategory>> getCategories() async {
    try {
      final response = await _dio.get('/ServiceCatalog/categories');
      final raw = response.data;
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(ServiceCategory.fromJson)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final serviceCatalogRepositoryProvider = Provider<ServiceCatalogRepository>((
  ref,
) {
  return ServiceCatalogRepository(ref.read(dioProvider));
});

final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final repo = ref.read(serviceCatalogRepositoryProvider);
  return repo.getCategories();
});
