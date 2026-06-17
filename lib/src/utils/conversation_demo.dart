import '../models/conversation.dart';
import '../models/message.dart';
import '../services/conversation_storage_service.dart';
import '../utils/logger.dart';

/// Demo utility to test conversation management features
class ConversationDemo {
  static final ConversationStorageService _storage = ConversationStorageService();

  /// Run a demo of conversation management features
  static Future<void> runDemo() async {
    Logger.info('Starting conversation management demo...');

    try {
      // Clear any existing conversations
      await _storage.clearAllConversations();

      // Create some sample conversations
      await _createSampleConversations();

      // Test rename functionality
      await _testRename();

      // Test duplicate functionality
      await _testDuplicate();

      // Test delete functionality
      await _testDelete();

      // Show final state
      await _showAllConversations();

      Logger.info('Conversation management demo completed successfully!');
    } catch (e) {
      Logger.error('Demo failed: $e');
    }
  }

  static Future<void> _createSampleConversations() async {
    Logger.info('Creating sample conversations...');

    // Conversation 1: Simple greeting
    await _storage.createConversation(
      id: 'conv-1',
      name: 'Greeting Chat',
      initialMessages: [
        Message.user('Hello!'),
        Message.assistant('Hi there! How can I help you today?'),
      ],
    );

    // Conversation 2: Programming help
    await _storage.createConversation(
      id: 'conv-2',
      name: 'Flutter Development',
      initialMessages: [
        Message.user('How do I create a custom widget in Flutter?'),
        Message.assistant('To create a custom widget in Flutter, you can extend StatelessWidget or StatefulWidget...'),
        Message.user('Can you show me an example?'),
        Message.assistant('Sure! Here\'s a simple example of a custom button widget...'),
      ],
    );

    // Conversation 3: Empty conversation
    await _storage.createConversation(
      id: 'conv-3',
      name: 'New Project Ideas',
    );

    Logger.info('Created 3 sample conversations');
  }

  static Future<void> _testRename() async {
    Logger.info('Testing rename functionality...');

    await _storage.renameConversation('conv-3', 'Brainstorming Session');
    
    final conversation = _storage.getConversation('conv-3');
    if (conversation?.name == 'Brainstorming Session') {
      Logger.info('✓ Rename test passed');
    } else {
      Logger.error('✗ Rename test failed');
    }
  }

  static Future<void> _testDuplicate() async {
    Logger.info('Testing duplicate functionality...');

    final duplicate = await _storage.duplicateConversation('conv-1', 'conv-1-copy');
    
    if (duplicate.id == 'conv-1-copy' && 
        duplicate.name == 'Greeting Chat (Copy)' &&
        duplicate.messages.length == 2) {
      Logger.info('✓ Duplicate test passed');
    } else {
      Logger.error('✗ Duplicate test failed');
    }
  }

  static Future<void> _testDelete() async {
    Logger.info('Testing delete functionality...');

    await _storage.deleteConversation('conv-1-copy');
    
    final deleted = _storage.getConversation('conv-1-copy');
    if (deleted == null) {
      Logger.info('✓ Delete test passed');
    } else {
      Logger.error('✗ Delete test failed');
    }
  }

  static Future<void> _showAllConversations() async {
    Logger.info('Final conversation list:');
    
    final conversations = _storage.getAllConversations();
    for (final conv in conversations) {
      Logger.info('- ${conv.name} (${conv.messages.length} messages)');
      Logger.info('  Preview: ${conv.preview}');
    }
  }
}