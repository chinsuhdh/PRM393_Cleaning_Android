import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_address.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class UserAddress with _$UserAddress {
  const UserAddress._();

  const factory UserAddress({
    required String id,
    required String label,
    required String addressText,
    double? latitude,
    double? longitude,
    @Default(false) bool isDefault,
  }) = _UserAddress;

  factory UserAddress.fromJson(Map<String, dynamic> json) => UserAddress(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        addressText: json['addressText']?.toString() ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isDefault: json['isDefault'] == true,
      );

  // Intentionally omits `id` — server-assigned, not sent back on create/update.
  Map<String, dynamic> toJson() => {
        'label': label,
        'addressText': addressText,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };
}
