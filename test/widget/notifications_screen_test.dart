import 'package:cleanai/data/repositories/notification_repository.dart';
import 'package:cleanai/ui/notification/notifications_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_test_app.dart';

void main() {
  testWidgets(
    '[WT-FE-NOTIFY-001-01] Màn hình hiển thị trạng thái không có thông báo',
    (tester) async {
      await pumpTestApp(
        tester,
        child: const NotificationsScreen(),
        overrides: [notificationsProvider.overrideWith((ref) async => [])],
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có thông báo nào'), findsOneWidget);
    },
  );
}
