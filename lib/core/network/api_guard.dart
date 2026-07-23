import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Runs [call] and translates any [DioException] into an [AppException].
///
/// Centralizes the translation every repository used to hand-roll as
/// `try { ... } on DioException catch (e) { throw Exception(backendMessageFromDioException(e, ...)) }`.
Future<T> guardApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (error) {
    throw AppException.fromDioException(error);
  }
}
