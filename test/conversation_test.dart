import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/models/conversation.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('Conversation Model Tests', () {
    test('creates a new conversation with default values', () {
      final conversation = Conversation.create(model: 'gpt-3.5-turbo');
      
      expect(conversation.id, isNotEmpty);
      expect(conversation.title, equals('New Chat'));
      expect(conversation.messages, isEmpty);
      expect(conversation.model, equals('gpt-3.5-turbo'));
      expect(conversation.isEmpty, isTrue);
      expect(conversation.isNotEmpty, isFalse);
    });

    test('creates a new conversation with custom title', () {
      final conversation = Conversation.create(
        title: 'Custom Title',
        model: 'gpt-4o',
      );
      
      expect(conversation.title, equals('Custom Title'));
      expect(conversation.model, equals('gpt-4o'));
    });

    test('updates conversation with copyWith', () {
      final conversation = Conversation.create(model: 'gpt-3.5-turbo');
      final messages = [Message.user('Hello'), Message.assistant('Hi there!')];
      
      final updatedConversation = conversation.copyWith(
        title: 'Updated Title',
        messages: messages,
      );
      
      expect(updatedConversation.id, equals(conversation.id));
      expect(updatedConversation.title, equals('Updated Title'));
      expect(updatedConversation.messages, equals(messages));
      expect(updatedConversation.model, equals('gpt-3.5-turbo'));
      expect(updatedConversation.isNotEmpty, isTrue);
    });

    test('returns correct last message snippet', () {
      final conversation = Conversation.create(model: 'gpt-3.5-turbo');
      
      // Empty conversation
      expect(conversation.lastMessageSnippet, equals('No messages yet'));
      
      // Short message
      final shortMessage = Message.user('Hello');
      final conversationWithShort = conversation.copyWith(messages: [shortMessage]);
      expect(conversationWithShort.lastMessageSnippet, equals('Hello'));
      
      // Long message
      final longMessage = Message.user('This is a very long message that should be truncated because it exceeds the maximum length limit');
      final conversationWithLong = conversation.copyWith(messages: [longMessage]);
      expect(conversationWithLong.lastMessageSnippet, startsWith('This is a very long message that should be truncat'));
      expect(conversationWithLong.lastMessageSnippet, endsWith('...'));
    });

    test('returns formatted timestamp', () {
      final now = DateTime.now();
      final conversation = Conversation(
        id: 'test-id',
        title: 'Test',
        messages: [],
        createdAt: now,
        updatedAt: now.subtract(const Duration(minutes: 5)),
        model: 'gpt-3.5-turbo',
      );
      
      expect(conversation.formattedTimestamp, equals('5m ago'));
    });
  });
}