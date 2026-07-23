import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';
import '../models/review.dart';

part 'review_repository.g.dart';

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
  }) =>
  guardApiCall(() async {
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
  });

  @override
  Future<List<Review>> getReviewsForUser(String userId) => guardApiCall(() async {
    final response = await _dio.get('/Reviews/user/$userId');
    final raw = response.data;
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(Review.fromJson).toList();
  });
}

@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) {
  return ApiReviewRepository(ref.read(dioProvider));
}

@riverpod
Future<Review?> bookingReview(
  Ref ref,
  ({String workerUserId, String bookingId}) args,
) async {
  final reviews = await ref.read(reviewRepositoryProvider).getReviewsForUser(args.workerUserId);
  for (final review in reviews) {
    if (review.bookingId == args.bookingId) return review;
  }
  return null;
}
