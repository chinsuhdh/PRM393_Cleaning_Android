import 'package:freezed_annotation/freezed_annotation.dart';

part 'review.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class Review with _$Review {
  const Review._();

  const factory Review({
    required String id,
    required String bookingId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? comment,
    required DateTime createdAt,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'].toString(),
        bookingId: json['bookingId'].toString(),
        reviewerId: json['reviewerId'].toString(),
        revieweeId: json['revieweeId'].toString(),
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'reviewerId': reviewerId,
        'revieweeId': revieweeId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };
}
