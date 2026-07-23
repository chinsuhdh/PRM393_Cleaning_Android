import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/destructive_dialog_actions.dart';
import 'chat_notifier.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/suggested_questions.dart';

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
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
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
          DestructiveDialogActions(
            confirmLabel: 'Xóa',
            onConfirm: () => Navigator.pop(dialogContext, true),
            onCancel: () => Navigator.pop(dialogContext, false),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(chatNotifierProvider.notifier).clearConversation();
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
    final chatState = ref.watch(chatNotifierProvider);
    final theme = Theme.of(context);

    ref.listen(chatNotifierProvider, (prev, next) {
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
                  return const TypingBubble();
                }
                return ChatMessageBubble(
                  message: chatState.messages[i],
                  onRetry: (text) => _send(text),
                );
              },
            ),
          ),
          if (chatState.messages.length <= 1 && !chatState.isAiTyping)
            SuggestedQuestions(onSelected: _send),
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
                    enabled: !chatState.isAiTyping,
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
