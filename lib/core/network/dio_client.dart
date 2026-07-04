import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_envelope.dart';

class DioClient {
  DioClient._();

  static final Dio _legacyInstance = create();

  @Deprecated('Inject dioProvider instead.')
  static Dio get instance => _legacyInstance;

  static Dio create({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl:
            baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://127.0.0.1:5000/api',
            ),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(ApiEnvelopeInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }
    return dio;
  }

  static void setAuthToken(Dio dio, String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuthToken(Dio dio) {
    dio.options.headers.remove('Authorization');
  }
}

final dioProvider = Provider<Dio>((ref) => DioClient.instance);
