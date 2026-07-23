import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_state.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;
  final Dio dio;

  AuthInterceptor(this.ref, this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final success = await ref.read(authNotifierProvider.notifier).refreshToken();

        if (success) {
          final options = err.requestOptions;
          final newResponse = await dio.fetch(options);
          return handler.resolve(newResponse);
        }
      } catch (e) {
        ref.read(authNotifierProvider.notifier).logout();
      }
    }
    return handler.next(err);
  }
}