import 'package:grpc/grpc.dart';
import 'dart:async';
import 'dart:math' as math;
import '../generated/chat.pbgrpc.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../utils/logger.dart';

class ChatGrpcClient {
  ChatServiceClient? _client;
  ClientChannel? _channel;
  bool _isCloudRun = false;
  static const Uuid _uuid = Uuid(); // For generating message IDs
  String? _currentConversationId;
  int _recoveryAttempts = 0;
  final int _maxRecoveryAttempts = 3;

  // Singleton pattern
  static final ChatGrpcClient _instance = ChatGrpcClient._internal();
  factory ChatGrpcClient() => _instance;

  ChatGrpcClient._internal();

  Future<void> init({
    required String host,
    required int port,
    bool secure = false,
    int retryAttempts = 2,
  }) async {
    Logger.info('Initializing gRPC client: $host:$port (secure: $secure)');

    try {
      // Close any existing channel first
      await shutdown();

      // Special handling for Cloud Run servers
      _isCloudRun = host.contains('run.app');
      if (_isCloudRun && port == 443) {
        Logger.info(
            'Detected Cloud Run service, applying specialized configuration');
        secure = true; // Force secure connection for Cloud Run
      }

      // Create channel options with appropriate settings for Cloud Run
      final options = ChannelOptions(
        credentials: secure
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
        codecRegistry:
            CodecRegistry(codecs: const [GzipCodec(), IdentityCodec()]),
        // Add a longer timeout for cloud connections
        connectionTimeout: const Duration(seconds: 15),
      );

      _channel = ClientChannel(
        host,
        port: port,
        options: options,
      );

      _client = ChatServiceClient(_channel!);

      // Test connection with retry logic
      int attempts = 0;
      bool connected = false;
      Exception? lastError;

      while (attempts < retryAttempts && !connected) {
        try {
          Logger.info(
              'Testing gRPC connection (attempt ${attempts + 1}/$retryAttempts)...');
          await _channel!.getConnection().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Connection test timed out');
            },
          );
          connected = true;
          Logger.info('gRPC connection test successful!');
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          Logger.info('Connection attempt ${attempts + 1} failed: $e');

          // Log more specific information about common error types
          if (e.toString().contains('Operation not permitted')) {
            Logger.info(
                'This error often occurs due to network restrictions or firewall settings.');
            Logger.info(
                'Consider using Mock Mode if you\'re unable to resolve network issues.');
          } else if (e.toString().contains('UNAVAILABLE')) {
            Logger.info('The server appears to be unavailable or unreachable.');
            Logger.info(
                'Check that the server is running and accessible from your network.');
          }

          attempts++;

          if (attempts < retryAttempts) {
            Logger.info('Retrying in 1 second...');
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      if (!connected) {
        Logger.info('All connection attempts failed');
        throw lastError ??
            Exception('Failed to connect after $retryAttempts attempts');
      }
    } catch (e) {
      Logger.info('Error initializing gRPC client: $e');
      rethrow;
    }
  }

  // For compatibility with existing code, but just calls regular init
  // This will be removed in future releases
  Future<void> initWithWeb({
    required String host,
    required int port,
    bool secure = false,
    int retryAttempts = 2,
  }) async {
    Logger.info(
        'Note: gRPC-Web support has been removed, using standard gRPC for Cloud Run');

    // Just use regular gRPC with TLS for Cloud Run
    await init(
      host: host,
      port: port,
      secure: true, // Always use secure for Cloud Run
      retryAttempts: retryAttempts,
    );
  }

  Future<void> shutdown() async {
    try {
      if (_channel != null) {
        await _channel!.shutdown();
        _channel = null;
        _client = null;
        Logger.info('gRPC channel shut down successfully');
      }
    } catch (e) {
      Logger.info('Error shutting down gRPC channel: $e');
    }
  }

  Stream<ChatMessage> chatStream(List<Message> messages) {
    try {
      if (_client == null) {
        Logger.info('gRPC client not initialized, returning error stream');
        return Stream.error(
            Exception('gRPC client not initialized. Call init() first.'));
      }

      Logger.info('Creating chat stream with ${messages.length} messages');

      // Reset recovery counter for new conversation
      _resetRecoveryCounter();

      // Create a controller that we'll use to emit events
      final controller = StreamController<ChatMessage>();

      // Take the last (most recent) message as our request
      if (messages.isEmpty) {
        controller.addError(Exception('No messages provided'));
        controller.close();
        return controller.stream;
      }

      // Get the last message (which should be from the user)
      final lastMessage = messages.last;
      if (!lastMessage.isUser) {
        controller.addError(Exception('Last message must be from the user'));
        controller.close();
        return controller.stream;
      }

      // Create a ChatMessage from the last user message
      final chatMessage = ChatMessage(
        messageId: _uuid.v4(),
        content: lastMessage.content,
        type: MessageType.USER_QUERY,
        conversationId: _currentConversationId ?? '',
      );

      Logger.info('Preparing to send message: ${chatMessage.content}');

      // If no conversation ID exists yet, start a new conversation first
      if (_currentConversationId == null || _currentConversationId!.isEmpty) {
        Logger.info('No active conversation, starting a new one first');
        _startConversationAndChat(chatMessage, controller);
      } else {
        Logger.info('Using existing conversation ID: $_currentConversationId');
        // We already have a conversation ID, so just chat
        _sendChatMessage(chatMessage, controller);
      }

      // Add error handling for the controller's events
      controller.onCancel = () {
        Logger.info('Stream controller was canceled by the listener');
        // Ensure we don't try to use the controller after it's closed
        _resetRecoveryCounter(); // Reset the recovery counter when stream is cancelled
      };

      // When the stream is done, make sure we don't have dangling futures
      // trying to add events to a closed controller
      return controller.stream.transform(
        StreamTransformer<ChatMessage, ChatMessage>.fromHandlers(
            handleDone: (sink) {
          Logger.info('Stream marked as done');
          sink.close();
        }, handleError: (error, stackTrace, sink) {
          Logger.info('Error in stream: $error');
          sink.addError(error, stackTrace);
        }),
      );
    } catch (e) {
      Logger.info('Error creating chat stream: $e');
      return Stream.error(e);
    }
  }

  // Helper method to first start a conversation, then send the chat message
  void _startConversationAndChat(
      ChatMessage message, StreamController<ChatMessage> controller) {
    try {
      Logger.info('Starting new conversation before sending chat message');

      // First check if the controller is still open
      if (controller.isClosed) {
        Logger.info('Skipping conversation start - controller already closed');
        return;
      }

      // First start a conversation with a new client ID
      String clientId = 'client-${_uuid.v4()}';

      // Create a status message for the UI
      final statusMessage = ChatMessage()
        ..messageId = 'status-${_uuid.v4()}'
        ..content = 'Starting a new conversation...'
        ..type = MessageType.ASSISTANT_RESPONSE
        ..conversationId = '';

      if (!controller.isClosed) {
        controller.add(statusMessage);
      }

      startConversation(clientId: clientId).then((response) {
        if (controller.isClosed) {
          Logger.info(
              'Skipping conversation handling - controller already closed');
          return;
        }

        if (response.conversationId.isEmpty) {
          Logger.info('Warning: Server returned empty conversation ID');
          // Generate a client-side ID if server doesn't provide one
          _currentConversationId = 'client-gen-${_uuid.v4()}';
        } else {
          _currentConversationId = response.conversationId;
        }

        Logger.info(
            'Started new conversation with ID: $_currentConversationId');

        // Create a success message for the UI
        final successMessage = ChatMessage()
          ..messageId = 'success-${_uuid.v4()}'
          ..content =
              'Started new conversation (ID: ${_currentConversationId!.substring(0, math.min(8, _currentConversationId!.length))}...)'
          ..type = MessageType.ASSISTANT_RESPONSE
          ..conversationId = _currentConversationId!;

        if (!controller.isClosed) {
          controller.add(successMessage);
        }

        // Now update the message with the conversation ID
        final updatedMessage = ChatMessage()
          ..messageId = message.messageId
          ..content = message.content
          ..type = message.type
          ..conversationId = _currentConversationId!;

        // And send it after a short delay to ensure the conversation is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!controller.isClosed) {
            _sendChatMessage(updatedMessage, controller);
          } else {
            Logger.info('Skipping message send - controller already closed');
          }
        });
      }).catchError((error) {
        Logger.info('Error starting conversation: $error');

        if (controller.isClosed) {
          Logger.info('Skipping error handling - controller already closed');
          return;
        }

        // If we failed to start a conversation, create a fallback client-side ID
        _currentConversationId = 'fallback-${_uuid.v4()}';
        Logger.info('Using fallback conversation ID: $_currentConversationId');

        // Create an error message for the UI
        final errorMessage = ChatMessage()
          ..messageId = 'error-${_uuid.v4()}'
          ..content = 'Failed to start a new conversation, using fallback mode.'
          ..type = MessageType.ASSISTANT_RESPONSE
          ..conversationId = '';

        if (!controller.isClosed) {
          controller.add(errorMessage);
        }

        // Update message with fallback ID and send anyway
        final fallbackMessage = ChatMessage()
          ..messageId = message.messageId
          ..content = message.content
          ..type = message.type
          ..conversationId = _currentConversationId!;

        if (!controller.isClosed) {
          _sendChatMessage(fallbackMessage, controller);
        }
      });
    } catch (e) {
      Logger.info('Error in _startConversationAndChat: $e');
      if (!controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
    }
  }

  // Helper method to send a chat message and handle the response stream
  void _sendChatMessage(
      ChatMessage message, StreamController<ChatMessage> controller) {
    // Check if controller is already closed before doing anything
    if (controller.isClosed) {
      Logger.info('Skipping _sendChatMessage - controller is already closed');
      return;
    }

    try {
      // Verify we have a non-empty conversation ID
      if (message.conversationId.isEmpty) {
        Logger.info(
            'Warning: Message has empty conversation ID, generating one');
        message.conversationId = 'generated-${_uuid.v4()}';
      }

      Logger.info(
          'Sending message to conversation ID: ${message.conversationId}');

      // Call the Chat method which returns a stream of ChatMessage
      final responseStream = _client!.chat(message);

      // Forward all responses to our controller
      responseStream.listen(
        (response) {
          Logger.info(
              'Received response: ${response.content.substring(0, response.content.length > 50 ? 50 : response.content.length)}...');

          // Check for conversation not found error messages in the response content
          if (response.content.contains("conversation not found") ||
              response.content.contains("conversation expired") ||
              response.content.contains("conversation does not exist")) {
            Logger.info(
                'Detected conversation not found error in response content');

            // Handle as a conversation not found error
            _currentConversationId = null;

            // Create a special message to inform the client
            final errorMessage = ChatMessage()
              ..messageId = 'error-${_uuid.v4()}'
              ..content =
                  'Previous conversation was not found or expired. Starting a new conversation.'
              ..type = MessageType.ASSISTANT_RESPONSE
              ..conversationId = '';

            // Make sure controller is still open before adding events
            if (!controller.isClosed) {
              controller.add(errorMessage);

              // Try to start a new conversation
              handleConversationNotFound().then((_) {
                // Only proceed if the controller is still open
                if (!controller.isClosed) {
                  // Create a follow-up message with instructions
                  final followUpMessage = ChatMessage()
                    ..messageId = 'follow-up-${_uuid.v4()}'
                    ..content =
                        'Please send your message again to continue with the new conversation.'
                    ..type = MessageType.ASSISTANT_RESPONSE
                    ..conversationId = _currentConversationId ?? '';

                  controller.add(followUpMessage);
                } else {
                  Logger.info(
                      'Skipping follow-up message - controller already closed');
                }
              }).catchError((e) {
                Logger.info('Error during conversation recovery: $e');
                // Don't try to use the controller if there's an error in recovery
              });
            } else {
              Logger.info(
                  'Skipping error handling - controller already closed');
            }

            return;
          }

          // If this is an assistant response with a conversation ID, save it
          if (response.type == MessageType.ASSISTANT_RESPONSE &&
              response.conversationId.isNotEmpty) {
            _currentConversationId = response.conversationId;
            Logger.info('Saved conversation ID: $_currentConversationId');
          }

          controller.add(response);
        },
        onError: (error) {
          Logger.info('Error from server: $error');

          // Special handling for conversation not found
          if (error.toString().contains('Conversation') &&
              error.toString().contains('not found')) {
            Logger.info(
                'Conversation not found, restarting with new conversation');
            // Clear the conversation ID
            _currentConversationId = null;

            // Create a system message to inform about the error
            final errorMessage = ChatMessage()
              ..messageId = 'error-${_uuid.v4()}'
              ..content =
                  'Previous conversation was not found or expired. Starting a new conversation.'
              ..type = MessageType.ASSISTANT_RESPONSE
              ..conversationId = '';

            // Make sure controller is still open before adding events
            if (!controller.isClosed) {
              controller.add(errorMessage);

              // Try to start a new conversation and automatically retry sending the message
              handleConversationNotFound().then((_) {
                Logger.info(
                    'Automatically retrying message after conversation recovery');

                // Only proceed if the controller is still open
                if (!controller.isClosed) {
                  // Update the message with the new conversation ID
                  final updatedMessage = ChatMessage()
                    ..messageId = message.messageId
                    ..content = message.content
                    ..type = message.type
                    ..conversationId = _currentConversationId ?? '';

                  // Send it again after a short delay to ensure the new conversation is ready
                  Future.delayed(const Duration(milliseconds: 500), () {
                    // Check again before sending
                    if (!controller.isClosed) {
                      _sendChatMessage(updatedMessage, controller);
                    } else {
                      Logger.info(
                          'Skipping retry after recovery - controller already closed');
                    }
                  });
                } else {
                  Logger.info(
                      'Skipping retry after recovery - controller already closed');
                }
              }).catchError((e) {
                Logger.info('Error during conversation recovery: $e');
                // Don't try to use the controller if there's an error in recovery
              });
            } else {
              Logger.info(
                  'Skipping error handling - controller already closed');
            }

            return;
          }

          controller.addError(getUserFriendlyErrorMessage(error));
        },
        onDone: () {
          Logger.info('Server stream complete');
          controller.close();
        },
      );
    } catch (e) {
      Logger.info('Error calling Chat method: $e');
      controller.addError(Exception('Error calling Chat method: $e'));
      controller.close();
    }
  }

  // Track progress of a request
  Stream<ProgressUpdate> trackProgress(String requestId) {
    try {
      if (_client == null) {
        Logger.info('gRPC client not initialized, returning error stream');
        return Stream.error(
            Exception('gRPC client not initialized. Call init() first.'));
      }

      final request = ProgressRequest()..requestId = requestId;
      Logger.info('Tracking progress for request: $requestId');

      try {
        // Call the Progress method which returns a stream of ProgressUpdate
        final progressStream = _client!.progress(request);

        // Return the stream with error handling
        return progressStream.transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              Logger.info('Error in progress stream: $error');
              final userFriendlyError =
                  Exception(getUserFriendlyErrorMessage(error));
              sink.addError(userFriendlyError, stackTrace);
            },
          ),
        );
      } catch (e) {
        Logger.info('Error calling Progress method: $e');
        return Stream.error(Exception('Error tracking progress: $e'));
      }
    } catch (e) {
      Logger.info('Error creating progress stream: $e');
      return Stream.error(e);
    }
  }

  // Start a new conversation
  Future<StartConversationResponse> startConversation({
    String clientId = '',
    String conversationId = '',
    String systemPrompt = '',
  }) async {
    try {
      if (_client == null) {
        Logger.info('gRPC client not initialized');
        throw Exception('gRPC client not initialized. Call init() first.');
      }

      // If no client ID is provided, generate one
      final effectiveClientId =
          clientId.isNotEmpty ? clientId : 'client-${_uuid.v4()}';

      // Always generate a conversation ID if one is not provided
      final effectiveConversationId = conversationId.isNotEmpty
          ? conversationId
          : 'conversation-${_uuid.v4()}';

      final request = StartConversationRequest()
        ..clientId = effectiveClientId
        ..conversationId = effectiveConversationId;

      // Add system prompt if provided
      if (systemPrompt.isNotEmpty) {
        request.systemPrompt = systemPrompt;
        Logger.info('Using custom system prompt: ${systemPrompt.length > 50 ? '${systemPrompt.substring(0, 50)}...' : systemPrompt}');
      }

      Logger.info(
          'Starting conversation for client: $effectiveClientId with ID: $effectiveConversationId');

      try {
        final response = await _client!.startConversation(request);

        if (response.conversationId.isEmpty) {
          Logger.info(
              'Warning: Server returned empty conversation ID, using client-provided ID');
          _currentConversationId = effectiveConversationId;
        } else {
          Logger.info(
              'Successfully started conversation: ${response.conversationId}');
          _currentConversationId = response.conversationId;
        }

        return response;
      } catch (e) {
        Logger.info('Error calling StartConversation method: $e');

        // If there's a specific error about conversation not found
        if (e.toString().contains('Conversation') &&
            e.toString().contains('not found')) {
          // Clear the conversation ID and retry with a new one
          Logger.info(
              'Conversation not found, clearing ID and will create a new one');
          _currentConversationId = null;

          // Create a synthetic response to allow the flow to continue
          final syntheticResponse = StartConversationResponse()
            ..conversationId = 'synthetic-${_uuid.v4()}';
          return syntheticResponse;
        }

        throw Exception('Error starting conversation: $e');
      }
    } catch (e) {
      Logger.info('Error starting conversation: $e');
      rethrow;
    }
  }

  // Reset the current conversation
  void resetConversation() {
    _currentConversationId = null;
    Logger.info(
        'Conversation reset. A new conversation will be started on the next message.');
  }

  // Check if a conversation is currently active
  bool get hasActiveConversation =>
      _currentConversationId != null && _currentConversationId!.isNotEmpty;

  // Get the current conversation ID
  String? get conversationId => _currentConversationId;

  // Set the conversation ID manually if needed
  set conversationId(String? id) {
    _currentConversationId = id;
    Logger.info('Conversation ID manually set to: $id');
  }

  // Check if the client is already initialized
  bool get isInitialized => _client != null;

  // Initialize only if not already initialized
  Future<void> initIfNeeded({
    required String host,
    required int port,
    bool secure = false,
    int retryAttempts = 2,
  }) async {
    if (!isInitialized) {
      await init(
          host: host, port: port, secure: secure, retryAttempts: retryAttempts);
    }
  }

  // Test the connection to the server
  Future<bool> testConnection(
      {Duration timeout = const Duration(seconds: 5)}) async {
    try {
      if (_client == null) {
        Logger.info('gRPC client not initialized, cannot test connection');
        return false;
      }

      Logger.info('Testing gRPC connection...');

      // First try to get the channel connection
      await _channel!.getConnection().timeout(
        timeout,
        onTimeout: () {
          throw Exception(
              'Connection test timed out after ${timeout.inSeconds} seconds');
        },
      );

      // If we have a conversation ID, try a lightweight call to verify the API works
      if (_currentConversationId != null &&
          _currentConversationId!.isNotEmpty) {
        try {
          // Try a lightweight call to check if API is responsive
          final request = StartConversationRequest()
            ..clientId = 'test-${_uuid.v4()}'
            ..conversationId = _currentConversationId!;

          await _client!.startConversation(request).timeout(
            timeout,
            onTimeout: () {
              throw Exception(
                  'API test timed out after ${timeout.inSeconds} seconds');
            },
          );
        } catch (e) {
          Logger.info(
              'API test failed, but connection might still be good: $e');
          // Even if this fails, we at least have a channel connection
        }
      }

      Logger.info('gRPC connection test successful!');
      return true;
    } catch (e) {
      Logger.info('gRPC connection test failed: $e');
      return false;
    }
  }

  // Handle conversation not found error by resetting and starting a new one
  Future<void> handleConversationNotFound() async {
    Logger.info('Handling conversation not found error');

    // Check if we can attempt recovery
    if (!_canAttemptRecovery()) {
      Logger.info('Too many recovery attempts, giving up');
      return;
    }

    // Clear the current conversation ID
    _currentConversationId = null;

    try {
      // Start a new conversation
      final response =
          await startConversation(clientId: 'recovery-${_uuid.v4()}');

      if (response.conversationId.isEmpty) {
        Logger.info(
            'Warning: Server returned empty conversation ID during recovery');
        // Generate a client-side ID if server doesn't provide one
        _currentConversationId = 'client-recovery-${_uuid.v4()}';
      } else {
        _currentConversationId = response.conversationId;
      }

      Logger.info(
          'Successfully recovered with new conversation: $_currentConversationId');
      return;
    } catch (e) {
      Logger.info('Failed to recover from conversation not found: $e');

      // Create a fallback client-side ID even if recovery fails
      _currentConversationId = 'fallback-recovery-${_uuid.v4()}';
      Logger.info(
          'Using fallback conversation ID after recovery failure: $_currentConversationId');
      return;
    }
  }

  // Ensure we have a valid conversation ID, creating one if needed
  Future<String> ensureConversationId() async {
    if (_currentConversationId != null && _currentConversationId!.isNotEmpty) {
      Logger.info('Using existing conversation ID: $_currentConversationId');
      return _currentConversationId!;
    }

    Logger.info('No conversation ID available, starting a new conversation');
    try {
      final response = await startConversation();
      Logger.info(
          'Started new conversation with ID: ${response.conversationId}');
      return response.conversationId;
    } catch (e) {
      Logger.info('Failed to start new conversation: $e');
      // Generate a fallback ID
      final fallbackId = 'fallback-${_uuid.v4()}';
      Logger.info('Using fallback conversation ID: $fallbackId');
      _currentConversationId = fallbackId;
      return fallbackId;
    }
  }

  // Helper method to get user-friendly error messages
  String getUserFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Network-related errors
    if (errorStr.contains('operation not permitted')) {
      return 'Network permission denied. This app needs network access permission to connect to the server.\n\n'
          'On macOS, please:\n'
          '1. Restart the app after permissions are granted\n'
          '2. Check if your firewall is blocking the connection\n'
          '3. Try enabling Mock Mode in settings as a workaround';
    } else if (errorStr.contains('unavailable') ||
        errorStr.contains('socket')) {
      return 'Unable to connect to the server. The service may be unavailable or your internet connection may be down.\n\n'
          'Please check your connection and try again later, or enable Mock Mode in settings.';
    } else if (errorStr.contains('deadline exceeded') ||
        errorStr.contains('timeout')) {
      return 'Connection timed out. The server is taking too long to respond.\n\n'
          'This could be due to server load or network issues. Please try again later.';
    }

    // Client-side errors
    else if (errorStr.contains('not initialized')) {
      return 'gRPC client not properly initialized. This is an internal error.\n\n'
          'Please restart the app or enable Mock Mode in settings.';
    }

    // API/Server errors
    else if (errorStr.contains('unimplemented') ||
        errorStr.contains('method not found')) {
      return 'API method not found on the server. Please make sure you\'re connecting to the correct server.\n\n'
          'Please try again or enable Mock Mode in settings if the issue persists.';
    } else if (errorStr.contains('invalid argument') ||
        errorStr.contains('bad request')) {
      return 'The server rejected the request as invalid. This might be due to an incompatible API version.\n\n'
          'Please check if your app needs to be updated.';
    } else if (errorStr.contains('resource exhausted')) {
      return 'The server has run out of resources or reached its quota.\n\n'
          'Please try again later when the server load might be lower.';
    } else if (errorStr.contains('permission denied') ||
        errorStr.contains('unauthenticated')) {
      return 'The server denied access to this resource. You may not have permission to use this service.\n\n'
          'Please check your credentials or contact support if you believe this is an error.';
    } else if (errorStr.contains('aborted')) {
      return 'The operation was aborted by the server.\n\n'
          'This could be due to server maintenance or an automatic shutdown. Please try again later.';
    } else if (errorStr.contains('internal') || errorStr.contains('unknown')) {
      return 'The server encountered an internal error while processing your request.\n\n'
          'This is not your fault. Please try again later or report this issue if it persists.';
    }

    // Conversation/context errors
    else if (errorStr.contains('conversation') &&
        errorStr.contains('not found')) {
      // Automatically handle this error by starting a new conversation
      handleConversationNotFound();
      return 'The conversation you were referring to could not be found on the server.\n\n'
          'A new conversation has been automatically started for you.';
    } else if (errorStr.contains('context length') ||
        errorStr.contains('too many messages')) {
      return 'The conversation history is too long for the server to process.\n\n'
          'Please reset the conversation to start a new session.';
    }

    // LLM-specific errors
    else if (errorStr.contains('model') &&
        (errorStr.contains('unavailable') || errorStr.contains('not found'))) {
      return 'The requested AI model is currently unavailable.\n\n'
          'Please try a different model or try again later.';
    } else if (errorStr.contains('content filter') ||
        errorStr.contains('moderation')) {
      return 'Your message was flagged by the content filter and could not be processed.\n\n'
          'Please revise your message and try again.';
    } else if (errorStr.contains('rate limit') ||
        errorStr.contains('too many requests')) {
      return 'You have exceeded the rate limit for API requests.\n\n'
          'Please wait a moment before sending another message.';
    }

    // Generic fallback
    else {
      return 'Error connecting to the server: $error\n\n'
          'Please try again later or enable Mock Mode in settings.';
    }
  }

  // Reset recovery counter after successful message
  void _resetRecoveryCounter() {
    if (_recoveryAttempts > 0) {
      Logger.info('Resetting recovery counter from $_recoveryAttempts to 0');
      _recoveryAttempts = 0;
    }
  }

  // Check if we've exceeded recovery attempts
  bool _canAttemptRecovery() {
    _recoveryAttempts++;
    if (_recoveryAttempts > _maxRecoveryAttempts) {
      Logger.info('Exceeded maximum recovery attempts ($_maxRecoveryAttempts)');
      return false;
    }
    Logger.info('Recovery attempt $_recoveryAttempts of $_maxRecoveryAttempts');
    return true;
  }
}
