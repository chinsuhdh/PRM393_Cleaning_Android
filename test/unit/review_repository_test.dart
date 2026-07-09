import 'package:cleanai/data/repositories/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dio_test_harness.dart';

void main() {
  test('[UT-FE-REVIEW-01] createReview posts the expected payload and parses the returned review', () async {
    final harness = DioTestHarness();
    harness.adapter.onPost(
      '/Reviews',
      (server) => server.reply(200, {
        'success': true,
        'message': 'ok',
        'data': {
          'id': 'r1',
          'bookingId': 'b1',
          'reviewerId': 'client-1',
          'revieweeId': 'worker-1',
          'rating': 5,
          'comment': 'Great job!',
          'createdAt': '2026-07-01T10:00:00Z',
        },
        'errorCode': null,
      }),
      data: {'bookingId': 'b1', 'revieweeId': 'worker-1', 'rating': 5, 'comment': 'Great job!'},
    );
    final repository = ApiReviewRepository(harness.dio);

    final review = await repository.createReview(
      bookingId: 'b1',
      revieweeId: 'worker-1',
      rating: 5,
      comment: 'Great job!',
    );

    expect(review.id, 'r1');
    expect(review.rating, 5);
  });

  test('[UT-FE-REVIEW-02] createReview surfaces the backend\'s business-rule message on a 400', () async {
    final harness = DioTestHarness();
    harness.adapter.onPost(
      '/Reviews',
      (server) => server.reply(400, {'message': 'Booking chưa hoàn thành.'}),
      data: {'bookingId': 'b1', 'revieweeId': 'worker-1', 'rating': 5},
    );
    final repository = ApiReviewRepository(harness.dio);

    expect(
      () => repository.createReview(bookingId: 'b1', revieweeId: 'worker-1', rating: 5),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Booking chưa hoàn thành.'),
        ),
      ),
    );
  });

  test('[UT-FE-REVIEW-03] getReviewsForUser parses a list of reviews', () async {
    final harness = DioTestHarness();
    harness.adapter.onGet(
      '/Reviews/user/worker-1',
      (server) => server.reply(200, {
        'success': true,
        'message': 'ok',
        'data': [
          {
            'id': 'r1',
            'bookingId': 'b1',
            'reviewerId': 'client-1',
            'revieweeId': 'worker-1',
            'rating': 4,
            'comment': null,
            'createdAt': '2026-07-01T10:00:00Z',
          },
        ],
        'errorCode': null,
      }),
      data: null,
    );
    final repository = ApiReviewRepository(harness.dio);

    final reviews = await repository.getReviewsForUser('worker-1');

    expect(reviews, hasLength(1));
    expect(reviews.first.bookingId, 'b1');
    expect(reviews.first.rating, 4);
  });
}
