import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

typedef ChatSuggestion = ({String label, String route});

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String text,
    required bool isUser,
    required DateTime timestamp,
    @Default(false) bool isError,
    String? retryText,
    @Default(<ChatSuggestion>[]) List<ChatSuggestion> suggestions,
  }) = _ChatMessage;
}
