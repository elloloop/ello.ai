import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/core/dependencies.dart';
import 'package:ello_ai/src/llm_client/mock_grpc_client.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('End-to-End Parameter Integration Test', () {
    test('Full parameter flow from UI state to chat client', () async {
      // Create a provider container
      final container = ProviderContainer();
      
      // Set custom temperature and top_p values
      container.read(temperatureProvider.notifier).updateTemperature(1.5);
      container.read(topPProvider.notifier).updateTopP(0.8);
      
      // Verify the values are set correctly
      expect(container.read(temperatureProvider), 1.5);
      expect(container.read(topPProvider), 0.8);
      
      // Create a mock client to test parameter passing
      final client = MockGrpcClient();
      final messages = [Message.user('Test parameter integration')];
      
      // Call the client with parameters from the providers
      final responseChunks = <String>[];
      await for (final chunk in client.chat(
        messages: messages,
        model: 'test-model',
        temperature: container.read(temperatureProvider),
        topP: container.read(topPProvider),
      )) {
        responseChunks.add(chunk);
      }
      
      final fullResponse = responseChunks.join();
      
      // Verify the parameters are correctly included in the response
      expect(fullResponse, contains('test-model'));
      expect(fullResponse, contains('Temperature: 1.5'));
      expect(fullResponse, contains('Top-p: 0.8'));
      expect(fullResponse, contains('Test parameter integration'));
      
      // Clean up
      container.dispose();
    });

    test('Parameter validation prevents invalid values', () {
      final container = ProviderContainer();
      
      // Test temperature bounds
      container.read(temperatureProvider.notifier).updateTemperature(-1.0);
      expect(container.read(temperatureProvider), 0.0);
      
      container.read(temperatureProvider.notifier).updateTemperature(3.0);
      expect(container.read(temperatureProvider), 2.0);
      
      // Test top_p bounds
      container.read(topPProvider.notifier).updateTopP(-0.5);
      expect(container.read(topPProvider), 0.0);
      
      container.read(topPProvider.notifier).updateTopP(1.5);
      expect(container.read(topPProvider), 1.0);
      
      container.dispose();
    });

    test('Default values are sensible for production use', () {
      final container = ProviderContainer();
      
      // Verify default values
      expect(container.read(temperatureProvider), 0.7); // Common default for balanced creativity
      expect(container.read(topPProvider), 1.0); // No nucleus sampling by default
      
      container.dispose();
    });

    test('Parameters work with different model types', () async {
      final container = ProviderContainer();
      final client = MockGrpcClient();
      
      // Set parameters
      container.read(temperatureProvider.notifier).updateTemperature(0.9);
      container.read(topPProvider.notifier).updateTopP(0.95);
      
      final models = ['gpt-3.5-turbo', 'gpt-4o', 'claude-3-sonnet', 'gemini-pro'];
      
      for (final model in models) {
        final messages = [Message.user('Hello $model')];
        
        final responseChunks = <String>[];
        await for (final chunk in client.chat(
          messages: messages,
          model: model,
          temperature: container.read(temperatureProvider),
          topP: container.read(topPProvider),
        )) {
          responseChunks.add(chunk);
        }
        
        final fullResponse = responseChunks.join();
        
        // Each model should work with the same parameters
        expect(fullResponse, contains(model));
        expect(fullResponse, contains('Temperature: 0.9'));
        expect(fullResponse, contains('Top-p: 0.95'));
      }
      
      container.dispose();
    });
  });
}