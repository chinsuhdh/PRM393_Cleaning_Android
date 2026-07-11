import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;
  final Dio dio;

  AuthInterceptor(this.ref, this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Nếu gặp lỗi 401 (Unauthorized)
    if (err.response?.statusCode == 401) {
      try {
        // 1. Gọi API Refresh Token
        // Bạn cần viết thêm hàm refreshToken trong AuthNotifier ở auth_repository.dart
        final success = await ref.read(authProvider.notifier).refreshToken();

        if (success) {
          // 2. Nếu refresh thành công, retry lại request cũ
          final options = err.requestOptions;
          final newResponse = await dio.fetch(options);
          return handler.resolve(newResponse);
        }
      } catch (e) {
        // Nếu refresh cũng lỗi, logout user
        ref.read(authProvider.notifier).logout();
      }
    }
    return handler.next(err);
  }
}