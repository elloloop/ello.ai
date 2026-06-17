import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grpc/grpc.dart';
import '../generated/chat.pb.dart' as proto;
import '../generated/chat.pbgrpc.dart';
import '../llm_client/chat_client.dart';
import '../llm_client/openai_client.dart';
import '../llm_client/mock_client.dart';
import '../llm_client/grpc_client.dart';
import '../llm_client/mock_grpc_client.dart';
import '../llm_client/grpc_chat_client.dart';
import '../models/message.dart';
import '../services/chat_service_client.dart';
import '../services/enhanced_grpc_client.dart';
import '../utils/logger.dart';

/// ============================================================================
/// CONFIGURATION MODELS
/// ============================================================================

/// Configuration for gRPC connection
class GrpcConnectionConfig {
  final String host;
  final int port;
  final bool secure;

  const GrpcConnectionConfig({
    required this.host,
    required this.port,
    this.secure = false,
  });
}

/// ============================================================================
/// STATE NOTIFIERS
/// ============================================================================

/// Chat history notifier
class ChatHistoryNotifier extends StateNotifier<List<Message>> {
  ChatHistoryNotifier() : super([]);

  void addUserMessage(String content) {
    state = [...state, Message.user(content)];
  }

  void addAssistantMessage(String content) {
    state = [...state, Message.assistant(content)];
  }

  void appendToLastMessage(String content) {
    if (state.isEmpty) {
      addAssistantMessage(content);
      return;
    }

    final last = state.last;
    state = [
      ...state.sublist(0, state.length - 1),
      last.appendContent(content)
    ];
  }

  void clear() {
    state = [];
  }
}

/// Model selection notifier
class ModelNotifier extends StateNotifier<String> {
  ModelNotifier() : super('gpt-3.5-turbo');

  void selectModel(String model) {
    state = model;
  }
}

/// gRPC host notifier
class GrpcHostNotifier extends StateNotifier<String> {
  GrpcHostNotifier() : super('grpc-server-4rwujpfquq-uc.a.run.app');

  void updateHost(String host) {
    state = host;
  }
}

/// gRPC port notifier
class GrpcPortNotifier extends StateNotifier<int> {
  GrpcPortNotifier() : super(443);

  void updatePort(int port) {
    state = port;
  }

  void setForDebug() {
    state = 50051; // Common local development port for gRPC
  }

  void setForProduction() {
    state = 443; // HTTPS port for production
  }
}

/// gRPC secure connection notifier
class GrpcSecureNotifier extends StateNotifier<bool> {
  GrpcSecureNotifier() : super(true);

  void toggle() {
    state = !state;
  }

  void setSecure(bool value) {
    state = value;
  }
}

/// Mock gRPC notifier
class MockGrpcNotifier extends StateNotifier<bool> {
  MockGrpcNotifier() : super(false);

  void toggle() {
    state = !state;
  }
}

/// Direct API notifier
class DirectApiNotifier extends StateNotifier<bool> {
  DirectApiNotifier() : super(false);

  void toggle() {
    state = !state;
  }
}

/// Chat client notifier
class ChatClientNotifier extends StateNotifier<ChatClient> {
  ChatClientNotifier(this.ref) : super(_createInitialClient(ref));

  final Ref ref;

