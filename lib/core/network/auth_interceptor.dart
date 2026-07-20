import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;
  final Dio dio;

  AuthInterceptor(this.ref, this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final success = await ref.read(authProvider.notifier).refreshToken();

        if (success) {
          final options = err.requestOptions;
          final newResponse = await dio.fetch(options);
          return handler.resolve(newResponse);
        }
      } catch (e) {
        ref.read(authProvider.notifier).logout();
      }
    }
    return handler.next(err);
  }
}