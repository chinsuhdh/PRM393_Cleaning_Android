import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cleanai/core/theme/app_theme.dart';
import 'package:cleanai/core/routes/app_router.dart';
import 'package:cleanai/core/theme/theme_provider.dart'; 

void main() {
  runApp(const ProviderScope(child: CleanAIApp()));
}

class CleanAIApp extends ConsumerWidget {
  const CleanAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'CleanAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: currentThemeMode, 
      routerConfig: appRouter,
    );
  }
}