  static ChatClient _createInitialClient(Ref ref) {
    final useDirectApi = ref.read(useDirectApiProvider);
    final useMock = ref.read(useMockGrpcProvider);
    final host = ref.read(grpcHostProvider);
    final port = ref.read(grpcPortProvider);
    final secure = ref.read(grpcSecureProvider);

    // Check if we're connecting to Cloud Run
    bool isCloudRun = host.contains('run.app');

    // If connecting to Cloud Run, always use secure connection
    final effectiveSecure = isCloudRun ? true : secure;

    Logger.info('Creating initial chat client:');
    Logger.info('- useDirectApi: $useDirectApi');
    Logger.info('- useMockGrpc: $useMock');
    Logger.info('- gRPC host: $host');
    Logger.info('- gRPC port: $port');
    Logger.info('- gRPC secure: $effectiveSecure');
    Logger.info('- isCloudRun: $isCloudRun');

    if (useDirectApi) {
      // Use direct API connection (OpenAI)
      const key = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
      return key.isEmpty ? MockClient() : OpenAIClient(key);
    } else if (useMock) {
      // Use mock client when explicitly requested
      Logger.info('Using mock gRPC client as requested (useMock: true)');
      return MockGrpcClient();
    } else {
      try {
        // Try to create a real gRPC client
        // Use the already initialized client from the provider
        final chatGrpcClient = ref.read(chatGrpcClientProvider);

        // Re-initialize the client to ensure it's using the latest settings
        try {
          chatGrpcClient.init(
            host: host,
            port: port,
            secure: effectiveSecure,
          );
          Logger.info('Successfully initialized gRPC client');
        } catch (e) {
          Logger.error('Error re-initializing gRPC client: $e');
          // Continue with the existing client
        }

        return GrpcChatClient(chatGrpcClient);
      } catch (e) {
        // Fallback to mock if connection fails during initialization
        Logger.error(
            'Error creating initial gRPC client: $e, falling back to mock');
        return MockGrpcClient();
      }
    }
  }

  void updateClient() {
    final useDirectApi = ref.read(useDirectApiProvider);
    final useMock = ref.read(useMockGrpcProvider);
    final host = ref.read(grpcHostProvider);
    final port = ref.read(grpcPortProvider);
    final secure = ref.read(grpcSecureProvider);

    // Check if we're connecting to Cloud Run
    bool isCloudRun = host.contains('run.app');

    // If connecting to Cloud Run, always use secure connection
    final effectiveSecure = isCloudRun ? true : secure;

    Logger.info('Updating chat client:');
    Logger.info('- useDirectApi: $useDirectApi');
    Logger.info('- useMockGrpc: $useMock');
    Logger.info('- gRPC host: $host');
    Logger.info('- gRPC port: $port');
    Logger.info('- gRPC secure: $effectiveSecure');
    Logger.info('- isCloudRun: $isCloudRun');

    // DO NOT update connection status during initialization
    // We'll use a separate function to update status after providers are initialized

    if (useDirectApi) {
      // Use direct API connection (OpenAI)
      const key = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
      state = key.isEmpty ? MockClient() : OpenAIClient(key);
      Logger.info(
          'Selected client: ${key.isEmpty ? "MockClient" : "OpenAIClient"}');
    } else {
      // Use gRPC connection (default)
      // Use mock client for testing when requested
      if (useMock) {
        state = MockGrpcClient();
        Logger.info('Selected client: MockGrpcClient (mock mode)');
        return;
      }

      try {
        // Configure gRPC connection
        // Use the already initialized client from the provider
        final chatGrpcClient = ref.read(chatGrpcClientProvider);

        // Re-initialize the client to ensure it's using the latest settings
        try {
          chatGrpcClient.init(
            host: host,
            port: port,
            secure: effectiveSecure,
          );
          Logger.info('Successfully re-initialized gRPC client');
        } catch (e) {
          Logger.error('Error re-initializing gRPC client: $e');
          // Continue with the existing client
        }

        // Set the client implementation that uses our gRPC service
        state = GrpcChatClient(chatGrpcClient);
        Logger.info('Selected client: GrpcChatClient (real server connection)');
      } catch (e) {
        // Fallback to mock if connection fails
        Logger.error('Error creating gRPC client: $e, falling back to mock');
        state = MockGrpcClient();
        Logger.info('Selected client: MockGrpcClient (fallback due to error)');
      }
    }
  }
}

