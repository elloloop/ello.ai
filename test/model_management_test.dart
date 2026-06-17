import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/src/core/dependencies.dart';

void main() {
  group('Model and API Key Management', () {
    test('modelProvidersProvider returns correct providers', () {
      final container = ProviderContainer();
      final providers = container.read(modelProvidersProvider);
      
      expect(providers.length, greaterThan(0));
      expect(providers.any((p) => p.id == 'openai'), true);
      expect(providers.any((p) => p.id == 'anthropic'), true);
      expect(providers.any((p) => p.id == 'google'), true);
      expect(providers.any((p) => p.id == 'meta'), true);
      
      container.dispose();
    });

    test('apiKeysProvider manages keys correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(apiKeysProvider.notifier);
      
      // Set a key
      notifier.setApiKey('openai', 'sk-test123');
      final keys = container.read(apiKeysProvider);
      expect(keys['openai'], 'sk-test123');
      
      // Remove a key
      notifier.removeApiKey('openai');
      final updatedKeys = container.read(apiKeysProvider);
      expect(updatedKeys['openai'], '');
      
      container.dispose();
    });

    test('availableModelsProvider filters models by API keys', () {
      final container = ProviderContainer();
      
      // Initially, no keys are set, so all models should be available
      final allModels = container.read(availableModelsProvider);
      expect(allModels.length, greaterThan(0));
      
      // Set only OpenAI key
      container.read(apiKeysProvider.notifier).setApiKey('openai', 'sk-test123');
      final openaiModels = container.read(availableModelsProvider);
      expect(openaiModels.every((model) => 
        ['gpt-3.5-turbo', 'gpt-4o', 'gpt-4-turbo', 'gpt-4'].contains(model)
      ), true);
      
      container.dispose();
    });

    test('API key validation works correctly', () {
      final container = ProviderContainer();
      
      // Set invalid OpenAI key
      container.read(apiKeysProvider.notifier).setApiKey('openai', 'invalid-key');
      final validation = container.read(apiKeyValidationProvider);
      expect(validation['openai'], isNotEmpty);
      
      // Set valid OpenAI key
      container.read(apiKeysProvider.notifier).setApiKey('openai', 'sk-valid123');
      final validValidation = container.read(apiKeyValidationProvider);
      expect(validValidation['openai'], isEmpty);
      
      container.dispose();
    });
  });
}