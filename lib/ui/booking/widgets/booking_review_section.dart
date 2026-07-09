import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/user_role.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/review.dart';
import '../../../data/repositories/review_repository.dart';
import 'star_rating.dart';

/// Inline review card for a Completed booking: the client rates + comments on the worker (once,
/// enforced server-side); the worker sees the client's review read-only, or an empty state if none
/// yet. Client reviews worker only — there is no reverse flow.
class BookingReviewSection extends ConsumerStatefulWidget {
  const BookingReviewSection({super.key, required this.booking, required this.viewerRole});

  final Booking booking;
  final UserRole viewerRole;

  @override
  ConsumerState<BookingReviewSection> createState() => _BookingReviewSectionState();
}

class _BookingReviewSectionState extends ConsumerState<BookingReviewSection> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit(String workerId) async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao đánh giá.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(reviewRepositoryProvider).createReview(
            bookingId: widget.booking.id,
            revieweeId: workerId,
            rating: _rating,
            comment: _commentController.text.trim(),
          );
      ref.invalidate(bookingReviewProvider((workerUserId: workerId, bookingId: widget.booking.id)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
        );
      }
    } catch (e) {
      debugPrint('[BookingReviewSection] submit failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = widget.booking.worker;
    if (worker == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final reviewAsync =
        ref.watch(bookingReviewProvider((workerUserId: worker.id, bookingId: widget.booking.id)));
    final isWorkerViewer = widget.viewerRole == UserRole.worker;

    return Card(
      key: const ValueKey('booking-review-section'),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: reviewAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Text('Không thể tải đánh giá.'),
          data: (review) {
            if (review != null) {
              return _ReadOnlyReview(review: review, isWorkerViewer: isWorkerViewer);
            }
            if (isWorkerViewer) {
              return const Text(
                'Khách hàng chưa để lại đánh giá.',
                key: ValueKey('review-empty-state'),
                style: TextStyle(color: Colors.grey),
              );
            }
            return _ReviewForm(
              rating: _rating,
              controller: _commentController,
              isSubmitting: _isSubmitting,
              onRatingChanged: (value) => setState(() => _rating = value),
              onSubmit: () => _submit(worker.id),
            );
          },
        ),
      ),
    );
  }
}

class _ReviewForm extends StatelessWidget {
  const _ReviewForm({
    required this.rating,
    required this.controller,
    required this.isSubmitting,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final int rating;
  final TextEditingController controller;
  final bool isSubmitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đánh giá nhân viên', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        StarRatingInput(value: rating, onChanged: onRatingChanged),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('review-comment-field'),
          controller: controller,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Nhận xét của bạn (không bắt buộc)'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('review-submit-button'),
            onPressed: isSubmitting ? null : onSubmit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Gửi đánh giá'),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyReview extends StatelessWidget {
  const _ReadOnlyReview({required this.review, required this.isWorkerViewer});

  final Review review;
  final bool isWorkerViewer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isWorkerViewer ? 'Đánh giá từ khách hàng' : 'Đánh giá của bạn',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        StarRatingDisplay(rating: review.rating),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.comment!),
        ],
      ],
    );
  }
}
