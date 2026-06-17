import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/llm_client/mock_client.dart';
import 'package:ello_ai/src/llm_client/mock_grpc_client.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('Chat Client Parameter Tests', () {
    test('MockClient includes temperature and top_p in response', () async {
      final client = MockClient();
      final messages = [Message.user('Hello')];
      
      final response = await client.chat(
        messages: messages,
        model: 'gpt-4',
        temperature: 0.8,
        topP: 0.9,
      ).join();
      
      expect(response, contains('gpt-4'));
      expect(response, contains('temp: 0.8'));
      expect(response, contains('top_p: 0.9'));
    });

    test('MockGrpcClient includes temperature and top_p in response', () async {
      final client = MockGrpcClient();
      final messages = [Message.user('Hello world')];
      
      final responseChunks = <String>[];
      await for (final chunk in client.chat(
        messages: messages,
        model: 'claude-3',
        temperature: 1.2,
        topP: 0.7,
      )) {
        responseChunks.add(chunk);
      }
      
      final fullResponse = responseChunks.join();
      expect(fullResponse, contains('claude-3'));
      expect(fullResponse, contains('Temperature: 1.2'));
      expect(fullResponse, contains('Top-p: 0.7'));
      expect(fullResponse, contains('Hello world'));
    });

    test('Chat clients handle null parameters gracefully', () async {
      final client = MockClient();
      final messages = [Message.user('Test')];
      
      // Should not throw when parameters are null
      expect(() async {
        await client.chat(
          messages: messages,
          model: 'gpt-3.5-turbo',
          // temperature and topP are null
        ).join();
      }, returnsNormally);
    });

    test('Chat clients handle partial parameters', () async {
      final client = MockGrpcClient();
      final messages = [Message.user('Test')];
      
      final responseChunks = <String>[];
      await for (final chunk in client.chat(
        messages: messages,
        temperature: 0.5,
        // topP is null, model is null
      )) {
        responseChunks.add(chunk);
      }
      
      final fullResponse = responseChunks.join();
      expect(fullResponse, contains('Temperature: 0.5'));
      // Should not contain Top-p since it's null
      expect(fullResponse, isNot(contains('Top-p:')));
    });
  });
}