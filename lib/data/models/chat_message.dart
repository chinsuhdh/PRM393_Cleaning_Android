typedef ChatSuggestion = ({String label, String route});

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  final bool isError;

  final String? retryText;

  final List<ChatSuggestion> suggestions;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.isError = false,
    this.retryText,
    this.suggestions = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
