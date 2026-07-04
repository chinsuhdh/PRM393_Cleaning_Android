import 'package:dio/dio.dart';

class ApiEnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (_isEnvelope(data)) {
      final envelope = data as Map;
      response.extra = {
        ...response.extra,
        'message': envelope['message'],
        'errorCode': envelope['errorCode'],
        'errors': envelope['errors'],
      };
      response.data = envelope['data'];
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    if (_isEnvelope(data)) {
      final envelope = data as Map;
      err.response!.extra = {
        ...err.response!.extra,
        'message': envelope['message'],
        'errorCode': envelope['errorCode'],
        'errors': envelope['errors'],
      };
    }
    handler.next(err);
  }

  bool _isEnvelope(Object? data) {
    return data is Map &&
        data['success'] is bool &&
        data.containsKey('data');
  }
}
