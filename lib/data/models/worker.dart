class Worker {
  final String id;
  final String name;
  final double rating;
  final String distance;
  final String experience;
  final String? avatarUrl;
  final int matchPercentage;
  final int reviews;
  final double? latitude;
  final double? longitude;

  final DateTime? suspendedAt;

  const Worker({
    required this.id,
    required this.name,
    required this.rating,
    this.distance = '',
    this.experience = '',
    this.avatarUrl,
    this.matchPercentage = 0,
    this.reviews = 0,
    this.latitude,
    this.longitude,
    this.suspendedAt,
  });

  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';

  bool get isSuspended => suspendedAt != null;

  Worker copyWith({
    String? id,
    String? name,
    double? rating,
    String? distance,
    String? experience,
    String? avatarUrl,
    int? matchPercentage,
    int? reviews,
    double? latitude,
    double? longitude,
    DateTime? suspendedAt,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      experience: experience ?? this.experience,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      reviews: reviews ?? this.reviews,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      suspendedAt: suspendedAt ?? this.suspendedAt,
    );
  }

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
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
      suspendedAt: DateTime.tryParse(json['suspendedAt']?.toString() ?? '')?.toLocal(),
    );
  }

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
    'suspendedAt': suspendedAt?.toIso8601String(),
  };
}
