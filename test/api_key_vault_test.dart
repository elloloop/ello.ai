import 'package:flutter_test/flutter_test.dart';
import 'package:ello_ai/src/services/api_key_vault.dart';

void main() {
  group('ApiKeyVault', () {
    late ApiKeyVault vault;

    setUp(() async {
      vault = await ApiKeyVault.create();
      // Clear any existing keys before each test
      await vault.clearAll();
    });

    tearDown(() async {
      // Clean up after each test
      await vault.clearAll();
    });

    test('should store and retrieve OpenAI API key', () async {
      const testKey = 'sk-test123456789';
      
      // Store the key
      await vault.storeOpenAIKey(testKey);
      
      // Retrieve the key
      final retrievedKey = await vault.getOpenAIKey();
      
      expect(retrievedKey, equals(testKey));
    });

    test('should return null for non-existent key', () async {
      final key = await vault.getOpenAIKey();
      expect(key, isNull);
    });

    test('should remove stored key', () async {
      const testKey = 'sk-test123456789';
      
      // Store the key
      await vault.storeOpenAIKey(testKey);
      
      // Verify it's stored
      final storedKey = await vault.getOpenAIKey();
      expect(storedKey, equals(testKey));
      
      // Remove the key
      await vault.removeOpenAIKey();
      
      // Verify it's removed
      final removedKey = await vault.getOpenAIKey();
      expect(removedKey, isNull);
    });

    test('should handle empty key storage', () async {
      // Try to store an empty key
      await vault.storeOpenAIKey('');
      
      // Should be able to retrieve it (even if empty)
      final key = await vault.getOpenAIKey();
      expect(key, equals(''));
    });

    test('should handle special characters in keys', () async {
      const testKey = 'sk-test!@#\$%^&*()_+-=[]{}|;:,.<>?';
      
      await vault.storeOpenAIKey(testKey);
      final retrievedKey = await vault.getOpenAIKey();
      
      expect(retrievedKey, equals(testKey));
    });

    test('should clear all keys', () async {
      const testKey = 'sk-test123456789';
      
      // Store a key
      await vault.storeOpenAIKey(testKey);
      
      // Verify it's stored
      final storedKey = await vault.getOpenAIKey();
      expect(storedKey, equals(testKey));
      
      // Clear all keys
      await vault.clearAll();
      
      // Verify it's removed
      final clearedKey = await vault.getOpenAIKey();
      expect(clearedKey, isNull);
    });
  });
}