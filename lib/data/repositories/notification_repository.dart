import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/network/dio_client.dart';
import '../models/notification_item.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<List<NotificationItem>> getNotifications() async {
    try {
      final response = await _dio.get('/Notifications');
      final raw = response.data;
      if (raw is List) {
        return raw.whereType<Map<String, dynamic>>().map(NotificationItem.fromJson).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[NotificationRepository] getNotifications failed: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.patch('/Notifications/$notificationId/read');
    } catch (e) {
      debugPrint('[NotificationRepository] markAsRead failed: $e');
    }
  }
}

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepository(ref.read(dioProvider));
}

@riverpod
Future<List<NotificationItem>> notifications(Ref ref) async {
  return ref.read(notificationRepositoryProvider).getNotifications();
}
