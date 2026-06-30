import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

class DioTestHarness {
  DioTestHarness()
    : dio = Dio(BaseOptions(baseUrl: 'http://cleanai.test/api')) {
    adapter = DioAdapter(dio: dio);
  }

  final Dio dio;
  late final DioAdapter adapter;
}
