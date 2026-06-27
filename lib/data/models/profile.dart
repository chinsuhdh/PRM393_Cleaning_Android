class Profile {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? email;
  final String? phoneNumber;
  final bool? isPhoneVerified; // [THÊM MỚI]

  Profile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.email,
    this.phoneNumber,
    this.isPhoneVerified, // [THÊM MỚI]
  });

  String get initials {
    if (fullName.trim().isEmpty) return '?';
    return fullName.trim()[0].toUpperCase();
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Người dùng',
      avatarUrl: json['avatarUrl']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false, // [THÊM MỚI] Đọc từ JSON
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'avatarUrl': avatarUrl,
    'email': email,
    'phoneNumber': phoneNumber,
    'isPhoneVerified': isPhoneVerified,
  };
}