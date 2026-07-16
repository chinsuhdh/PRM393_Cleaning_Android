import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/backend_error_message.dart';
import '../../core/network/dio_client.dart';

typedef ChatBotReply = ({String sessionId, String reply, bool success});

class AiHistoryMessage {
  final String senderType;
  final String message;
  final DateTime createdAt;

  AiHistoryMessage({
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  factory AiHistoryMessage.fromJson(Map<String, dynamic> json) =>
      AiHistoryMessage(
        senderType: json['senderType']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  bool get isUser => senderType == 'User';
}

class AiRepository {
  AiRepository(this._dio);

  final Dio _dio;

  Future<ChatBotReply> chatWithBot(String sessionId, String message) async {
    try {
      final response = await _dio.post(
        '/Ai/chat',
        data: {"sessionId": sessionId, "message": message},
      );
      final data = response.data as Map;
      return (
        sessionId: data['sessionId']?.toString() ?? sessionId,
        reply: data['reply']?.toString() ?? 'AI không có phản hồi.',
        success: data['success'] == true,
      );
    } on DioException catch (e) {
      debugPrint('[AiRepository] chatWithBot failed: $e');
      if (e.response?.statusCode == 429) {
        throw Exception(
          'Bạn đã gửi quá nhiều tin nhắn, vui lòng thử lại sau ít phút.',
        );
      }
      throw Exception(
        backendMessageFromDioException(e, fallback: 'Lỗi kết nối đến AI Server.'),
      );
    }
  }

  Future<List<AiHistoryMessage>> getHistory(String sessionId) async {
    try {
      final response = await _dio.get('/Ai/history/$sessionId');
      final raw = response.data;
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(AiHistoryMessage.fromJson)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[AiRepository] getHistory failed: $e');
      return [];
    }
  }

  Future<void> clearHistory(String sessionId) async {
    try {
      await _dio.delete('/Ai/history/$sessionId');
    } on DioException catch (e) {
      debugPrint('[AiRepository] clearHistory failed: $e');
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiRepository(ref.read(dioProvider)),
);