/// Chat controller notifier
class ChatController extends StateNotifier<AsyncValue<void>> {
  ChatController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  @override
  void dispose() {
    // Close gRPC channel if the client is a GrpcClient
    final client = ref.read(currentChatClientProvider);
    if (client is GrpcClient) {
      client.dispose();
    }
    super.dispose();
  }

  Future<void> sendMessage(String content) async {
    if (content.isEmpty) return;

    final chatHistory = ref.read(chatHistoryProvider.notifier);
    chatHistory.addUserMessage(content);

    state = const AsyncLoading();
    final client = ref.read(currentChatClientProvider);
    final selectedModel = ref.read(modelProvider);
    final messages = ref.read(chatHistoryProvider);

    // Check if we're using mock client - reset counter if so
    final isMock = client.toString().contains('Mock');
    if (isMock) {
      ref.read(connectionFailCounterProvider.notifier).state = 0;
    }

    // We'll update connection status separately from provider initialization
    // Instead of updating in the provider, do it after all providers are ready
    Future.microtask(() {
      if (!isMock) {
        ref.read(connectionStatusProvider.notifier).setConnecting();
      }
    });

    try {
      // If we're using the gRPC client, check for conversation ID
      if (client is GrpcChatClient) {
        final grpcClient = ref.read(chatGrpcClientProvider);

        // Check if we have an active conversation
        if (!grpcClient.hasActiveConversation) {
          Logger.info(
              'No active conversation detected, attempting to start one');
          try {
            // Try to start a new conversation
            final clientId = 'client-${DateTime.now().millisecondsSinceEpoch}';
            final response =
                await grpcClient.startConversation(clientId: clientId);

            // Update the conversation ID in the provider
            ref
                .read(conversationIdProvider.notifier)
                .setConversationId(response.conversationId);

            Logger.info(
                'Successfully started new conversation before sending message');

            // Inform the user
            chatHistory
                .addAssistantMessage('Started a new conversation session.');
          } catch (e) {
            Logger.warning(
                'Failed to start conversation: $e, will try with message send');
            // We'll let the message send flow handle it
          }
        }
      }

      await for (final chunk
          in client.chat(messages: messages, model: selectedModel)) {
        if (messages.isEmpty || messages.last.isUser) {
          chatHistory.addAssistantMessage(chunk);
        } else {
          chatHistory.appendToLastMessage(chunk);
        }
      }
      state = const AsyncData(null);

      // Reset fail counter on success and update connection status
      ref.read(connectionFailCounterProvider.notifier).state = 0;

      // Update connection status after successful message
      Future.microtask(() {
        if (!isMock) {
          ref.read(connectionStatusProvider.notifier).setConnected();
        }
      });
    } catch (e) {
      Logger.error('Error in chat stream: $e');

      // Update connection status to failed for real clients
      Future.microtask(() {
        if (!isMock) {
          ref.read(connectionStatusProvider.notifier).setFailed();
        }
      });

      // Check for conversation not found errors and handle them specially
      if (e.toString().contains('Conversation') &&
          e.toString().contains('not found')) {
        Logger.info(
            'Detected conversation not found error, clearing conversation ID');

        // Clear the conversation ID in the provider
        ref.read(conversationIdProvider.notifier).clearConversationId();

        // If using gRPC client, reset its conversation ID too
        if (client is GrpcChatClient) {
          final grpcClient = ref.read(chatGrpcClientProvider);
          grpcClient.resetConversation();

          // Try to start a new conversation for next time
          try {
            final clientId =
                'recovery-${DateTime.now().millisecondsSinceEpoch}';
            await grpcClient.startConversation(clientId: clientId);
          } catch (startError) {
            Logger.error('Failed to restart conversation: $startError');
          }
        }

        // Add a message informing the user
        chatHistory.addAssistantMessage(
            'Previous conversation was not found or expired. Starting a new conversation.');

        // Don't show additional error messages in this case
        state = const AsyncData(null);
        return;
      }

      // Add error message to chat for other types of errors
      if (messages.isEmpty || messages.last.isUser) {
        String errorMsg = 'Error: Unable to get response from the server. ';

        // Get user-friendly error message if possible
        if (client is GrpcChatClient) {
          // Access the underlying ChatGrpcClient to get the friendly error message
          final chatGrpcClient = ref.read(chatGrpcClientProvider);
          errorMsg = chatGrpcClient.getUserFriendlyErrorMessage(e);
        }
        // Fallback to generic error categorization
        else if (e.toString().contains('Operation not permitted') ||
            e.toString().contains('UNAVAILABLE')) {
          errorMsg += 'The app is unable to connect to the server.\n\n';
          errorMsg += 'Possible solutions:\n';
          errorMsg += '1. Check your internet connection\n';
          errorMsg +=
              '2. Enable Mock Mode in the debug settings (recommended)\n';
          errorMsg += '3. Try again later';

          // If auto-fallback is not enabled, suggest it
          if (!ref.read(autoFallbackToMockProvider)) {
            errorMsg +=
                '\n\nNote: You can enable auto-fallback to Mock Mode in Debug Settings';
          }
        } else {
          // General error case
          errorMsg += '${e.toString()}\n\n';
          errorMsg +=
              'If you\'re seeing connection issues, you can enable Mock Mode in the debug settings.';
        }

        chatHistory.addAssistantMessage(errorMsg);
      } else {
        chatHistory.appendToLastMessage(
            '\n\nError: Connection interrupted. ${e.toString()}');
      }

      state = AsyncError(e, StackTrace.current);

      // If we're in real mode and we get an error, increment the fail counter
      if (!isMock) {
        final currentFailCount = ref.read(connectionFailCounterProvider);
        ref.read(connectionFailCounterProvider.notifier).state =
            currentFailCount + 1;

        // Check if we should auto-fallback to mock mode
        final maxAttempts = ref.read(maxConnectionAttemptsProvider);
        final shouldAutoFallback = ref.read(autoFallbackToMockProvider);

        Logger.info(
            'Connection failure count: ${currentFailCount + 1}/$maxAttempts (Auto-fallback: $shouldAutoFallback)');

        if (shouldAutoFallback && currentFailCount + 1 >= maxAttempts) {
          Logger.info(
              'Maximum connection failures reached, auto-switching to mock mode');

          // Only toggle if we're not already in mock mode
          if (!ref.read(useMockGrpcProvider)) {
            ref.read(useMockGrpcProvider.notifier).toggle();

            // Add a message to inform the user
            chatHistory.addAssistantMessage(
                'Auto-switched to Mock Mode after $maxAttempts failed connection attempts.\n'
                'You can change this setting in the debug menu.');
          }
        }
      }
    }
  }

