import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/core/dependencies.dart';
import 'package:ello_ai/src/models/message.dart';

/// Test helpers for creating consistent test setups across the application
class TestHelpers {
  /// Creates a standard mocked ProviderContainer for testing
  static ProviderContainer createMockContainer({
    List<Message> messages = const [],
    ConnectionStatus connectionStatus = ConnectionStatus.connected,
    bool useMockGrpc = true,
    bool hasActiveConversation = false,
    String selectedModel = 'gpt-3.5-turbo',
    List<String> availableModels = const ['gpt-3.5-turbo', 'gpt-4o'],
    bool isDebugMode = true,
    String grpcHost = 'mock-host',
    int grpcPort = 1234,
    bool grpcSecure = false,
    bool autoFallback = false,
    int failCount = 0,
    int maxAttempts = 3,
  }) {
    return ProviderContainer(overrides: [
      // Chat history with preloaded messages
      chatHistoryProvider.overrideWith((ref) {
        final notifier = ChatHistoryNotifier();
        for (final message in messages) {
          if (message.isUser) {
            notifier.addUserMessage(message.content);
          } else {
            notifier.addAssistantMessage(message.content);
          }
        }
        return notifier;
      }),
      
      // Connection status
      connectionStatusProvider.overrideWith((ref) {
        final notifier = ConnectionStatusNotifier();
        switch (connectionStatus) {
          case ConnectionStatus.connected:
            notifier.setConnected();
            break;
          case ConnectionStatus.connecting:
            notifier.setConnecting();
            break;
          case ConnectionStatus.disconnected:
            notifier.setDisconnected();
            break;
          case ConnectionStatus.failed:
            notifier.setFailed();
            break;
        }
        return notifier;
      }),
      
      // Mock gRPC setting
      useMockGrpcProvider.overrideWith((ref) {
        final notifier = MockGrpcNotifier();
        if (useMockGrpc) notifier.toggle();
        return notifier;
      }),
      
      // Model selection
      modelProvider.overrideWith((ref) => ModelNotifier()..selectModel(selectedModel)),
      availableModelsProvider.overrideWith((ref) => availableModels),
      
      // Debug mode
      isDebugModeProvider.overrideWith((ref) => isDebugMode),
      
      // gRPC connection settings
      grpcHostProvider.overrideWith((ref) => GrpcHostNotifier()..updateHost(grpcHost)),
      grpcPortProvider.overrideWith((ref) => GrpcPortNotifier()..updatePort(grpcPort)),
      grpcSecureProvider.overrideWith((ref) => GrpcSecureNotifier()..setSecure(grpcSecure)),
      
      // Connection handling
      autoFallbackToMockProvider.overrideWith((ref) => autoFallback),
      connectionFailCounterProvider.overrideWith((ref) => failCount),
      maxConnectionAttemptsProvider.overrideWith((ref) => maxAttempts),
      
      // Conversation state
      hasActiveConversationProvider.overrideWith((ref) => hasActiveConversation),
      conversationIdProvider.overrideWith((ref) => ConversationIdNotifier()),
      
      // Additional providers that may be referenced
      chatProvider.overrideWith((ref) => ChatController(ref)),
      isDebugModeProvider.overrideWith((ref) => isDebugMode),
      
      // Initialization
      initConnectionStatusProvider.overrideWith((ref) {}),
    ]);
  }

  /// Creates test messages for common scenarios
  static List<Message> createTestConversation() {
    return [
      Message.user('Hello, how are you?'),
      Message.assistant('I\'m doing well, thank you! How can I help you today?'),
      Message.user('Can you help me with Flutter testing?'),
      Message.assistant('Absolutely! Flutter has excellent testing capabilities. You can write unit tests, widget tests, and integration tests.'),
    ];
  }

  /// Creates a conversation with error messages
  static List<Message> createErrorConversation() {
    return [
      Message.user('Test connection'),
      Message.assistant('Error: Connection failed to the server'),
      Message.user('Try again'),
      Message.assistant('Error: Unable to establish connection'),
    ];
  }

  /// Creates a long conversation for testing scrolling
  static List<Message> createLongConversation() {
    final messages = <Message>[];
    for (int i = 1; i <= 20; i++) {
      messages.add(Message.user('User message number $i'));
      messages.add(Message.assistant('Assistant response number $i with some longer content to test text wrapping and message display.'));
    }
    return messages;
  }

  /// Test configuration for different connection states
  static const testConnectionStates = [
    ConnectionStatus.connected,
    ConnectionStatus.connecting,
    ConnectionStatus.disconnected,
    ConnectionStatus.failed,
  ];

  /// Common model options for testing
  static const testModels = [
    'gpt-3.5-turbo',
    'gpt-4o',
    'claude-3-opus',
    'claude-3-sonnet',
    'gemini-pro',
    'llama-3',
    'custom-model',
  ];

  /// Helper to get connection status display text
  static String getConnectionStatusText(ConnectionStatus status, bool isMockMode) {
    if (isMockMode) return 'Mock Mode';
    
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.failed:
        return 'Disconnected';
    }
  }

  /// Helper to validate message structure in tests
  static bool validateMessageStructure(Message message) {
    return message.content.isNotEmpty;
  }

  /// Helper to create specific test scenarios
  static ProviderContainer createErrorScenario() {
    return createMockContainer(
      messages: createErrorConversation(),
      connectionStatus: ConnectionStatus.failed,
      useMockGrpc: false,
    );
  }

  static ProviderContainer createMockScenario() {
    return createMockContainer(
      messages: createTestConversation(),
      connectionStatus: ConnectionStatus.connected,
      useMockGrpc: true,
    );
  }

  static ProviderContainer createConnectingScenario() {
    return createMockContainer(
      connectionStatus: ConnectionStatus.connecting,
      useMockGrpc: false,
    );
  }

  static ProviderContainer createActiveConversationScenario() {
    return createMockContainer(
      messages: createTestConversation(),
      hasActiveConversation: true,
    );
  }
}