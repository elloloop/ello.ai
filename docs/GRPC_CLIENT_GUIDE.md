# gRPC Chat Integration

This document explains how to use the gRPC chat integration in the Flutter app.

## Overview

The app provides multiple ways to connect to a gRPC server:

1. **Standard ChatGrpcClient** - The original implementation with basic conversation handling
2. **EnhancedGrpcChatClient** - A more robust implementation based on the Python client pattern

## Server Connection

### Using the Connection Manager

The app includes a `ServerConnectionManager` widget that allows you to easily connect to different gRPC servers:

```dart
// In your widget tree
ServerConnectionManager(),
```

### Using the Connection Utility

For programmatic connections, use the `ServerConnectionUtil` class:

```dart
// Connect to Cloud Run
final config = ServerConnectionUtil.getCloudRunConfig();

// Connect to local server
final config = ServerConnectionUtil.getLocalConfig();

// Connect to custom server
final config = ServerConnectionUtil.getCustomConfig(
  host: 'example.com',
  port: 8080,
  secure: true,
);
```

## Using the Enhanced gRPC Client

The enhanced client provides a more robust conversation experience:

```dart
// Get the client
final client = ref.read(enhancedGrpcClientProvider);

// Connect to the server
final success = await client.connect();

// Start a new conversation
final response = await client.startConversation();
final conversationId = response.conversationId;

// Send a message and get streaming response
final stream = client.chat("Hello, how can I help you?");

// Process the response stream
stream.listen(
  (response) {
    print('Response: ${response.content}');
  },
  onError: (error) {
    print('Error: $error');
  },
  onDone: () {
    print('Stream complete');
  },
);

// Reset the conversation
await client.resetConversation();
```

## Example Usage

The app includes example screens that demonstrate how to use the gRPC clients:

1. `GrpcChatExample` - Uses the standard client
2. `EnhancedChatExample` - Uses the enhanced client

## Command Line Tools

The project includes helpful shell scripts:

1. `tools/connect_grpc.sh` - Set up connection to local or cloud servers

   ```bash
   # Connect to local server
   ./tools/connect_grpc.sh --local

   # Connect to Cloud Run
   ./tools/connect_grpc.sh --cloud

   # Connect to custom server
   ./tools/connect_grpc.sh --custom example.com:8080
   ```

## Handling Common Errors

The client automatically handles many common errors:

1. **Conversation Not Found**: The client will automatically start a new conversation and retry
2. **Connection Issues**: The UI provides reconnection options
3. **Server Errors**: User-friendly error messages are displayed

## Best Practices

1. Always check if the client is connected before sending messages
2. Provide user feedback during connection and message streaming
3. Handle conversation lifecycle appropriately (reset when needed)
4. Use the enhanced client for more robust error handling
