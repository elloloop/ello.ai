import 'package:uuid/uuid.dart';
import 'message.dart';

class Conversation {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String model;

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    required this.model,
  });

  factory Conversation.create({
    String? title,
    required String model,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: const Uuid().v4(),
      title: title ?? 'New Chat',
      messages: [],
      createdAt: now,
      updatedAt: now,
      model: model,
    );
  }

  Conversation copyWith({
    String? title,
    List<Message>? messages,
    DateTime? updatedAt,
    String? model,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      model: model ?? this.model,
    );
  }

  /// Get the last message snippet for display in conversation list
  String get lastMessageSnippet {
    if (messages.isEmpty) return 'No messages yet';
    final lastMessage = messages.last;
    const maxLength = 50;
    if (lastMessage.content.length <= maxLength) {
      return lastMessage.content;
    }
    return '${lastMessage.content.substring(0, maxLength)}...';
  }

  /// Get a formatted timestamp string for display
  String get formattedTimestamp {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if conversation has any messages
  bool get isEmpty => messages.isEmpty;

  /// Check if conversation has messages
  bool get isNotEmpty => messages.isNotEmpty;
}