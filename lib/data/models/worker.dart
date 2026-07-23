import 'package:freezed_annotation/freezed_annotation.dart';

part 'worker.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class Worker with _$Worker {
  const Worker._();

  const factory Worker({
    required String id,
    required String name,
    required double rating,
    @Default('') String distance,
    @Default('') String experience,
    String? avatarUrl,
    @Default(0) int matchPercentage,
    @Default(0) int reviews,
    double? latitude,
    double? longitude,
    @Default(10) double serviceRadiusKm,
    DateTime? suspendedAt,
  }) = _Worker;

  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  bool get isSuspended => suspendedAt != null;

  // Custom fromJson (not generated): several fields have dual-key fallbacks
  // depending on which endpoint served the JSON (worker-search vs. profile-me).
  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        id: (json['id'] ?? json['userId'])?.toString() ?? '',
        name: json['name'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? (json['averageRating'] as num?)?.toDouble() ?? 0,
        distance: json['distance'] as String? ?? '',
        experience: json['experience'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        matchPercentage: json['matchPercentage'] as int? ?? 0,
        reviews: json['reviews'] as int? ?? 0,
        latitude: (json['latitude'] as num?)?.toDouble() ?? (json['currentLat'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble() ?? (json['currentLng'] as num?)?.toDouble(),
        serviceRadiusKm: (json['serviceRadiusKm'] as num?)?.toDouble() ?? 10,
        suspendedAt: DateTime.tryParse(json['suspendedAt']?.toString() ?? '')?.toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'distance': distance,
        'experience': experience,
        'avatarUrl': avatarUrl,
        'matchPercentage': matchPercentage,
        'reviews': reviews,
        'latitude': latitude,
        'longitude': longitude,
        'serviceRadiusKm': serviceRadiusKm,
        'suspendedAt': suspendedAt?.toIso8601String(),
      };
}
