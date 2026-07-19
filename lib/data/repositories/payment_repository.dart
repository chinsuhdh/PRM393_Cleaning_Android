import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';
import '../models/payment.dart';

abstract class PaymentRepository {
  Future<({String paymentId, String paymentUrl})> payNow(String bookingId);
  Future<Payment?> getPaymentByBooking(String bookingId);
  Future<bool> confirmVnpayReturn(String returnUrl);
}

class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(this._dio);

  final Dio _dio;

  @override
  Future<({String paymentId, String paymentUrl})> payNow(String bookingId) async {
    try {
      final response = await _dio.post('/Payments', data: {'bookingId': bookingId});
      final data = Map<String, dynamic>.from(response.data as Map);
      return (paymentId: data['paymentId'].toString(), paymentUrl: data['paymentUrl'].toString());
    } on DioException catch (error) {
      debugPrint('[PaymentRepository] payNow failed: $error');
      throw Exception(
        backendMessageFromDioException(error, fallback: 'Không thể bắt đầu thanh toán VNPay.'),
      );
    }
  }

  @override
  Future<Payment?> getPaymentByBooking(String bookingId) async {
    try {
      final response = await _dio.get('/Payments/booking/$bookingId');
      if (response.data is Map<String, dynamic>) {
        return Payment.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      debugPrint('[PaymentRepository] getPaymentByBooking failed: $error');
      throw Exception(
        backendMessageFromDioException(error, fallback: 'Không thể tải thông tin thanh toán.'),
      );
    }
  }

  @override
  Future<bool> confirmVnpayReturn(String returnUrl) async {
    try {
      final params = Uri.parse(returnUrl).queryParameters;
      final response = await _dio.get('/Payments/vnpay-confirm', queryParameters: params);
      final data = Map<String, dynamic>.from(response.data as Map);
      return data['success'] == true;
    } on DioException catch (error) {
      debugPrint('[PaymentRepository] confirmVnpayReturn failed: $error');
      return false;
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return ApiPaymentRepository(ref.read(dioProvider));
});
