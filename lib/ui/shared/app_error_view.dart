import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/app_exception.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  final Object error;
  final VoidCallback? onRetry;

  bool get _noLongerViewable {
    final e = error;
    return e is AppException &&
        (e.type == AppErrorType.forbidden || e.type == AppErrorType.notFound);
  }

  String get _message {
    final e = error;
    if (e is AppException) return e.message;
    return 'Đã xảy ra lỗi, vui lòng thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    if (_noLongerViewable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            Text(_message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}
