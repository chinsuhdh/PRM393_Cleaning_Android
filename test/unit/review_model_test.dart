import 'package:cleanai/data/models/review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('[UT-FE-REVIEW-MODEL-01] Review.fromJson/toJson round-trip preserves all fields', () {
    final json = {
      'id': 'r1',
      'bookingId': 'b1',
      'reviewerId': 'client-1',
      'revieweeId': 'worker-1',
      'rating': 5,
      'comment': 'Great job!',
      'createdAt': '2026-07-01T10:00:00Z',
    };

    final review = Review.fromJson(json);

    expect(review.id, 'r1');
    expect(review.bookingId, 'b1');
    expect(review.reviewerId, 'client-1');
    expect(review.revieweeId, 'worker-1');
    expect(review.rating, 5);
    expect(review.comment, 'Great job!');
    expect(review.createdAt, DateTime.parse('2026-07-01T10:00:00Z'));

    final roundTripped = Review.fromJson(review.toJson());
    expect(roundTripped.id, review.id);
    expect(roundTripped.rating, review.rating);
    expect(roundTripped.comment, review.comment);
  });

  test('[UT-FE-REVIEW-MODEL-02] A null comment parses to null, not a string', () {
    final review = Review.fromJson({
      'id': 'r2',
      'bookingId': 'b2',
      'reviewerId': 'client-1',
      'revieweeId': 'worker-1',
      'rating': 3,
      'comment': null,
      'createdAt': '2026-07-01T10:00:00Z',
    });

    expect(review.comment, isNull);
  });
}
