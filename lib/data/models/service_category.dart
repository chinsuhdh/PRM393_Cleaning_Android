import 'package:freezed_annotation/freezed_annotation.dart';

part 'service_category.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class ServiceCategory with _$ServiceCategory {
  const ServiceCategory._();

  const factory ServiceCategory({
    required String id,
    required String name,
    String? iconName,
  }) = _ServiceCategory;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) => ServiceCategory(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Unknown') as String,
        iconName: json['iconName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
      };
}
