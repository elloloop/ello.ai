import 'dart:async';
import 'package:uuid/uuid.dart';
import '../generated/chat.pbgrpc.dart';

/// Enhanced gRPC chat client that follows the same pattern as the Python client
/// This implementation focuses on robust conversation handling and streaming
class EnhancedGrpcChatClient {
  final ChatServiceClient _client;
  final Uuid _uuid = Uuid();
  String? _conversationId;
  String? _clientId;
  bool _isConnected = false;

  // Events for client status changes
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  // Create with an existing gRPC client
  EnhancedGrpcChatClient(this._client) {
    // Generate a stable client ID
    _clientId = 'flutter-client-${_uuid.v4()}';
    print('Initialized enhanced gRPC client with ID: $_clientId');
  }

  // Check if we're connected
  bool get isConnected => _isConnected;

  // Get current conversation ID
  String? get conversationId => _conversationId;

  // Check if we have an active conversation
  bool get hasActiveConversation =>
      _conversationId != null && _conversationId!.isNotEmpty;

  // Connect and start a conversation
  Future<bool> connect() async {
    try {
      _connectionStatusController.add(ConnectionStatus.connecting);

      // First test with a simple API call
      try {
        // Use a test request to verify connection
        final testRequest = StartConversationRequest()..clientId = _clientId!;

        await _client
            .startConversation(testRequest)
            .timeout(const Duration(seconds: 5));

        _isConnected = true;
      } catch (e) {
        print('Connection test failed: $e');
        _isConnected = false;
        _connectionStatusController.add(ConnectionStatus.disconnected);
        return false;
      }

      // Now start a conversation to fully verify API works
      final response = await startConversation();

      if (response.conversationId.isEmpty) {
        print('Warning: Server returned empty conversation ID');
        _isConnected = false;
        _connectionStatusController.add(ConnectionStatus.error);
        return false;
      }

      // Successfully connected
      _isConnected = true;
      _connectionStatusController.add(ConnectionStatus.connected);
      return true;
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      _connectionStatusController.add(ConnectionStatus.error);
      return false;
    }
  }

  // Start a new conversation
  Future<StartConversationResponse> startConversation() async {
    // Generate a new conversation ID if needed
    final conversationId = _conversationId ?? 'conversation-${_uuid.v4()}';

    // Create the request
    final request = StartConversationRequest()
      ..clientId = _clientId!
      ..conversationId = conversationId;

    print('Starting conversation: $conversationId');

    try {
      // Call the service
      final response = await _client
          .startConversation(request)
          .timeout(const Duration(seconds: 10));

      // Save the conversation ID
      _conversationId = response.conversationId;
      print('Conversation started: ${response.conversationId}');

      return response;
    } catch (e) {
      print('Error starting conversation: $e');
      // Keep using our client-side ID if server fails
      _conversationId = conversationId;

      // Return a synthetic response
      return StartConversationResponse()..conversationId = conversationId;
    }
  }

  // Reset the conversation
  Future<void> resetConversation() async {
    _conversationId = null;
    print('Conversation reset, will start a new one on next message');

    // Start a new conversation right away
    try {
      await startConversation();
    } catch (e) {
      print('Failed to start new conversation after reset: $e');
      // We'll try again with the next message
    }
  }

  // Send a message and get streaming response
  Stream<ChatMessage> chat(String content) {
    // Create a controller to manage the stream
    final controller = StreamController<ChatMessage>();

    // Function to handle sending after ensuring conversation exists
    void sendMessage() async {
      try {
        // Ensure we have a conversation ID
        if (_conversationId == null || _conversationId!.isEmpty) {
          try {
            final response = await startConversation();
            _conversationId = response.conversationId;
          } catch (e) {
            print('Failed to start conversation before chat: $e');
            controller.addError('Failed to start conversation: $e');
            controller.close();
            return;
          }
        }

        // Create the request message
        final request = ChatMessage()
          ..messageId = 'msg-${_uuid.v4()}'
          ..content = content
          ..type = MessageType.USER_QUERY
          ..conversationId = _conversationId!;

        print('Sending message to conversation: $_conversationId');

        // Status update - thinking
        controller.add(ChatMessage()
          ..messageId = 'status-${_uuid.v4()}'
          ..content = 'Assistant is thinking...'
          ..type = MessageType.ASSISTANT_RESPONSE
          ..conversationId = _conversationId!);

        // Call the service and get streaming response
        final responses = _client.chat(request);

        // Process the streamed responses
        responses.listen(
          (response) {
            // Check for conversation errors in content
            if (response.content.contains('conversation not found') ||
                response.content.contains('conversation expired')) {
              print('Detected conversation error in response');
              _conversationId = null;

              // Create an error message
              final errorMessage = ChatMessage()
                ..messageId = 'error-${_uuid.v4()}'
                ..content =
                    'Previous conversation was not found or expired. Starting a new conversation.'
                ..type = MessageType.ASSISTANT_RESPONSE
                ..conversationId = '';

              controller.add(errorMessage);

              // Try to start a new conversation and retry
              startConversation().then((response) {
                _conversationId = response.conversationId;

                // Create a retry message
                final retryMessage = ChatMessage()
                  ..messageId = 'retry-${_uuid.v4()}'
                  ..content =
                      'Started new conversation. Retrying your message...'
                  ..type = MessageType.ASSISTANT_RESPONSE
                  ..conversationId = _conversationId!;

                controller.add(retryMessage);

                // Wait a moment then retry
                Future.delayed(const Duration(milliseconds: 500), () {
                  sendMessage();
                });
              });

              return;
            }

            // Forward the response
            controller.add(response);
          },
          onError: (error) {
            print('Error in chat stream: $error');

            // Special handling for conversation not found
            if (error.toString().contains('conversation not found') ||
                error.toString().contains('conversation expired')) {
              _conversationId = null;

              // Create an error message
              final errorMessage = ChatMessage()
                ..messageId = 'error-${_uuid.v4()}'
                ..content =
                    'Previous conversation was not found or expired. Starting a new conversation.'
                ..type = MessageType.ASSISTANT_RESPONSE
                ..conversationId = '';

              controller.add(errorMessage);

              // Try to start a new conversation and retry
              startConversation().then((response) {
                _conversationId = response.conversationId;

                // Create a retry message
                final retryMessage = ChatMessage()
                  ..messageId = 'retry-${_uuid.v4()}'
                  ..content =
                      'Started new conversation. Retrying your message...'
                  ..type = MessageType.ASSISTANT_RESPONSE
                  ..conversationId = _conversationId!;

                controller.add(retryMessage);

                // Wait a moment then retry
                Future.delayed(const Duration(milliseconds: 500), () {
                  sendMessage();
                });
              });

              return;
            }

            controller.addError(error);
          },
          onDone: () {
            controller.close();
          },
        );
      } catch (e) {
        print('Error sending chat message: $e');
        controller.addError(e);
        controller.close();
      }
    }

    // Start the process
    sendMessage();

    // Return the stream
    return controller.stream;
  }

  // Track progress of a request
  Stream<ProgressUpdate> trackProgress(String requestId) {
    final request = ProgressRequest()..requestId = requestId;

    try {
      return _client.progress(request);
    } catch (e) {
      // Create an error stream
      final controller = StreamController<ProgressUpdate>();
      controller.addError(e);
      controller.close();
      return controller.stream;
    }
  }

  // Dispose resources
  void dispose() {
    _connectionStatusController.close();
  }
}

// Connection status enum
enum ConnectionStatus { disconnected, connecting, connected, error }