  // Reset the current conversation
  Future<void> resetConversation() async {
    final chatHistory = ref.read(chatHistoryProvider.notifier);
    final client = ref.read(currentChatClientProvider);

    try {
      // Clear the conversation ID in the provider
      ref.read(conversationIdProvider.notifier).clearConversationId();

      // If using gRPC client, reset its conversation ID too
      if (client is GrpcChatClient) {
        final grpcClient = ref.read(chatGrpcClientProvider);
        grpcClient.resetConversation();

        // Try to start a new conversation right away
        try {
          final clientId = 'reset-${DateTime.now().millisecondsSinceEpoch}';
          final response =
              await grpcClient.startConversation(clientId: clientId);

          // Update the conversation ID in the provider
          ref
              .read(conversationIdProvider.notifier)
              .setConversationId(response.conversationId);

          Logger.info('Successfully started new conversation after reset');
        } catch (e) {
          Logger.error('Failed to start new conversation after reset: $e');
          // We'll try again with the next message
        }
      }

      // Add a message to inform the user
      chatHistory.addAssistantMessage(
          'Conversation has been reset. Starting a new session.');
    } catch (e) {
      Logger.error('Error resetting conversation: $e');
      chatHistory.addAssistantMessage('Error resetting conversation: $e');
    }
  }
}

