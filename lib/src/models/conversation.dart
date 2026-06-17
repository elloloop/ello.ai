import 'message.dart';

/// Represents a conversation with messages and metadata
class Conversation {
  const Conversation({
    required this.id,
    required this.name,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Create a copy of this conversation with updated fields
  Conversation copyWith({
    String? id,
    String? name,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a duplicate of this conversation with a new ID
  Conversation duplicate({required String newId, String? newName}) {
    return Conversation(
      id: newId,
      name: newName ?? '$name (Copy)',
      messages: List.from(messages),
      createdAt: DateTime.now(),
      updatedAt: null,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      name: json['name'] as String,
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Get a preview of the conversation (first user message or creation time)
  String get preview {
    final userMessages = messages.where((m) => m.isUser);
    final firstUserMessage = userMessages.isNotEmpty ? userMessages.first : null;
    if (firstUserMessage != null) {
      final content = firstUserMessage.content.trim();
      return content.length > 50 ? '${content.substring(0, 50)}...' : content;
    }
    return 'Created ${_formatDate(createdAt)}';
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

