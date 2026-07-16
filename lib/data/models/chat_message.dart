class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  /// True when this bubble represents a failed/fallback reply (network error,
  /// rate limit, or the AI provider itself being unavailable) rather than a
  /// real answer — driven by the backend's `success` flag / a thrown request.
  final bool isError;

  /// The original user message to resend when [isError] is true and the
  /// user taps Retry.
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
