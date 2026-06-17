// Integration tests for headless chat exchange functionality
//
// These tests verify the complete chat flow works end-to-end without UI dependencies.
// They test the core chat logic, state management, and provider interactions.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/core/dependencies.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('Chat Integration Tests (Headless)', () {
    late ProviderContainer container;

    setUp(() {
      // Create a container with mock configurations for reliable testing
      container = ProviderContainer(overrides: [
        // Use mock gRPC client for reliable testing
        useMockGrpcProvider.overrideWith((ref) => MockGrpcNotifier()..toggle()),
        // Set up other required providers with test values
        connectionStatusProvider
            .overrideWith((ref) => ConnectionStatusNotifier()..setConnected()),
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

    testWidgets('Complete chat exchange flow with mock client', (tester) async {
      // Get the chat controller and history
      final chatController = container.read(chatProvider.notifier);
      final chatHistory = container.read(chatHistoryProvider.notifier);

      // Verify initial state is empty
      expect(container.read(chatHistoryProvider), isEmpty);

      // Send a test message
      const testMessage = "Hello, this is a test message!";
      await chatController.sendMessage(testMessage);

      // Allow async operations to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the message was added to history
      final messages = container.read(chatHistoryProvider);
      expect(messages.length, greaterThanOrEqualTo(1));

      // Verify user message was added
      final userMessage = messages.first;
      expect(userMessage.isUser, isTrue);
      expect(userMessage.content, equals(testMessage));

      // Wait for assistant response (mock client should respond)
      await tester.pump(const Duration(milliseconds: 500));

      // Verify assistant response was added
      final updatedMessages = container.read(chatHistoryProvider);
      expect(updatedMessages.length, greaterThanOrEqualTo(2));

      final assistantMessage = updatedMessages.last;
      expect(assistantMessage.isUser, isFalse);
      expect(assistantMessage.content, isNotEmpty);
      expect(assistantMessage.content.toLowerCase(), contains('mock'));
    });

    testWidgets('Multiple message exchange', (tester) async {
      final chatController = container.read(chatProvider.notifier);

      // Send first message
      await chatController.sendMessage("First message");
      await tester.pump(const Duration(milliseconds: 600));

      // Send second message
      await chatController.sendMessage("Second message");
      await tester.pump(const Duration(milliseconds: 600));

      // Verify we have multiple exchanges
      final messages = container.read(chatHistoryProvider);
      expect(messages.length, greaterThanOrEqualTo(4)); // 2 user + 2 assistant messages

      // Verify message order and types
      expect(messages[0].isUser, isTrue);
      expect(messages[0].content, equals("First message"));
      expect(messages[1].isUser, isFalse); // Assistant response
      expect(messages[2].isUser, isTrue);
      expect(messages[2].content, equals("Second message"));
      expect(messages[3].isUser, isFalse); // Assistant response
    });

    testWidgets('Chat state management during message sending', (tester) async {
      final chatController = container.read(chatProvider.notifier);

      // Initially should be in idle state
      expect(container.read(chatProvider), const AsyncData<void>(null));

      // Start sending a message (don't await yet)
      final sendFuture = chatController.sendMessage("Test message");

      // Immediately check if state changed to loading
      await tester.pump();
      final currentState = container.read(chatProvider);
      
      // Should be in loading state or completed quickly with mock client
      expect(currentState.isLoading || currentState.hasValue, isTrue);

      // Wait for completion
      await sendFuture;
      await tester.pump(const Duration(milliseconds: 100));

      // Should be back to data state
      expect(container.read(chatProvider), const AsyncData<void>(null));
    });

    testWidgets('Conversation reset functionality', (tester) async {
      final chatController = container.read(chatProvider.notifier);

      // Add some messages first
      await chatController.sendMessage("Message before reset");
      await tester.pump(const Duration(milliseconds: 500));

      // Verify we have messages
      expect(container.read(chatHistoryProvider).length, greaterThan(0));

      // Reset conversation
      await chatController.resetConversation();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify conversation was reset - should have at least one message 
      // (the reset notification message)
      final messages = container.read(chatHistoryProvider);
      expect(messages.length, greaterThanOrEqualTo(1));
      
      // The last message should be the reset notification
      final lastMessage = messages.last;
      expect(lastMessage.isUser, isFalse);
      expect(lastMessage.content.toLowerCase(), anyOf([
        contains('reset'),
        contains('conversation'),
        contains('new session')
      ]));
    });

    testWidgets('Empty message handling', (tester) async {
      final chatController = container.read(chatProvider.notifier);
      final initialLength = container.read(chatHistoryProvider).length;

      // Try to send empty message
      await chatController.sendMessage("");
      await tester.pump();

      // Should not add any messages
      expect(container.read(chatHistoryProvider).length, equals(initialLength));
    });

    testWidgets('Mock client connection status', (tester) async {
      // Verify mock mode is enabled
      expect(container.read(useMockGrpcProvider), isTrue);

      // Verify connection status is properly managed
      final connectionStatus = container.read(connectionStatusProvider);
      expect(connectionStatus, isA<ConnectionStatus>());

      // Send a message and verify connection status remains stable
      final chatController = container.read(chatProvider.notifier);
      await chatController.sendMessage("Test connection");
      await tester.pump(const Duration(milliseconds: 300));

      // Connection should remain stable with mock client
      final updatedStatus = container.read(connectionStatusProvider);
      expect(updatedStatus, isA<ConnectionStatus>());
    });

    testWidgets('Chat client provider switches to mock mode', (tester) async {
      // Verify the current client is mock
      final client = container.read(currentChatClientProvider);
      expect(client.toString(), contains('Mock'));

      // Verify the client can handle chat requests
      const testMessage = "Provider test message";
      final chatController = container.read(chatProvider.notifier);
      
      await chatController.sendMessage(testMessage);
      await tester.pump(const Duration(milliseconds: 400));

      // Verify response was received
      final messages = container.read(chatHistoryProvider);
      expect(messages.length, greaterThanOrEqualTo(2));
      expect(messages.last.isUser, isFalse);
    });
  });

  group('Chat Integration Tests (Error Scenarios)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        useMockGrpcProvider.overrideWith((ref) => MockGrpcNotifier()..toggle()),
        connectionStatusProvider
            .overrideWith((ref) => ConnectionStatusNotifier()..setConnected()),
        modelProvider.overrideWith((ref) => ModelNotifier()),
        chatHistoryProvider.overrideWith((ref) => ChatHistoryNotifier()),
        grpcHostProvider
            .overrideWith((ref) => GrpcHostNotifier()..updateHost('test-host')),
        grpcPortProvider
            .overrideWith((ref) => GrpcPortNotifier()..updatePort(1234)),
        grpcSecureProvider
            .overrideWith((ref) => GrpcSecureNotifier()..setSecure(false)),
        initConnectionStatusProvider.overrideWith((ref) {}),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Chat handles whitespace-only messages', (tester) async {
      final chatController = container.read(chatProvider.notifier);
      final initialLength = container.read(chatHistoryProvider).length;

      // Try to send whitespace-only message
      await chatController.sendMessage("   \n\t   ");
      await tester.pump();

      // Should not add any messages (whitespace is trimmed to empty)
      expect(container.read(chatHistoryProvider).length, equals(initialLength));
    });

    testWidgets('Multiple rapid message sends', (tester) async {
      final chatController = container.read(chatProvider.notifier);

      // Send multiple messages rapidly
      final futures = <Future>[];
      for (int i = 0; i < 3; i++) {
        futures.add(chatController.sendMessage("Rapid message $i"));
      }

      // Wait for all to complete
      await Future.wait(futures);
      await tester.pump(const Duration(seconds: 2));

      // Should have all messages in history
      final messages = container.read(chatHistoryProvider);
      expect(messages.length, greaterThanOrEqualTo(6)); // 3 user + 3 assistant

      // Verify user messages are in order
      final userMessages = messages.where((m) => m.isUser).toList();
      expect(userMessages.length, equals(3));
      for (int i = 0; i < 3; i++) {
        expect(userMessages[i].content, equals("Rapid message $i"));
      }
    });
  });
}