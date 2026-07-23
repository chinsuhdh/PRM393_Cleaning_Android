import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    required String fullName,
    String? avatarUrl,
    String? email,
    String? phoneNumber,
    @Default(false) bool isPhoneVerified,
    @Default(0) int bookingCount,
    @Default(0) int savedCount,
  }) = _Profile;

  String get initials {
    if (fullName.trim().isEmpty) return '?';
    return fullName.trim()[0].toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? 'Người dùng',
        avatarUrl: json['avatarUrl']?.toString(),
        email: json['email']?.toString(),
        phoneNumber: json['phoneNumber']?.toString(),
        isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
        bookingCount: json['bookingCount'] as int? ?? 0,
        savedCount: json['savedCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'email': email,
        'phoneNumber': phoneNumber,
        'isPhoneVerified': isPhoneVerified,
        'bookingCount': bookingCount,
        'savedCount': savedCount,
      };
}
