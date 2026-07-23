import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/chat_message.dart';
import '../../../data/repositories/ai_repository.dart';

part 'chat_notifier.g.dart';

const _sessionPrefsKey = 'ai_chat_session_id';

final greetingMessage = ChatMessage(
  id: '0',
  text: "Xin chào! Mình là CleanAI trợ lý ảo. Bạn cần giúp gì hôm nay? 😊",
  isUser: false,
  timestamp: DateTime.now(),
);

class ChatState {
  final List<ChatMessage> messages;
  final bool isAiTyping;
  final bool isLoadingHistory;
  final String sessionId;

  ChatState({
    required this.messages,
    this.isAiTyping = false,
    this.isLoadingHistory = false,
    required this.sessionId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isAiTyping,
    bool? isLoadingHistory,
    String? sessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  late final AiRepository _aiRepo;

  @override
  ChatState build() {
    _aiRepo = ref.read(aiRepositoryProvider);
    _restoreSession();
    return ChatState(messages: [greetingMessage], sessionId: _generateSessionId());
  }

  static String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedSessionId = prefs.getString(_sessionPrefsKey);
    if (storedSessionId == null) {
      await prefs.setString(_sessionPrefsKey, state.sessionId);
      return;
    }

    state = state.copyWith(sessionId: storedSessionId, isLoadingHistory: true);
    final history = await _aiRepo.getHistory(storedSessionId);
    if (history.isEmpty) {
      state = state.copyWith(isLoadingHistory: false);
      return;
    }

    state = state.copyWith(
      messages: history
          .map(
            (m) => ChatMessage(
              id: '${m.createdAt.microsecondsSinceEpoch}-${m.isUser}',
              text: m.message,
              isUser: m.isUser,
              timestamp: m.createdAt,
            ),
          )
          .toList(),
      isLoadingHistory: false,
    );
  }

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(
      id: DateTime.now().toIso8601String(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isAiTyping: true,
    );

    try {
      final reply = await _aiRepo.chatWithBot(state.sessionId, text);
      final aiMsg = ChatMessage(
        id: DateTime.now().toIso8601String(),
        text: reply.reply,
        isUser: false,
        timestamp: DateTime.now(),
        isError: !reply.success,
        retryText: reply.success ? null : text,
        suggestions: reply.suggestions,
      );
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isAiTyping: false,
        sessionId: reply.sessionId,
      );
    } catch (e) {
      final errorMsg = ChatMessage(
        id: DateTime.now().toIso8601String(),
        text: 'Không thể kết nối đến máy chủ. Vui lòng thử lại.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
        retryText: text,
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isAiTyping: false,
      );
    }
  }

  Future<void> clearConversation() async {
    await _aiRepo.clearHistory(state.sessionId);
    final newSessionId = _generateSessionId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionPrefsKey, newSessionId);
    state = ChatState(messages: [greetingMessage], sessionId: newSessionId);
  }
}
