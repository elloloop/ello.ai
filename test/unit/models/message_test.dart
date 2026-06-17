import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('Message', () {
    group('Factory constructors', () {
      test('creates user message correctly', () {
        const content = 'Hello, this is a user message';
        final message = Message.user(content);
        
        expect(message.content, equals(content));
        expect(message.isUser, isTrue);
      });

      test('creates assistant message correctly', () {
        const content = 'Hello, this is an assistant message';
        final message = Message.assistant(content);
        
        expect(message.content, equals(content));
        expect(message.isUser, isFalse);
      });
    });

    group('Content manipulation', () {
      test('appendContent works correctly for user message', () {
        final originalMessage = Message.user('Hello');
        final appendedMessage = originalMessage.appendContent(' World');
        
        expect(appendedMessage.content, equals('Hello World'));
        expect(appendedMessage.isUser, equals(originalMessage.isUser));
        expect(originalMessage.content, equals('Hello')); // Original unchanged
      });

      test('appendContent works correctly for assistant message', () {
        final originalMessage = Message.assistant('AI response');
        final appendedMessage = originalMessage.appendContent(' continues');
        
        expect(appendedMessage.content, equals('AI response continues'));
        expect(appendedMessage.isUser, equals(originalMessage.isUser));
        expect(originalMessage.content, equals('AI response')); // Original unchanged
      });

      test('appendContent with empty string', () {
        final originalMessage = Message.user('Hello');
        final appendedMessage = originalMessage.appendContent('');
        
        expect(appendedMessage.content, equals('Hello'));
        expect(appendedMessage.isUser, equals(originalMessage.isUser));
      });

      test('appendContent multiple times', () {
        final message1 = Message.assistant('Part 1');
        final message2 = message1.appendContent(' Part 2');
        final message3 = message2.appendContent(' Part 3');
        
        expect(message3.content, equals('Part 1 Part 2 Part 3'));
        expect(message3.isUser, isFalse);
      });
    });

    group('Edge cases', () {
      test('handles empty content', () {
        final userMessage = Message.user('');
        final assistantMessage = Message.assistant('');
        
        expect(userMessage.content, isEmpty);
        expect(userMessage.isUser, isTrue);
        expect(assistantMessage.content, isEmpty);
        expect(assistantMessage.isUser, isFalse);
      });

      test('handles very long content', () {
        final longContent = 'A' * 10000;
        final message = Message.user(longContent);
        
        expect(message.content.length, equals(10000));
        expect(message.isUser, isTrue);
      });

      test('handles special characters', () {
        const specialContent = 'Hello 😀 こんにちは 🚀 @#\$%^&*()';
        final message = Message.assistant(specialContent);
        
        expect(message.content, equals(specialContent));
        expect(message.isUser, isFalse);
      });
    });
  });
}