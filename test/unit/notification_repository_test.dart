import 'package:cleanai/data/repositories/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test(
    '[UT-FE-NOTIFY-01] getNotifications parses a list with defaults for missing fields',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Notifications',
        (server) => server.reply(200, [
          {'id': 'n1', 'title': 'Đơn mới', 'message': 'Bạn có đơn mới', 'isUnread': true},
          {'id': 'n2'},
        ]),
        data: null,
      );
      final repository = NotificationRepository(harness.dio);

      final items = await repository.getNotifications();

      expect(items, hasLength(2));
      expect(items.first.title, 'Đơn mới');
      expect(items.first.isUnread, isTrue);
      expect(items[1].title, 'Thông báo');
      expect(items[1].isUnread, isFalse);
    },
  );

  test(
    '[UT-FE-NOTIFY-02] getNotifications returns [] on a server error',
    () async {
      final harness = DioTestHarness();
      harness.adapter.onGet(
        '/Notifications',
        (server) => server.reply(500, {'message': 'boom'}),
        data: null,
      );
      final repository = NotificationRepository(harness.dio);

      expect(await repository.getNotifications(), isEmpty);
    },
  );
}