/// Conversation ID notifier
class ConversationIdNotifier extends StateNotifier<String?> {
  ConversationIdNotifier() : super(null);

  void setConversationId(String? id) {
    Logger.debug('Setting conversation ID: $id');
    state = id;
  }

  void clearConversationId() {
    Logger.debug('Clearing conversation ID');
    state = null;
  }
}

/// ============================================================================
/// PROVIDERS
/// ============================================================================

/// Model selection provider
final modelProvider =
    StateNotifierProvider<ModelNotifier, String>((ref) => ModelNotifier());

/// Model provider configuration
class ModelProvider {
  final String id;
  final String name;
  final List<String> models;
  final String apiKeyName;
  final String Function(String)? validateKey;

  const ModelProvider({
    required this.id,
    required this.name,
    required this.models,
    required this.apiKeyName,
    this.validateKey,
  });
}

/// Available model providers
final modelProvidersProvider = Provider<List<ModelProvider>>((ref) => [
      ModelProvider(
        id: 'openai',
        name: 'OpenAI',
        models: ['gpt-3.5-turbo', 'gpt-4o', 'gpt-4-turbo', 'gpt-4'],
        apiKeyName: 'OpenAI API Key',
        validateKey: (key) => key.startsWith('sk-') ? '' : 'OpenAI keys must start with "sk-"',
      ),
      ModelProvider(
        id: 'anthropic',
        name: 'Anthropic',
        models: ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'],
        apiKeyName: 'Anthropic API Key',
        validateKey: (key) => key.startsWith('sk-ant-') ? '' : 'Anthropic keys must start with "sk-ant-"',
      ),
      ModelProvider(
        id: 'google',
        name: 'Google',
        models: ['gemini-pro', 'gemini-1.5-pro'],
        apiKeyName: 'Google API Key',
        validateKey: (key) => key.length > 30 ? '' : 'Google API key appears to be too short',
      ),
      ModelProvider(
        id: 'meta',
        name: 'Meta',
        models: ['llama-3', 'llama-2'],
        apiKeyName: 'Meta/Llama API Key',
      ),
    ]);

/// Legacy available models provider (for backward compatibility)
final availableModelsProvider = Provider<List<String>>((ref) {
  final providers = ref.watch(modelProvidersProvider);
  final apiKeys = ref.watch(apiKeysProvider);
  
  // If no API keys are configured, show all models
  if (apiKeys.values.every((key) => key.isEmpty)) {
    return providers.expand((provider) => provider.models).toList();
  }
  
  // Otherwise, only show models for providers with valid keys
  final availableModels = <String>[];
  for (final provider in providers) {
    final key = apiKeys[provider.id] ?? '';
    if (key.isNotEmpty) {
      // Validate key if validator exists
      if (provider.validateKey != null) {
        final validationError = provider.validateKey!(key);
        if (validationError.isEmpty) {
          availableModels.addAll(provider.models);
        }
      } else {
        // No validation, assume valid if not empty
        availableModels.addAll(provider.models);
      }
    }
  }
  
  return availableModels;
});

/// API Keys Management
class ApiKeysNotifier extends StateNotifier<Map<String, String>> {
  ApiKeysNotifier() : super({
    'openai': const String.fromEnvironment('OPENAI_API_KEY', defaultValue: ''),
    'anthropic': const String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: ''),
    'google': const String.fromEnvironment('GOOGLE_API_KEY', defaultValue: ''),
    'meta': const String.fromEnvironment('META_API_KEY', defaultValue: ''),
  });

  void setApiKey(String providerId, String key) {
    state = {...state, providerId: key};
  }

  void removeApiKey(String providerId) {
    state = {...state, providerId: ''};
  }

  String? getApiKey(String providerId) {
    return state[providerId];
  }

  bool hasValidKey(String providerId) {
    final key = state[providerId] ?? '';
    return key.isNotEmpty;
  }
}

