import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import 'destructive_dialog_actions.dart';

Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Đăng xuất'),
      content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?'),
      actions: [
        DestructiveDialogActions(
          confirmLabel: 'Đăng xuất',
          onConfirm: () => Navigator.pop(context, true),
          onCancel: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );

  if (confirm == true) {
    ref.read(authProvider.notifier).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }
}
