// Headless integration test for chat exchange functionality
//
// This test verifies the complete chat flow works end-to-end using only providers
// and business logic, without any UI dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/core/dependencies.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('Headless Chat Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      // Create a provider container with mock configurations for reliable testing
      container = ProviderContainer(overrides: [
        // Enable mock gRPC client for consistent testing
        useMockGrpcProvider.overrideWith((ref) => MockGrpcNotifier()..toggle()),
        // Set up connection status as connected
        connectionStatusProvider
            .overrideWith((ref) => ConnectionStatusNotifier()..setConnected()),
        // Configure other providers with test values
        modelProvider.overrideWith((ref) => ModelNotifier()),
        grpcHostProvider
            .overrideWith((ref) => GrpcHostNotifier()..updateHost('test-host')),
        grpcPortProvider
            .overrideWith((ref) => GrpcPortNotifier()..updatePort(1234)),
        grpcSecureProvider
            .overrideWith((ref) => GrpcSecureNotifier()..setSecure(false)),
        chatHistoryProvider.overrideWith((ref) => ChatHistoryNotifier()),
        initConnectionStatusProvider.overrideWith((ref) {}),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('basic chat exchange using mock client', () async {
      // Get the chat controller
      final chatController = container.read(chatProvider.notifier);

      // Verify initial state
      expect(container.read(chatHistoryProvider), isEmpty);
      expect(container.read(useMockGrpcProvider), isTrue);

      // Send a test message
      const testMessage = "Hello, test message!";
      await chatController.sendMessage(testMessage);

      // Wait briefly for mock client to respond
      await Future.delayed(const Duration(milliseconds: 700));

      // Verify the message exchange
      final messages = container.read(chatHistoryProvider);
      expect(messages.length, greaterThanOrEqualTo(2));

      // Check user message
      final userMessage = messages.first;
      expect(userMessage.isUser, isTrue);
      expect(userMessage.content, equals(testMessage));

      // Check assistant response
      final assistantMessage = messages.last;
      expect(assistantMessage.isUser, isFalse);
      expect(assistantMessage.content, isNotEmpty);
      expect(assistantMessage.content.toLowerCase(), contains('mock'));
    });

    test('conversation reset clears history correctly', () async {
      final chatController = container.read(chatProvider.notifier);

      // Send a message first
      await chatController.sendMessage("Message before reset");
      await Future.delayed(const Duration(milliseconds: 600));

      // Verify we have messages
      expect(container.read(chatHistoryProvider).length, greaterThan(0));

      // Reset conversation
      await chatController.resetConversation();
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify reset message was added
      final messages = container.read(chatHistoryProvider);
      expect(messages.length, greaterThanOrEqualTo(1));

      final resetMessage = messages.last;
      expect(resetMessage.isUser, isFalse);
      expect(resetMessage.content.toLowerCase(), anyOf([
        contains('reset'),
        contains('conversation'),
        contains('new session')
      ]));
    });

    test('empty message is ignored', () async {
      final chatController = container.read(chatProvider.notifier);
      final initialLength = container.read(chatHistoryProvider).length;

      // Try to send empty message
      await chatController.sendMessage("");

      // Should not add any messages
      expect(container.read(chatHistoryProvider).length, equals(initialLength));
    });

    test('multiple messages create proper conversation flow', () async {
      final chatController = container.read(chatProvider.notifier);

      // Send multiple messages
      await chatController.sendMessage("First message");
      await Future.delayed(const Duration(milliseconds: 600));

      await chatController.sendMessage("Second message");
      await Future.delayed(const Duration(milliseconds: 600));

      // Verify conversation flow
      final messages = container.read(chatHistoryProvider);
      expect(messages.length, greaterThanOrEqualTo(4)); // 2 user + 2 assistant

      // Check message order and types
      final userMessages = messages.where((m) => m.isUser).toList();
      final assistantMessages = messages.where((m) => !m.isUser).toList();

      expect(userMessages.length, equals(2));
      expect(assistantMessages.length, greaterThanOrEqualTo(2));

      expect(userMessages[0].content, equals("First message"));
      expect(userMessages[1].content, equals("Second message"));
    });

    test('chat state transitions correctly during message sending', () async {
      final chatController = container.read(chatProvider.notifier);

      // Initially should be in data state
      expect(container.read(chatProvider), const AsyncData<void>(null));

      // Send message and monitor state
      final sendFuture = chatController.sendMessage("State test message");

      // Wait for completion
      await sendFuture;

      // Should return to data state
      expect(container.read(chatProvider), const AsyncData<void>(null));
    });

    test('mock client is properly configured', () {
      // Verify mock mode is enabled
      expect(container.read(useMockGrpcProvider), isTrue);

      // Verify the current client is mock
      final client = container.read(currentChatClientProvider);
      expect(client.toString(), contains('Mock'));

      // Verify connection status
      final connectionStatus = container.read(connectionStatusProvider);
      expect(connectionStatus, equals(ConnectionStatus.connected));
    });

    test('provider dependencies are properly initialized', () {
      // Test that all required providers are accessible
      expect(() => container.read(chatHistoryProvider), returnsNormally);
      expect(() => container.read(modelProvider), returnsNormally);
      expect(() => container.read(connectionStatusProvider), returnsNormally);
      expect(() => container.read(currentChatClientProvider), returnsNormally);
      expect(() => container.read(chatProvider), returnsNormally);

      // Test initial values
      expect(container.read(chatHistoryProvider), isEmpty);
      expect(container.read(modelProvider), isA<String>());
      expect(container.read(connectionStatusProvider), isA<ConnectionStatus>());
    });
  });
}