/// API Keys provider
final apiKeysProvider =
    StateNotifierProvider<ApiKeysNotifier, Map<String, String>>((ref) => ApiKeysNotifier());

/// API Key validation results provider
final apiKeyValidationProvider = Provider<Map<String, String>>((ref) {
  final apiKeys = ref.watch(apiKeysProvider);
  final providers = ref.watch(modelProvidersProvider);
  final validationResults = <String, String>{};
  
  for (final provider in providers) {
    final key = apiKeys[provider.id] ?? '';
    if (key.isNotEmpty && provider.validateKey != null) {
      validationResults[provider.id] = provider.validateKey!(key);
    } else {
      validationResults[provider.id] = '';
    }
  }
  
  return validationResults;
});

/// gRPC host provider
final grpcHostProvider = StateNotifierProvider<GrpcHostNotifier, String>(
    (ref) => GrpcHostNotifier());

/// gRPC port provider
final grpcPortProvider =
    StateNotifierProvider<GrpcPortNotifier, int>((ref) => GrpcPortNotifier());

/// gRPC secure connection provider
final grpcSecureProvider = StateNotifierProvider<GrpcSecureNotifier, bool>(
    (ref) => GrpcSecureNotifier());

/// Mock gRPC provider
final useMockGrpcProvider =
    StateNotifierProvider<MockGrpcNotifier, bool>((ref) => MockGrpcNotifier());

/// Direct API provider
final useDirectApiProvider = StateNotifierProvider<DirectApiNotifier, bool>(
    (ref) => DirectApiNotifier());

/// gRPC Web mode provider
// No longer needed as we only use standard gRPC with TLS for Cloud Run

/// Chat client provider
final currentChatClientProvider =
    StateNotifierProvider<ChatClientNotifier, ChatClient>((ref) {
  final notifier = ChatClientNotifier(ref);

  // Initial update
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Update client AFTER the first frame is rendered
    // This ensures that all providers are properly initialized
    notifier.updateClient();
  });

  // Update client when relevant providers change
  ref.listen(useDirectApiProvider, (_, __) => notifier.updateClient());
  ref.listen(useMockGrpcProvider, (_, __) => notifier.updateClient());
  ref.listen(grpcHostProvider, (_, __) => notifier.updateClient());
  ref.listen(grpcPortProvider, (_, __) => notifier.updateClient());
  ref.listen(grpcSecureProvider, (_, __) => notifier.updateClient());

  return notifier;
});

/// Chat history provider
final chatHistoryProvider =
    StateNotifierProvider<ChatHistoryNotifier, List<Message>>(
        (ref) => ChatHistoryNotifier());

/// Chat controller provider
final chatProvider = StateNotifierProvider<ChatController, AsyncValue<void>>(
    (ref) => ChatController(ref));

/// gRPC client provider
final chatGrpcClientProvider = Provider<ChatGrpcClient>((ref) {
  final chatGrpcClient = ChatGrpcClient();

  // Initialize the client immediately with default settings
  // This ensures the client is always initialized before use
  final host = ref.read(grpcHostProvider);
  final port = ref.read(grpcPortProvider);
  final secure = ref.read(grpcSecureProvider);

  // Check if we're connecting to Cloud Run
  bool isCloudRun = host.contains('run.app');

  // If connecting to Cloud Run, always use secure connection
  final effectiveSecure = isCloudRun ? true : secure;

  try {
    // Initialize the client when the provider is created
    chatGrpcClient.init(
      host: host,
      port: port,
      secure: effectiveSecure,
    );
    Logger.info('Successfully initialized gRPC client at startup');
  } catch (e) {
    Logger.error('Error initializing gRPC client at startup: $e');
    // We don't rethrow here to avoid crashing the app during initialization
    // The client will attempt reconnection when needed
  }

  return chatGrpcClient;
});

