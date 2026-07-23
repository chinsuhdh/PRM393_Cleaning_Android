import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';

void showAppearanceBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _AppearanceSheetContent(),
  );
}

class _AppearanceSheetContent extends ConsumerWidget {
  const _AppearanceSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(appThemeModeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Giao diện',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _ThemeOption(
            title: 'Mặc định hệ thống',
            mode: ThemeMode.system,
            currentTheme: currentTheme,
            icon: Icons.settings_suggest_outlined,
          ),
          _ThemeOption(
            title: 'Chế độ sáng',
            mode: ThemeMode.light,
            currentTheme: currentTheme,
            icon: Icons.light_mode_outlined,
          ),
          _ThemeOption(
            title: 'Chế độ tối',
            mode: ThemeMode.dark,
            currentTheme: currentTheme,
            icon: Icons.dark_mode_outlined,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ThemeOption extends ConsumerWidget {
  const _ThemeOption({
    required this.title,
    required this.mode,
    required this.currentTheme,
    required this.icon,
  });

  final String title;
  final ThemeMode mode;
  final ThemeMode currentTheme;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: currentTheme,
      title: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      onChanged: (ThemeMode? value) {
        if (value != null) {
          ref.read(appThemeModeProvider.notifier).set(value);
          Navigator.pop(context);
        }
      },
    );
  }
}
