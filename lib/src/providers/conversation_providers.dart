import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/conversation_storage_service.dart';
import '../utils/logger.dart';

/// Provider for conversation storage service
final conversationStorageServiceProvider = Provider<ConversationStorageService>((ref) {
  return ConversationStorageService();
});

/// Provider for the current active conversation ID
final activeConversationIdProvider = StateProvider<String?>((ref) => null);

/// Provider for all conversations
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, List<Conversation>>((ref) {
  return ConversationsNotifier(ref);
});

/// Provider for the current active conversation
final activeConversationProvider = Provider<Conversation?>((ref) {
  final activeId = ref.watch(activeConversationIdProvider);
  final conversations = ref.watch(conversationsProvider);
  
  if (activeId == null) return null;
  
  try {
    return conversations.firstWhere((conv) => conv.id == activeId);
  } catch (e) {
    return null;
  }
});

/// Notifier for managing conversations
class ConversationsNotifier extends StateNotifier<List<Conversation>> {
  ConversationsNotifier(this.ref) : super([]) {
    _loadConversations();
  }

  final Ref ref;
  final _uuid = const Uuid();

  ConversationStorageService get _storage => ref.read(conversationStorageServiceProvider);

  /// Load all conversations from storage
  Future<void> _loadConversations() async {
    try {
      final conversations = _storage.getAllConversations();
      state = conversations;
    } catch (e) {
      Logger.error('Error loading conversations: $e');
    }
  }

  /// Create a new conversation
  Future<String> createConversation({String? name, List<Message>? initialMessages}) async {
    try {
      final id = _uuid.v4();
      final conversation = await _storage.createConversation(
        id: id,
        name: name,
        initialMessages: initialMessages,
      );
      
      state = [...state, conversation];
      
      // Set as active conversation
      ref.read(activeConversationIdProvider.notifier).state = id;
      
      Logger.info('Created and activated conversation: $id');
      return id;
    } catch (e) {
      Logger.error('Error creating conversation: $e');
      rethrow;
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String id) async {
    try {
      await _storage.deleteConversation(id);
      state = state.where((conv) => conv.id != id).toList();
      
      // If this was the active conversation, clear it
      if (ref.read(activeConversationIdProvider) == id) {
        ref.read(activeConversationIdProvider.notifier).state = null;
      }
      
      Logger.info('Deleted conversation: $id');
    } catch (e) {
      Logger.error('Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Rename a conversation
  Future<void> renameConversation(String id, String newName) async {
    try {
      await _storage.renameConversation(id, newName);
      
      // Update state
      state = state.map((conv) {
        if (conv.id == id) {
          return conv.copyWith(name: newName, updatedAt: DateTime.now());
        }
        return conv;
      }).toList();
      
      Logger.info('Renamed conversation $id to: $newName');
    } catch (e) {
      Logger.error('Error renaming conversation: $e');
      rethrow;
    }
  }

  /// Duplicate a conversation
  Future<String> duplicateConversation(String id) async {
    try {
      final newId = _uuid.v4();
      final duplicated = await _storage.duplicateConversation(id, newId);
      
      state = [...state, duplicated];
      
      Logger.info('Duplicated conversation $id to $newId');
      return newId;
    } catch (e) {
      Logger.error('Error duplicating conversation: $e');
      rethrow;
    }
  }

  /// Set active conversation
  void setActiveConversation(String? id) {
    ref.read(activeConversationIdProvider.notifier).state = id;
    Logger.info('Set active conversation: $id');
  }

  /// Update messages for a conversation
  Future<void> updateConversationMessages(String id, List<Message> messages) async {
    try {
      await _storage.updateConversationMessages(id, messages);
      
      // Update state
      state = state.map((conv) {
        if (conv.id == id) {
          return conv.copyWith(messages: messages, updatedAt: DateTime.now());
        }
        return conv;
      }).toList();
    } catch (e) {
      Logger.error('Error updating conversation messages: $e');
      rethrow;
    }
  }

  /// Get or create a default conversation
  Future<String> getOrCreateDefaultConversation() async {
    if (state.isEmpty) {
      return await createConversation(name: 'New Conversation');
    }
    
    // Return the first conversation ID
    final firstConv = state.first;
    ref.read(activeConversationIdProvider.notifier).state = firstConv.id;
    return firstConv.id;
  }
}