import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/dispatch_hub_service.dart';
import '../booking/booking_detail_screen.dart'; // For bookingDetailProvider

class BookingChatScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingChatScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends ConsumerState<BookingChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSignalR();
  }

  Future<void> _loadMessages() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final messages = await repo.getMessages(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
      _markAsRead();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupSignalR() {
    final client = ref.read(dispatchHubClientProvider);
    client.onReceiveMessage((msg) {
      if (!mounted) return;
      final newMsg = ChatMessage.fromJson(msg);
      if (newMsg.bookingId != widget.bookingId) return;

      // Our own sent messages are already rendered via the optimistic add in
      // _sendMessage(); relying on this echo too raced with that HTTP response
      // and could show the message twice.
      final currentUserId = ref.read(authProvider).userId;
      if (newMsg.senderId == currentUserId) return;

      setState(() {
        if (!_messages.any((m) => m.id == newMsg.id)) {
          _messages.add(newMsg);
        }
      });
      _scrollToBottom();
      _markAsRead();
    });
  }

  void _markAsRead() {
    ref.read(chatRepositoryProvider).markAsRead(widget.bookingId).catchError((_) {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final repo = ref.read(chatRepositoryProvider);
    final userId = ref.read(authProvider).userId;

    // Optimistic UI update
    final optimisticMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      bookingId: widget.bookingId,
      senderId: userId ?? '',
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(optimisticMsg);
    });
    _scrollToBottom();

    try {
      final realMsg = await repo.sendMessage(widget.bookingId, text);
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == optimisticMsg.id);
        if (index != -1) {
          _messages[index] = realMsg;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == optimisticMsg.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authProvider).userId;
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));
    
    return Scaffold(
      appBar: AppBar(
        title: bookingAsync.when(
          data: (booking) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chat đơn đặt lịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                'Mã đơn: ${booking.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          loading: () => const Text('Chat'),
          error: (_, __) => const Text('Chat'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Lỗi: $_error'))
                    : _messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có tin nhắn nào.\nHãy gửi lời chào!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true, // Show newest at the bottom
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              // Since we are reversing the list view, we need to reverse the index
                              final msg = _messages[_messages.length - 1 - index];
                              final isMe = msg.senderId == currentUserId;
                              return _buildMessageBubble(msg, isMe, theme);
                            },
                          ),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, ThemeData theme) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(
                color: isMe
                    ? theme.colorScheme.onPrimary.withOpacity(0.7)
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