/// Enhanced gRPC client provider - a more robust implementation based on Python client
final enhancedGrpcClientProvider = Provider<EnhancedGrpcChatClient>((ref) {
  // Get the gRPC client from the proto
  final chatServiceClient = ref.watch(chatServiceClientProvider);

  // Create the enhanced client
  final client = EnhancedGrpcChatClient(chatServiceClient);

  // Listen for connection status changes
  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

/// gRPC connection provider
final grpcConnectionProvider =
    FutureProvider.family<void, GrpcConnectionConfig>((ref, config) async {
  final client = ref.watch(chatGrpcClientProvider);
  await client.init(
    host: config.host,
    port: config.port,
    secure: config.secure,
  );
});

/// Chat stream provider
final chatStreamProvider =
    StreamProvider.family<proto.ChatMessage, List<dynamic>>((ref, messages) {
  final client = ref.watch(chatGrpcClientProvider);

  try {
    // Make sure the client is initialized before trying to use it
    final host = ref.read(grpcHostProvider);
    final port = ref.read(grpcPortProvider);
    final secure = ref.read(grpcSecureProvider);
    bool isCloudRun = host.contains('run.app');
    final effectiveSecure = isCloudRun ? true : secure;

    // Try to initialize if it hasn't been already
    try {
      client.init(
        host: host,
        port: port,
        secure: effectiveSecure,
      );
    } catch (e) {
      Logger.error('Error initializing gRPC client in streamProvider: $e');
      // Continue anyway and try to use the client
    }

    // Get the current conversation ID from the provider
    final conversationId = ref.read(conversationIdProvider);

    // If we don't have a conversation ID, start a new one
    if (conversationId == null || conversationId.isEmpty) {
      Logger.info('No active conversation ID, starting a new one');
      // Start a new conversation asynchronously
      // We'll let the client handle the sequencing
    } else {
      Logger.info('Using existing conversation ID: $conversationId');
      // Ensure the client has the same conversation ID
      client.conversationId = conversationId;
    }

    // Convert app messages to our model
    final appMessages = messages
        .map((m) => Message(content: m.content, isUser: m.role == 'user'))
        .toList();

    // Call the updated chatStream method
    return client.chatStream(appMessages);
  } catch (e) {
    // Convert to a stream that emits an error
    return Stream.error(e);
  }
});

/// ============================================================================
/// DEBUG UTILITIES
/// ============================================================================

/// Connection fail counter to track failures
final connectionFailCounterProvider = StateProvider<int>((ref) => 0);

/// Auto-fallback to mock after certain number of failures
final autoFallbackToMockProvider = StateProvider<bool>((ref) => true);

/// Maximum connection attempts before auto-fallback
final maxConnectionAttemptsProvider = Provider<int>((ref) => 3);

/// Provider that determines if the app is running in debug mode
final isDebugModeProvider = Provider<bool>((ref) {
  // In a real app, we would use kDebugMode from foundation.dart
  return kDebugMode;
});

/// ============================================================================
/// CONNECTION STATUS PROVIDER
/// ============================================================================

/// Connection status states
enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  failed,
}

/// Connection status notifier
class ConnectionStatusNotifier extends StateNotifier<ConnectionStatus> {
  ConnectionStatusNotifier() : super(ConnectionStatus.disconnected);

  void setConnected() {
    state = ConnectionStatus.connected;
  }

  void setConnecting() {
    state = ConnectionStatus.connecting;
  }

  void setDisconnected() {
    state = ConnectionStatus.disconnected;
  }

  void setFailed() {
    state = ConnectionStatus.failed;
  }
}

/// Connection status provider
final connectionStatusProvider =
    StateNotifierProvider<ConnectionStatusNotifier, ConnectionStatus>(
        (ref) => ConnectionStatusNotifier());

/// Initialize connection status provider
/// This will safely initialize the connection status after all providers are ready
final initConnectionStatusProvider = Provider<void>((ref) {
  // Access the providers to create dependency
  final useDirectApi = ref.watch(useDirectApiProvider);
  final useMock = ref.watch(useMockGrpcProvider);
  final client = ref.watch(currentChatClientProvider);

  // Update connection status after provider initialization
  Future.microtask(() {
    if (useMock) {
      ref.read(connectionStatusProvider.notifier).setConnected();
    } else if (useDirectApi) {
      const key = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
      if (key.isEmpty) {
        ref.read(connectionStatusProvider.notifier).setDisconnected();
      } else {
        ref.read(connectionStatusProvider.notifier).setConnected();
      }
    } else {
      // Check if client is GrpcChatClient
      if (client is GrpcChatClient) {
        // Try to determine if it's actually connected
        try {
          ref.read(connectionStatusProvider.notifier).setConnected();
        } catch (e) {
          ref.read(connectionStatusProvider.notifier).setFailed();
        }
      } else {
        ref.read(connectionStatusProvider.notifier).setDisconnected();
      }
    }
  });

  return;
});

/// Conversation ID provider
final conversationIdProvider =
    StateNotifierProvider<ConversationIdNotifier, String?>((ref) {
  final notifier = ConversationIdNotifier();

  // Listen to changes in the chatGrpcClient
  ref.listen(chatGrpcClientProvider, (previous, next) {
    if (next.conversationId != null) {
      notifier.setConversationId(next.conversationId);
    }
  });

  return notifier;
});

/// Provider to check if there's an active conversation
final hasActiveConversationProvider = Provider<bool>((ref) {
  final conversationId = ref.watch(conversationIdProvider);
  return conversationId != null && conversationId.isNotEmpty;
});

/// Start a new conversation provider
final startConversationProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(chatGrpcClientProvider);

  try {
    // Generate a unique client ID
    final clientId = 'client-${DateTime.now().millisecondsSinceEpoch}';

    // Start a new conversation
    final response = await client.startConversation(clientId: clientId);

    // Update the conversation ID in the provider
    ref
        .read(conversationIdProvider.notifier)
        .setConversationId(response.conversationId);

    return response.conversationId;
  } catch (e) {
    Logger.error('Error starting conversation in provider: $e');
    // Clear the conversation ID on error
    ref.read(conversationIdProvider.notifier).clearConversationId();
    throw Exception('Failed to start conversation: $e');
  }
});

/// Cloud Run connection configuration provider
final cloudRunConnectionProvider = Provider<GrpcConnectionConfig>((ref) {
  // Default Cloud Run URL from previous deployment
  const defaultCloudRunUrl = 'grpc-server-4rwujpfquq-uc.a.run.app';

  // For Cloud Run, we always use port 443 and secure connection
  return const GrpcConnectionConfig(
    host: defaultCloudRunUrl,
    port: 443,
    secure: true,
  );
});

/// ChatServiceClient provider for raw gRPC generated client
final chatServiceClientProvider = Provider<ChatServiceClient>((ref) {
  // Get the gRPC configuration
  final host = ref.watch(grpcHostProvider);
  final port = ref.watch(grpcPortProvider);
  final secure = ref.watch(grpcSecureProvider);

  // Create channel options
  final options = ChannelOptions(
    credentials: secure
        ? const ChannelCredentials.secure()
        : const ChannelCredentials.insecure(),
    codecRegistry: CodecRegistry(codecs: const [GzipCodec(), IdentityCodec()]),
    connectionTimeout: const Duration(seconds: 15),
  );

  // Create channel
  final channel = ClientChannel(
    host,
    port: port,
    options: options,
  );

  // Create and return the client
  return ChatServiceClient(channel);
});
