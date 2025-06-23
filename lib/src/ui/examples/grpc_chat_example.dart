import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/grpc_providers.dart';
import '../../generated/chat.pbenum.dart'; // Import for MessageType enum

class GrpcChatExample extends ConsumerStatefulWidget {
  const GrpcChatExample({Key? key}) : super(key: key);

  @override
  ConsumerState<GrpcChatExample> createState() => _GrpcChatExampleState();
}

class _GrpcChatExampleState extends ConsumerState<GrpcChatExample> {
  final TextEditingController _messageController = TextEditingController();
  final List<dynamic> _messages = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToGrpcServer();
  }

  Future<void> _connectToGrpcServer() async {
    final config = GrpcConnectionConfig(
      host: 'localhost', // Change to your server's host
      port: 50051, // Change to your server's port
    );

    // Show connecting status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to gRPC server...')),
    );

    try {
      // Initialize the connection
      await ref.read(grpcConnectionProvider(config).future);

      // Test the connection
      final client = ref.read(chatGrpcClientProvider);
      final isConnected = await client.testConnection();

      setState(() {
        _isConnected = isConnected;
      });

      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to gRPC server')),
        );

        // If this is a fresh connection, start a new conversation
        if (!client.hasActiveConversation) {
          try {
            final response = await client.startConversation();
            setState(() {
              _messages.add(AppMessage(
                content:
                    'Started new conversation (ID: ${response.conversationId.substring(0, 8)}...)',
                role: 'system',
                timestamp: DateTime.now(),
              ));
            });
          } catch (e) {
            print('Error starting conversation: $e');
            // We'll create one when the first message is sent
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Connected to server but API test failed. Some features may not work.')),
        );
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    // Create and add user message
    final userMessage = AppMessage(
      content: _messageController.text,
      role: 'user',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
    });

    // Start streaming response
    _streamResponse();
  }

  void _streamResponse() {
    // Create assistant message placeholder
    final assistantMessage = AppMessage(
      content: '',
      role: 'assistant',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(assistantMessage);
    });

    // Listen to stream of responses
    ref
        .read(chatStreamProvider(
            _messages.where((m) => m.role == 'user').toList()))
        .when(
      data: (response) {
        // Handle different message types
        switch (response.type) {
          case MessageType.ASSISTANT_RESPONSE:
            setState(() {
              // Check if we have a conversation not found error
              if (response.content.contains('conversation not found') ||
                  response.content.contains('conversation expired') ||
                  response.content
                      .contains('Previous conversation was not found')) {
                // Add a system message about the error
                _messages.add(AppMessage(
                  content: response.content,
                  role: 'system',
                  timestamp: DateTime.now(),
                ));

                // Show a more prominent notification with action
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Previous conversation was not found or expired.'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 10),
                      action: SnackBarAction(
                        label: 'RESET',
                        textColor: Colors.white,
                        onPressed: _resetConversation,
                      ),
                    ),
                  );
                });
              } else {
                // Update the last message (assistant's message)
                final lastMsg = _messages.last as AppMessage;
                _messages[_messages.length - 1] = AppMessage(
                  content: lastMsg.content + response.content,
                  role: 'assistant',
                  timestamp: lastMsg.timestamp,
                );
              }
            });
            break;

          case MessageType.ACTION_REQUEST:
            // For demonstration, show tool/action requests in UI
            setState(() {
              _messages.add(AppMessage(
                content: 'Action Request: ${response.content}',
                role: 'system',
                timestamp: DateTime.now(),
              ));
            });
            break;

          case MessageType.ACTION_RESPONSE:
            // For demonstration, show tool/action responses in UI
            setState(() {
              _messages.add(AppMessage(
                content: 'Action Response: ${response.content}',
                role: 'system',
                timestamp: DateTime.now(),
              ));
            });
            break;

          case MessageType.USER_QUERY:
            // We typically don't receive user queries from the server
            // but log them just in case
            print('Received USER_QUERY from server: ${response.content}');
            break;

          default:
            // Log other message types for debugging
            print(
                'Received message of type: ${response.type}, content: ${response.content}');
        }
      },
      loading: () {
        // Stream is being processed
      },
      error: (error, stackTrace) {
        // Show error in UI
        setState(() {
          final lastMsg = _messages.last as AppMessage;
          _messages[_messages.length - 1] = AppMessage(
            content: 'Error: $error',
            role: 'system',
            timestamp: lastMsg.timestamp,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      },
    );
  }

  void _resetConversation() async {
    try {
      final client = ref.read(chatGrpcClientProvider);

      // Reset the conversation in the client
      client.resetConversation();

      // Clear local message history
      setState(() {
        _messages.clear();
      });

      // Start a new conversation
      try {
        final response = await client.startConversation();
        setState(() {
          _messages.add(AppMessage(
            content:
                'Started new conversation (ID: ${response.conversationId.substring(0, 8)}...)',
            role: 'system',
            timestamp: DateTime.now(),
          ));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation reset successfully')),
        );
      } catch (e) {
        print('Error starting new conversation after reset: $e');

        setState(() {
          _messages.add(AppMessage(
            content:
                'Conversation reset. A new conversation will start with your next message.',
            role: 'system',
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      print('Error resetting conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting conversation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current conversation ID if available
    final client = ref.read(chatGrpcClientProvider);
    final conversationId = client.conversationId;
    final hasConversation = client.hasActiveConversation;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('gRPC Chat Example'),
            if (hasConversation)
              Text(
                'Conversation: ${(conversationId?.length ?? 0) > 8 ? conversationId!.substring(0, 8) + "..." : conversationId}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          // Connection status indicator
          IconButton(
            icon: Icon(_isConnected ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _connectToGrpcServer,
            tooltip: _isConnected ? 'Connected' : 'Reconnect',
          ),
          // Reset conversation button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isConnected ? _resetConversation : null,
            tooltip: 'Reset Conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index] as AppMessage;

                // Determine avatar icon based on role
                IconData avatarIcon;
                Color avatarColor;
                switch (message.role) {
                  case 'user':
                    avatarIcon = Icons.person;
                    avatarColor = Colors.blue;
                    break;
                  case 'assistant':
                    avatarIcon = Icons.smart_toy;
                    avatarColor = Colors.green;
                    break;
                  case 'system':
                    avatarIcon = Icons.settings;
                    avatarColor = Colors.orange;
                    break;
                  default:
                    avatarIcon = Icons.question_mark;
                    avatarColor = Colors.grey;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4.0, horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: avatarColor.withOpacity(0.2),
                        child: Icon(avatarIcon, color: avatarColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: message.role == 'user'
                                    ? Colors.blue.withOpacity(0.1)
                                    : message.role == 'assistant'
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.role.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: message.role == 'user'
                                          ? Colors.blue
                                          : message.role == 'assistant'
                                              ? Colors.green
                                              : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(message.content),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, top: 4.0),
                              child: Text(
                                _formatTimestamp(message.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isConnected,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isConnected ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to format timestamp
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

// Simple app message class - use the one from your message_converter.dart
class AppMessage {
  final String content;
  final String role;
  final DateTime timestamp;

  AppMessage({
    required this.content,
    required this.role,
    required this.timestamp,
  });
}
