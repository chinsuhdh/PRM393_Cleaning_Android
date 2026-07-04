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

String? backendErrorCodeFromDioException(DioException error) {
  final extra = error.response?.extra;
  if (extra != null && extra['errorCode'] is String) {
    return extra['errorCode'] as String;
  }

  final data = error.response?.data;
  if (data is Map && data['errorCode'] is String) {
    return data['errorCode'] as String;
  }

  return null;
}
