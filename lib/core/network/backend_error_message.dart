import 'package:dio/dio.dart';

String backendMessageFromResponse(
  Object? responseData, {
  required String fallback,
}) {
  if (responseData is Map) {
    final message = responseData['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final error = responseData['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }
  }

  if (responseData is String && responseData.trim().isNotEmpty) {
    return responseData.trim();
  }

  return fallback;
}

String backendMessageFromDioException(
  DioException error, {
  required String fallback,
}) {
  return backendMessageFromResponse(
    error.response?.data,
    fallback: fallback,
  );
}
