import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import '../../core/network/api_guard.dart';
import '../../core/network/dio_client.dart';

part 'chat_repository.g.dart';

class ChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String).toLocal() : null,
    );
  }
}

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  Future<List<ChatMessage>> getMessages(String bookingId) => guardApiCall(() async {
    final response = await _dio.get('/bookings/$bookingId/messages');
    final data = response.data as List;
    return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  });

  Future<ChatMessage> sendMessage(String bookingId, String content) => guardApiCall(() async {
    final response = await _dio.post('/bookings/$bookingId/messages', data: {
      'content': content,
    });
    return ChatMessage.fromJson(response.data as Map<String, dynamic>);
  });

  Future<void> markAsRead(String bookingId) => guardApiCall(() async {
    await _dio.post('/bookings/$bookingId/messages/read');
  });
}

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  return ChatRepository(ref.read(dioProvider));
}
