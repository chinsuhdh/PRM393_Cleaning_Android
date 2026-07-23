import 'package:dio/dio.dart';

import 'error_codes.dart';

enum AppErrorType {
  validation,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  server,
  network,
  unknown,
}

/// The single exception type every repository throws for a failed API call.
///
/// Mirrors the backend's `AppError`/`AppException` shape (code + message +
/// status) so a `DioException` only needs to be translated once, here,
/// instead of every repository hand-rolling its own `throw Exception(...)`.
class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    required this.type,
    this.statusCode,
    this.errors,
    this.cause,
  });

  /// The backend `errorCode`, or a local synthetic code (see [ErrorCodes.network])
  /// for failures that never reached the server.
  final String code;

  /// User-facing message. Already the backend's own (Vietnamese) message when
  /// available; otherwise a generic fallback.
  final String message;

  final AppErrorType type;
  final int? statusCode;

  /// Field validation errors, when the backend populated `errors`.
  final Map<String, List<String>>? errors;

  /// The original [DioException], kept for logging — never shown to the user.
  final Object? cause;

  bool get isCode => code.isNotEmpty;

  factory AppException.fromDioException(DioException error) {
    final response = error.response;
    if (response == null) {
      return AppException(
        code: ErrorCodes.network,
        message: _networkFallbackMessage(error),
        type: AppErrorType.network,
        cause: error,
      );
    }

    final statusCode = response.statusCode;
    final envelope = _envelopeOf(response);

    final message = _stringFrom(envelope?['message']) ??
        _stringFrom(envelope?['error']) ??
        _fallbackMessageFor(statusCode);

    final code = _stringFrom(envelope?['errorCode']) ?? '';

    return AppException(
      code: code,
      message: message,
      type: _typeFromStatus(statusCode),
      statusCode: statusCode,
      errors: _errorsFrom(envelope?['errors']),
      cause: error,
    );
  }

  /// Reads the envelope populated by `ApiEnvelopeInterceptor` — prefers
  /// `response.extra` (already unwrapped on success) and falls back to the
  /// raw error body (still the full envelope on failure responses).
  static Map<Object?, Object?>? _envelopeOf(Response response) {
    final extra = response.extra;
    if (extra.containsKey('errorCode') || extra.containsKey('message')) {
      return extra;
    }
    final data = response.data;
    return data is Map ? data : null;
  }

  static String? _stringFrom(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static Map<String, List<String>>? _errorsFrom(Object? value) {
    if (value is! Map) return null;
    final result = <String, List<String>>{};
    for (final entry in value.entries) {
      final key = entry.key?.toString();
      final rawList = entry.value;
      if (key == null || rawList is! List) continue;
      result[key] = rawList.map((item) => item.toString()).toList();
    }
    return result.isEmpty ? null : result;
  }

  static AppErrorType _typeFromStatus(int? statusCode) => switch (statusCode) {
        400 => AppErrorType.validation,
        401 => AppErrorType.unauthorized,
        403 => AppErrorType.forbidden,
        404 => AppErrorType.notFound,
        409 => AppErrorType.conflict,
        null => AppErrorType.unknown,
        _ => AppErrorType.server,
      };

  static String _fallbackMessageFor(int? statusCode) => switch (statusCode) {
        401 => 'Bạn cần đăng nhập để thực hiện thao tác này.',
        403 => 'Bạn không có quyền thực hiện thao tác này.',
        404 => 'Không tìm thấy dữ liệu yêu cầu.',
        _ => 'Đã xảy ra lỗi, vui lòng thử lại.',
      };

  static String _networkFallbackMessage(DioException error) =>
      switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'Kết nối máy chủ quá hạn, vui lòng thử lại.',
        DioExceptionType.connectionError =>
          'Không thể kết nối máy chủ. Kiểm tra kết nối mạng của bạn.',
        _ => 'Đã xảy ra lỗi, vui lòng thử lại.',
      };

  @override
  String toString() => message;
}
