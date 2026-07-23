import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_item.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    required String id,
    required String title,
    required String message,
    @Default(false) bool isUnread,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Thông báo',
        message: json['message']?.toString() ?? '',
        isUnread: json['isUnread'] == true,
      );
}
