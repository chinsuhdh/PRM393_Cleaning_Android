import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';

import '../../core/network/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/chat_message.dart';

part 'ai_repository.g.dart';

typedef ChatBotReply = ({
  String sessionId,
  String reply,
  bool success,
  List<ChatSuggestion> suggestions,
});

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
      final rawSuggestions = data['suggestions'];
      final suggestions = <ChatSuggestion>[];
      if (rawSuggestions is List) {
        for (final item in rawSuggestions) {
          if (item is Map && item['label'] != null && item['route'] != null) {
            suggestions.add((
              label: item['label'].toString(),
              route: item['route'].toString(),
            ));
          }
        }
      }
      return (
        sessionId: data['sessionId']?.toString() ?? sessionId,
        reply: data['reply']?.toString() ?? 'AI không có phản hồi.',
        success: data['success'] == true,
        suggestions: suggestions,
      );
    } on DioException catch (e) {
      debugPrint('[AiRepository] chatWithBot failed: $e');
      if (e.response?.statusCode == 429) {
        throw AppException(
          code: 'AI_RATE_LIMITED',
          message: 'Bạn đã gửi quá nhiều tin nhắn, vui lòng thử lại sau ít phút.',
          type: AppErrorType.conflict,
          statusCode: 429,
          cause: e,
        );
      }
      throw AppException.fromDioException(e);
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

@Riverpod(keepAlive: true)
AiRepository aiRepository(Ref ref) => AiRepository(ref.read(dioProvider));
