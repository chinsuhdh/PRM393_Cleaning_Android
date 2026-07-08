import 'package:cleanai/core/constants/user_role.dart';
import 'package:cleanai/data/models/booking.dart';
import 'package:cleanai/data/models/review.dart';
import 'package:cleanai/data/models/worker.dart';
import 'package:cleanai/data/repositories/review_repository.dart';
import 'package:cleanai/ui/booking/widgets/booking_review_section.dart';
import 'package:cleanai/ui/booking/widgets/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const worker = Worker(id: 'worker-1', name: 'John', rating: 4.5);
  const booking = Booking(
    id: 'booking-1', serviceName: 'Home Cleaning', date: '', time: '',
    price: 200000, status: 'Completed', bookingType: 'Immediate', worker: worker,
  );

  Widget wrap(Widget child, {required ReviewRepository repository}) {
    return ProviderScope(
      overrides: [reviewRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets(
    '[WT-FE-REVIEW-01] Client with no existing review sees the star input and submit button',
    (tester) async {
      final repository = _FakeReviewRepository(existingReviews: const []);
      await tester.pumpWidget(wrap(
        const BookingReviewSection(booking: booking, viewerRole: UserRole.client),
        repository: repository,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(StarRatingInput), findsOneWidget);
      expect(find.byKey(const ValueKey('review-submit-button')), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-REVIEW-02] Submitting without selecting a rating shows a validation message and does not call the repository',
    (tester) async {
      final repository = _FakeReviewRepository(existingReviews: const []);
      await tester.pumpWidget(wrap(
        const BookingReviewSection(booking: booking, viewerRole: UserRole.client),
        repository: repository,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('review-submit-button')));
      await tester.pump();

      expect(repository.createCalls, isEmpty);
      expect(find.text('Vui lòng chọn số sao đánh giá.'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-REVIEW-03] Selecting a rating and submitting calls createReview with the worker as revieweeId, then shows the read-only view',
    (tester) async {
      final repository = _FakeReviewRepository(existingReviews: const []);
      await tester.pumpWidget(wrap(
        const BookingReviewSection(booking: booking, viewerRole: UserRole.client),
        repository: repository,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('star-input-4')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('review-submit-button')));
      await tester.pumpAndSettle();

      expect(repository.createCalls, hasLength(1));
      expect(repository.createCalls.first.bookingId, 'booking-1');
      expect(repository.createCalls.first.revieweeId, 'worker-1');
      expect(repository.createCalls.first.rating, 4);
      expect(find.byType(StarRatingDisplay), findsOneWidget);
      expect(find.byKey(const ValueKey('review-submit-button')), findsNothing);
    },
  );

  testWidgets(
    '[WT-FE-REVIEW-04] Client with an existing review sees it read-only, not the input',
    (tester) async {
      final repository = _FakeReviewRepository(existingReviews: [
        Review(
          id: 'r1', bookingId: 'booking-1', reviewerId: 'client-1', revieweeId: 'worker-1',
          rating: 5, comment: 'Excellent!', createdAt: DateTime(2026, 7, 1),
        ),
      ]);
      await tester.pumpWidget(wrap(
        const BookingReviewSection(booking: booking, viewerRole: UserRole.client),
        repository: repository,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(StarRatingInput), findsNothing);
      expect(find.byType(StarRatingDisplay), findsOneWidget);
      expect(find.text('Excellent!'), findsOneWidget);
    },
  );

  testWidgets(
    '[WT-FE-REVIEW-05] Worker with no review yet sees an empty state, no input control',
    (tester) async {
      final repository = _FakeReviewRepository(existingReviews: const []);
      await tester.pumpWidget(wrap(
        const BookingReviewSection(booking: booking, viewerRole: UserRole.worker),
        repository: repository,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('review-empty-state')), findsOneWidget);
      expect(find.byType(StarRatingInput), findsNothing);
    },
  );

  testWidgets(
    '[WT-FE-REVIEW-06] Worker with an existing review sees the client\'s review read-only',
    (tester) async {
      final repository = _FakeReviewRepository(existingReviews: [
        Review(
          id: 'r1', bookingId: 'booking-1', reviewerId: 'client-1', revieweeId: 'worker-1',
          rating: 3, comment: null, createdAt: DateTime(2026, 7, 1),
        ),
      ]);
      await tester.pumpWidget(wrap(
        const BookingReviewSection(booking: booking, viewerRole: UserRole.worker),
        repository: repository,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Đánh giá từ khách hàng'), findsOneWidget);
      expect(find.byType(StarRatingDisplay), findsOneWidget);
    },
  );
}

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository({required List<Review> existingReviews}) : _existingReviews = List.of(existingReviews);
  final List<Review> _existingReviews;
  final List<({String bookingId, String revieweeId, int rating, String? comment})> createCalls = [];

  @override
  Future<Review> createReview({
    required String bookingId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    createCalls.add((bookingId: bookingId, revieweeId: revieweeId, rating: rating, comment: comment));
    final review = Review(
      id: 'new-review', bookingId: bookingId, reviewerId: 'client-1', revieweeId: revieweeId,
      rating: rating, comment: comment, createdAt: DateTime(2026, 7, 1),
    );
    _existingReviews.add(review);
    return review;
  }

  @override
  Future<List<Review>> getReviewsForUser(String userId) async {
    return _existingReviews.where((r) => r.revieweeId == userId).toList();
  }
}
