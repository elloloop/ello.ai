import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/models/conversation.dart';
import 'package:ello_ai/src/models/message.dart';
import 'package:ello_ai/src/services/conversation_storage_service.dart';

void main() {
  group('ConversationStorageService Tests', () {
    late ConversationStorageService service;

    setUp(() {
      service = ConversationStorageService();
      // Clear any existing conversations
      service.clearAllConversations();
    });

    test('creates a new conversation', () async {
      final conversation = await service.createConversation(
        id: 'test-id',
        name: 'Test Conversation',
      );

      expect(conversation.id, equals('test-id'));
      expect(conversation.name, equals('Test Conversation'));
      expect(conversation.messages, isEmpty);

      final retrieved = service.getConversation('test-id');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test Conversation'));
    });

    test('renames a conversation', () async {
      await service.createConversation(
        id: 'test-id',
        name: 'Original Name',
      );

      await service.renameConversation('test-id', 'New Name');

      final conversation = service.getConversation('test-id');
      expect(conversation!.name, equals('New Name'));
      expect(conversation.updatedAt, isNotNull);
    });

    test('duplicates a conversation', () async {
      final messages = [
        Message.user('Hello'),
        Message.assistant('Hi there!'),
      ];

      await service.createConversation(
        id: 'original-id',
        name: 'Original Conversation',
        initialMessages: messages,
      );

      final duplicate = await service.duplicateConversation('original-id', 'duplicate-id');

      expect(duplicate.id, equals('duplicate-id'));
      expect(duplicate.name, equals('Original Conversation (Copy)'));
      expect(duplicate.messages.length, equals(2));
      expect(duplicate.messages[0].content, equals('Hello'));
      expect(duplicate.messages[1].content, equals('Hi there!'));

      // Ensure original is unchanged
      final original = service.getConversation('original-id');
      expect(original!.name, equals('Original Conversation'));
    });

    test('deletes a conversation', () async {
      await service.createConversation(
        id: 'test-id',
        name: 'Test Conversation',
      );

      expect(service.getConversation('test-id'), isNotNull);

      await service.deleteConversation('test-id');

      expect(service.getConversation('test-id'), isNull);
    });

    test('updates conversation messages', () async {
      await service.createConversation(
        id: 'test-id',
        name: 'Test Conversation',
      );

      final messages = [
        Message.user('Hello'),
        Message.assistant('Hi!'),
      ];

      await service.updateConversationMessages('test-id', messages);

      final conversation = service.getConversation('test-id');
      expect(conversation!.messages.length, equals(2));
      expect(conversation.messages[0].content, equals('Hello'));
      expect(conversation.updatedAt, isNotNull);
    });

    test('gets all conversations sorted by update time', () async {
      // Create conversations with some delay to ensure different timestamps
      await service.createConversation(id: 'conv1', name: 'First');
      await Future.delayed(const Duration(milliseconds: 10));
      await service.createConversation(id: 'conv2', name: 'Second');
      await Future.delayed(const Duration(milliseconds: 10));
      await service.createConversation(id: 'conv3', name: 'Third');

      // Update the first conversation to make it most recent
      await service.renameConversation('conv1', 'First Updated');

      final conversations = service.getAllConversations();
      expect(conversations.length, equals(3));
      
      // Should be sorted by most recent first
      expect(conversations[0].name, equals('First Updated'));
    });
  });

  group('Conversation Model Tests', () {
    test('creates conversation with correct data', () {
      final conversation = Conversation(
        id: 'test-id',
        name: 'Test Chat',
        messages: [Message.user('Hello')],
        createdAt: DateTime.now(),
      );

      expect(conversation.id, equals('test-id'));
      expect(conversation.name, equals('Test Chat'));
      expect(conversation.messages.length, equals(1));
    });

    test('duplicates conversation correctly', () {
      final original = Conversation(
        id: 'original',
        name: 'Original Chat',
        messages: [Message.user('Hello'), Message.assistant('Hi!')],
        createdAt: DateTime.now(),
      );

      final duplicate = original.duplicate(newId: 'duplicate');

      expect(duplicate.id, equals('duplicate'));
      expect(duplicate.name, equals('Original Chat (Copy)'));
      expect(duplicate.messages.length, equals(2));
      expect(duplicate.messages[0].content, equals('Hello'));
      expect(duplicate.messages[1].content, equals('Hi!'));
    });

    test('generates preview from first user message', () {
      final conversation = Conversation(
        id: 'test',
        name: 'Test',
        messages: [
          Message.user('This is a very long message that should be truncated when displayed as a preview'),
          Message.assistant('Response'),
        ],
        createdAt: DateTime.now(),
      );

      final preview = conversation.preview;
      expect(preview.length, lessThanOrEqualTo(53)); // 50 chars + "..."
      expect(preview, startsWith('This is a very long message'));
      expect(preview, endsWith('...'));
    });

    test('generates preview from creation date when no user messages', () {
      final conversation = Conversation(
        id: 'test',
        name: 'Test',
        messages: [Message.assistant('System message')],
        createdAt: DateTime.now(),
      );

      final preview = conversation.preview;
      expect(preview, startsWith('Created'));
    });

    test('converts to and from JSON correctly', () {
      final original = Conversation(
        id: 'test-id',
        name: 'Test Chat',
        messages: [
          Message.user('Hello'),
          Message.assistant('Hi there!'),
        ],
        createdAt: DateTime.parse('2023-01-01T12:00:00Z'),
        updatedAt: DateTime.parse('2023-01-01T12:30:00Z'),
      );

      final json = original.toJson();
      final restored = Conversation.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.messages.length, equals(original.messages.length));
      expect(restored.messages[0].content, equals('Hello'));
      expect(restored.messages[1].content, equals('Hi there!'));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.updatedAt, equals(original.updatedAt));
    });
  });

  group('Message Model Tests', () {
    test('creates user and assistant messages correctly', () {
      final userMessage = Message.user('Hello');
      final assistantMessage = Message.assistant('Hi there!');

      expect(userMessage.isUser, isTrue);
      expect(userMessage.content, equals('Hello'));

      expect(assistantMessage.isUser, isFalse);
      expect(assistantMessage.content, equals('Hi there!'));
    });

    test('appends content to message', () {
      final message = Message.user('Hello');
      final updated = message.appendContent(' world!');

      expect(updated.content, equals('Hello world!'));
      expect(updated.isUser, equals(message.isUser));
    });

    test('converts to and from JSON correctly', () {
      final original = Message.user('Test message');
      final json = original.toJson();
      final restored = Message.fromJson(json);

      expect(restored.content, equals(original.content));
      expect(restored.isUser, equals(original.isUser));
    });
  });
}