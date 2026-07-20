import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';
import '../models/review.dart';

abstract class ReviewRepository {
  Future<Review> createReview({
    required String bookingId,
    required String revieweeId,
    required int rating,
    String? comment,
  });
  Future<List<Review>> getReviewsForUser(String userId);
}

class ApiReviewRepository implements ReviewRepository {
  ApiReviewRepository(this._dio);

  final Dio _dio;

  @override
  Future<Review> createReview({
    required String bookingId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        '/Reviews',
        data: {
          'bookingId': bookingId,
          'revieweeId': revieweeId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return Review.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      debugPrint('[ReviewRepository] createReview failed: $error');
      throw Exception(backendMessageFromDioException(error, fallback: 'Không thể gửi đánh giá.'));
    }
  }

  @override
  Future<List<Review>> getReviewsForUser(String userId) async {
    try {
      final response = await _dio.get('/Reviews/user/$userId');
      final raw = response.data;
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().map((json) => Review.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (error) {
      debugPrint('[ReviewRepository] getReviewsForUser failed: $error');
      throw Exception(backendMessageFromDioException(error, fallback: 'Không thể tải đánh giá.'));
    }
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ApiReviewRepository(ref.read(dioProvider));
});

final bookingReviewProvider = FutureProvider.autoDispose
    .family<Review?, ({String workerUserId, String bookingId})>((ref, args) async {
  final reviews = await ref.read(reviewRepositoryProvider).getReviewsForUser(args.workerUserId);
  for (final review in reviews) {
    if (review.bookingId == args.bookingId) return review;
  }
  return null;
});
