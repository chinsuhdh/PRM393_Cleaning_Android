import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../core/network/api_guard.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/payment.dart';

part 'payment_repository.g.dart';

abstract class PaymentRepository {
  Future<({String paymentId, String paymentUrl})> payNow(String bookingId);
  Future<Payment?> getPaymentByBooking(String bookingId);
  Future<bool> confirmVnpayReturn(String returnUrl);
}

class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(this._dio);

  final Dio _dio;

  @override
  Future<({String paymentId, String paymentUrl})> payNow(String bookingId) => guardApiCall(() async {
    final response = await _dio.post('/Payments', data: {'bookingId': bookingId});
    final data = Map<String, dynamic>.from(response.data as Map);
    return (paymentId: data['paymentId'].toString(), paymentUrl: data['paymentUrl'].toString());
  });

  @override
  Future<Payment?> getPaymentByBooking(String bookingId) async {
    try {
      return await guardApiCall(() async {
        final response = await _dio.get('/Payments/booking/$bookingId');
        if (response.data is Map<String, dynamic>) {
          return Payment.fromJson(response.data as Map<String, dynamic>);
        }
        return null;
      });
    } on AppException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
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

@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(Ref ref) {
  return ApiPaymentRepository(ref.read(dioProvider));
}
