import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../utils/logger.dart';

/// Service for managing conversation storage
/// For now, uses in-memory storage. In a real app, this would use 
/// SharedPreferences, SQLite, or another persistence mechanism.
class ConversationStorageService {
  static final ConversationStorageService _instance = ConversationStorageService._internal();
  factory ConversationStorageService() => _instance;
  ConversationStorageService._internal();

  final Map<String, Conversation> _conversations = {};

  /// Get all conversations
  List<Conversation> getAllConversations() {
    final conversations = _conversations.values.toList();
    // Sort by most recently updated/created
    conversations.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt;
      final bTime = b.updatedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return conversations;
  }

  /// Get a specific conversation by ID
  Conversation? getConversation(String id) {
    return _conversations[id];
  }

  /// Save or update a conversation
  Future<void> saveConversation(Conversation conversation) async {
    try {
      _conversations[conversation.id] = conversation;
      Logger.info('Saved conversation: ${conversation.id}');
    } catch (e) {
      Logger.error('Error saving conversation: $e');
      rethrow;
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String id) async {
    try {
      _conversations.remove(id);
      Logger.info('Deleted conversation: $id');
    } catch (e) {
      Logger.error('Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Rename a conversation
  Future<void> renameConversation(String id, String newName) async {
    try {
      final conversation = _conversations[id];
      if (conversation != null) {
        final updated = conversation.copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
        _conversations[id] = updated;
        Logger.info('Renamed conversation $id to: $newName');
      }
    } catch (e) {
      Logger.error('Error renaming conversation: $e');
      rethrow;
    }
  }

  /// Duplicate a conversation
  Future<Conversation> duplicateConversation(String id, String newId) async {
    try {
      final original = _conversations[id];
      if (original != null) {
        final duplicate = original.duplicate(newId: newId);
        _conversations[newId] = duplicate;
        Logger.info('Duplicated conversation $id to $newId');
        return duplicate;
      }
      throw Exception('Conversation not found: $id');
    } catch (e) {
      Logger.error('Error duplicating conversation: $e');
      rethrow;
    }
  }

  /// Create a new conversation
  Future<Conversation> createConversation({
    required String id,
    String? name,
    List<Message>? initialMessages,
  }) async {
    try {
      final conversation = Conversation(
        id: id,
        name: name ?? 'New Conversation',
        messages: initialMessages ?? [],
        createdAt: DateTime.now(),
      );
      _conversations[id] = conversation;
      Logger.info('Created new conversation: $id');
      return conversation;
    } catch (e) {
      Logger.error('Error creating conversation: $e');
      rethrow;
    }
  }

  /// Update conversation messages
  Future<void> updateConversationMessages(String id, List<Message> messages) async {
    try {
      final conversation = _conversations[id];
      if (conversation != null) {
        final updated = conversation.copyWith(
          messages: messages,
          updatedAt: DateTime.now(),
        );
        _conversations[id] = updated;
      }
    } catch (e) {
      Logger.error('Error updating conversation messages: $e');
      rethrow;
    }
  }

  /// Clear all conversations (for testing/debugging)
  Future<void> clearAllConversations() async {
    _conversations.clear();
    Logger.info('Cleared all conversations');
  }
}