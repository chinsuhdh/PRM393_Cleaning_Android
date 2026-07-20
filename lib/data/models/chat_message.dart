class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  final bool isError;

  final String? retryText;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isError = false,
    this.retryText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
