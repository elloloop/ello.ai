import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dependencies.dart';
import '../../generated/chat.pbgrpc.dart';
import '../../generated/chat.pbenum.dart';

class EnhancedChatExample extends ConsumerStatefulWidget {
  const EnhancedChatExample({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedChatExample> createState() =>
      _EnhancedChatExampleState();
}

class _EnhancedChatExampleState extends ConsumerState<EnhancedChatExample> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isConnected = false;
  bool _isTyping = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _connectToServer() async {
    final client = ref.read(enhancedGrpcClientProvider);

    setState(() {
      _isConnected = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to server...')),
    );

    try {
      final success = await client.connect();

      setState(() {
        _isConnected = success;
        _conversationId = client.conversationId;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Connected with conversation ID: ${_getShortId(_conversationId)}')),
        );

        // Add system message
        setState(() {
          _messages.add(ChatMessage()
            ..messageId = 'welcome'
            ..content =
                'Welcome to the chat! You are now connected to the server.'
            ..type = MessageType.ASSISTANT_RESPONSE
            ..conversationId = _conversationId ?? '');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect')),
        );
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  void _resetConversation() async {
    final client = ref.read(enhancedGrpcClientProvider);

    setState(() {
      _messages.clear();
      _isTyping = true;
    });

    await client.resetConversation();

    setState(() {
      _conversationId = client.conversationId;
      _isTyping = false;

      // Add system message
      _messages.add(ChatMessage()
        ..messageId = 'reset'
        ..content =
            'Conversation has been reset. New ID: ${_getShortId(_conversationId)}'
        ..type = MessageType.ASSISTANT_RESPONSE
        ..conversationId = _conversationId ?? '');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conversation reset successfully')),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final client = ref.read(enhancedGrpcClientProvider);
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to server')),
      );
      return;
    }

    // Add user message
    setState(() {
      _messages.add(ChatMessage()
        ..messageId = 'user-${DateTime.now().millisecondsSinceEpoch}'
        ..content = message
        ..type = MessageType.USER_QUERY
        ..conversationId = _conversationId ?? '');

      _messageController.clear();
      _isTyping = true;
    });

    // Get the response stream
    final responseStream = client.chat(message);

    // Start with an empty response
    ChatMessage? currentResponse;

    // Listen to the stream
    responseStream.listen(
      (response) {
        // First message sets up the response
        if (currentResponse == null) {
          setState(() {
            currentResponse = response;
            _messages.add(currentResponse!);
            _conversationId = client.conversationId;
          });
        }
        // Special status/info messages
        else if (response.messageId.startsWith('status-') ||
            response.messageId.startsWith('error-') ||
            response.messageId.startsWith('retry-')) {
          // Add as a separate message
          setState(() {
            _messages.add(response);
          });
        }
        // Update existing response with new content
        else {
          setState(() {
            final index = _messages.indexOf(currentResponse!);
            if (index >= 0) {
              _messages[index] = response;
            }
          });
        }
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );

        setState(() {
          _isTyping = false;
        });
      },
      onDone: () {
        setState(() {
          _isTyping = false;
        });
      },
    );
  }

  String _getShortId(String? id) {
    if (id == null || id.isEmpty) return 'None';
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  @override
  Widget build(BuildContext context) {
    // Monitor connection status changes
    ref.listen(
        enhancedGrpcClientProvider.select(
            (client) => client.connectionStatusStream), (previous, next) {
      next.listen((status) {
        if (status == ConnectionStatus.connected && !_isConnected) {
          setState(() {
            _isConnected = true;
          });
        } else if (status == ConnectionStatus.disconnected && _isConnected) {
          setState(() {
            _isConnected = false;
          });
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enhanced gRPC Chat'),
            Text(
              'Conversation: ${_getShortId(_conversationId)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          // Connection status indicator
          IconButton(
            icon: Icon(_isConnected ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _connectToServer,
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
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.type == MessageType.USER_QUERY;
                final isSystem = message.messageId.startsWith('status-') ||
                    message.messageId.startsWith('error-') ||
                    message.messageId.startsWith('reset') ||
                    message.messageId.startsWith('welcome') ||
                    message.messageId.startsWith('retry-');

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : isSystem
                          ? Alignment.center
                          : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade100
                          : isSystem
                              ? Colors.orange.shade50
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message.content),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Assistant is typing...'),
                ],
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
                    enabled: _isConnected && !_isTyping,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: (_isConnected && !_isTyping) ? _sendMessage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
