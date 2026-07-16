import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/ai_repository.dart';

const _sessionPrefsKey = 'ai_chat_session_id';

const _suggestedQuestions = [
  'Chính sách hủy đặt lịch?',
  'Có những dịch vụ nào?',
  'Cách ghép nhân viên?',
  'Thanh toán như thế nào?',
];

final _greeting = ChatMessage(
  id: '0',
  text: "Xin chào! Mình là CleanAI trợ lý ảo. Bạn cần giúp gì hôm nay? 😊",
  isUser: false,
);

// State quản lý danh sách tin nhắn và trạng thái loading
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

class ChatNotifier extends StateNotifier<ChatState> {
  final AiRepository _aiRepo;

  ChatNotifier(this._aiRepo)
    : super(ChatState(messages: [_greeting], sessionId: _generateSessionId())) {
    _restoreSession();
  }

  static String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  // Phiên trò chuyện được lưu cục bộ để lịch sử không bị mất khi khởi động lại app.
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
        isError: !reply.success,
        retryText: reply.success ? null : text,
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
    state = ChatState(messages: [_greeting], sessionId: newSessionId);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.read(aiRepositoryProvider));
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? presetText]) {
    final text = presetText ?? _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa lịch sử trò chuyện?'),
        content: const Text('Toàn bộ tin nhắn trong cuộc trò chuyện này sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(chatProvider.notifier).clearConversation();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final theme = Theme.of(context);

    // Tự động cuộn khi có tin nhắn mới
    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: kPrimaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: kPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CleanAI Assistant',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  'Luôn sẵn sàng hỗ trợ bạn',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Xóa lịch sử trò chuyện',
            onPressed: chatState.messages.length <= 1 ? null : _confirmClear,
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.isLoadingHistory) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount:
                  chatState.messages.length + (chatState.isAiTyping ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == chatState.messages.length) {
                  return const _TypingBubble();
                }
                return _MessageBubble(
                  message: chatState.messages[i],
                  onRetry: (text) => _send(text),
                );
              },
            ),
          ),
          if (chatState.messages.length <= 1 && !chatState.isAiTyping)
            _SuggestedQuestions(onSelected: _send),
          // Input bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !chatState.isAiTyping, // Khóa input khi AI đang gõ
                    decoration: InputDecoration(
                      hintText: chatState.isAiTyping
                          ? 'AI đang suy nghĩ...'
                          : 'Hỏi về dịch vụ, giá cả, chính sách...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: chatState.isAiTyping ? null : () => _send(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: chatState.isAiTyping ? Colors.grey : kPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedQuestions extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const _SuggestedQuestions({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(_suggestedQuestions[i]),
          onPressed: () => onSelected(_suggestedQuestions[i]),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<String> onRetry;
  const _MessageBubble({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: message.isError ? Colors.red.shade100 : kPrimaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: message.isError
                    ? Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 16)
                    : const Text(
                        'AI',
                        style: TextStyle(
                          color: kOnPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? kPrimary
                        : message.isError
                            ? Colors.red.shade50
                            : theme.colorScheme.surfaceContainerHighest,
                    border: message.isError ? Border.all(color: Colors.red.shade200) : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : message.isError
                              ? Colors.red.shade900
                              : theme.colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                if (message.isError && message.retryText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: TextButton.icon(
                      onPressed: () => onRetry(message.retryText!),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Thử lại'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
