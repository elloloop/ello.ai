import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/llm_client/mock_client.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('MockClient', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
    });

    test('returns expected message format without model', () async {
      final messages = [Message.user('Hello')];
      
      final response = mockClient.chat(messages: messages);
      final responseText = await response.single;
      
      expect(responseText, equals('Hello from MockClient!'));
    });

    test('returns expected message format with model', () async {
      final messages = [Message.user('Hello')];
      const model = 'gpt-3.5-turbo';
      
      final response = mockClient.chat(messages: messages, model: model);
      final responseText = await response.single;
      
      expect(responseText, equals('Hello from MockClient using gpt-3.5-turbo!'));
    });

    test('handles empty messages list', () async {
      final messages = <Message>[];
      
      final response = mockClient.chat(messages: messages);
      final responseText = await response.single;
      
      expect(responseText, equals('Hello from MockClient!'));
    });

    test('handles multiple messages in list', () async {
      final messages = [
        Message.user('First message'),
        Message.assistant('Assistant response'),
        Message.user('Second message'),
      ];
      
      final response = mockClient.chat(messages: messages);
      final responseText = await response.single;
      
      expect(responseText, equals('Hello from MockClient!'));
    });

    test('handles null model parameter', () async {
      final messages = [Message.user('Hello')];
      
      final response = mockClient.chat(messages: messages, model: null);
      final responseText = await response.single;
      
      expect(responseText, equals('Hello from MockClient!'));
    });

    test('returns stream with single value', () async {
      final messages = [Message.user('Test')];
      
      final response = mockClient.chat(messages: messages);
      final responseList = await response.toList();
      
      expect(responseList.length, equals(1));
      expect(responseList.first, equals('Hello from MockClient!'));
    });

    test('works with different model names', () async {
      final testCases = [
        'gpt-4',
        'claude-3',
        'gemini-pro',
        'custom-model-123',
        '',
      ];
      
      for (final model in testCases) {
        final messages = [Message.user('Test with $model')];
        final response = mockClient.chat(messages: messages, model: model);
        final responseText = await response.single;
        
        if (model.isNotEmpty) {
          expect(responseText, equals('Hello from MockClient using $model!'));
        } else {
          expect(responseText, equals('Hello from MockClient using !'));
        }
      }
    });
  });
}