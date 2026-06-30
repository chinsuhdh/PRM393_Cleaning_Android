import 'package:cleanai/core/network/dio_client.dart';
import 'package:cleanai/ui/home/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';
import '../support/fixture_loader.dart';
import '../support/pump_test_app.dart';

void main() {
  testWidgets(
    '[IT-FE-HOME-001-01] Màn hình Home tải danh mục qua provider và repository',
    (tester) async {
      final harness = DioTestHarness();
      final fixture = await tester.runAsync(
        () => loadJsonFixture('service_categories.json'),
      );
      if (fixture == null) {
        fail('Không thể đọc fixture service_categories.json');
      }

      final categoryName = (fixture as List).single['name'] as String;
      harness.adapter.onGet(
        '/ServiceCatalog/categories',
        (server) => server.reply(200, fixture),
        data: null,
      );

      await pumpTestApp(
        tester,
        child: const HomeScreen(),
        overrides: [dioProvider.overrideWithValue(harness.dio)],
      );
      await _pumpUntilFound(tester, find.text(categoryName));
      expect(find.text(categoryName), findsOneWidget);
      expect(find.text('No categories available'), findsNothing);
    },
  );

  testWidgets(
    '[IT-FE-HOME-001-02] Màn hình Home hiển thị trạng thái rỗng khi API lỗi',
    (tester) async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/ServiceCatalog/categories',
        (server) => server.reply(500, {'message': 'Test failure'}),
        data: null,
      );

      await pumpTestApp(
        tester,
        child: const HomeScreen(),
        overrides: [dioProvider.overrideWithValue(harness.dio)],
      );
      await _pumpUntilFound(tester, find.text('No categories available'));

      expect(find.text('No categories available'), findsOneWidget);
    },
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Không tìm thấy widget mong đợi sau 1 giây: $finder');
}
