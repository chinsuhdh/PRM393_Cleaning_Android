import 'package:cleanai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '[E2E-FOUNDATION-001-01] Ứng dụng khởi động với cấu hình kiểm thử',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: CleanAIApp()));
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}
