import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';

/// Simulated VNPay gateway: linking always succeeds server-side as long as the value is non-empty;
/// the actual charge happens automatically on the backend when the worker finishes the job.
abstract class PaymentRepository {
  /// The client's linked VNPay account, or null when not linked yet.
  Future<String?> getVnpayAccount();
  Future<String?> linkVnpayAccount(String vnpayAccount);
}

class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(this._dio);

  final Dio _dio;

  @override
  Future<String?> getVnpayAccount() async {
    try {
      final response = await _dio.get('/Payments/vnpay-account');
      return (response.data as Map?)?['vnpayAccount'] as String?;
    } on DioException catch (error) {
      throw Exception(
        backendMessageFromDioException(error, fallback: 'Không thể tải thông tin VNPay.'),
      );
    }
  }

  @override
  Future<String?> linkVnpayAccount(String vnpayAccount) async {
    try {
      final response = await _dio.put(
        '/Payments/vnpay-account',
        data: {'vnpayAccount': vnpayAccount},
      );
      return (response.data as Map?)?['vnpayAccount'] as String?;
    } on DioException catch (error) {
      throw Exception(
        backendMessageFromDioException(error, fallback: 'Không thể liên kết tài khoản VNPay.'),
      );
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return ApiPaymentRepository(ref.read(dioProvider));
});
