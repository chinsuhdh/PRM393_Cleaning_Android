import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/backend_error_message.dart';

class BookingLoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const BookingLoadError({super.key, required this.error, required this.onRetry});

  bool get _noLongerViewable {
    final e = error;
    if (e is DioException) {
      final status = e.response?.statusCode;
      return status == 403 || status == 404;
    }
    return false;
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
              const Text(
                'Đơn này không còn khả dụng.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
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

    final message = error is DioException
        ? backendMessageFromDioException(error as DioException, fallback: 'Không thể tải dữ liệu đơn.')
        : 'Không thể tải dữ liệu đơn.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
