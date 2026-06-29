import 'package:cleanai/data/repositories/service_catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';
import '../support/fixture_loader.dart';

void main() {
  test(
    '[UT-FE-SERVICE-001-01] Repository đọc danh mục dịch vụ từ API',
    () async {
      final harness = DioTestHarness();
      final fixture = await loadJsonFixture('service_categories.json');
      harness.adapter.onGet(
        '/ServiceCatalog/categories',
        (server) => server.reply(200, fixture),
        data: null,
      );
      final repository = ServiceCatalogRepository(harness.dio);

      final categories = await repository.getCategories();

      expect(categories, hasLength(1));
      expect(categories.single.name, 'Dọn dẹp Chung cư');
    },
  );
}
