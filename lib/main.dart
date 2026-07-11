import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Đã sửa: Sử dụng package import thay vì import tương đối
import 'package:cleanai/core/theme/app_theme.dart';
import 'package:cleanai/core/routes/app_router.dart';
import 'package:cleanai/core/theme/theme_provider.dart'; // Import Provider giao diện

void main() {
  runApp(const ProviderScope(child: CleanAIApp()));
}

class CleanAIApp extends ConsumerWidget { // Đổi thành ConsumerWidget
  const CleanAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lắng nghe trạng thái giao diện hiện tại
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CleanAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: currentThemeMode, // Áp dụng trạng thái theme vào đây
      routerConfig: appRouter,
    );
  }
}