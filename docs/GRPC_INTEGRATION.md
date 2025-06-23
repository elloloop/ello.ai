# gRPC Integration Guide

This document outlines how the Flutter app integrates with the Python backend gRPC API.

## Overview

The app uses a gRPC client to communicate with the Python backend. The client sends messages to the server and receives a stream of responses. The app handles different message types from the server, including assistant responses, action requests, and action responses.

## Key Components

### Proto Definition

The app uses the same proto definition as the backend (`chat.proto`), which defines the message types and service methods.

### ChatGrpcClient

The `ChatGrpcClient` class handles all communication with the gRPC server. It provides methods for:

- Initializing the client connection
- Starting a conversation
- Sending chat messages
- Tracking progress
- Handling errors

### Message Flow

1. User sends a message via the UI
2. The app sends the message to the server using the `chat` method
3. The server responds with a stream of messages
4. The app processes the different message types and updates the UI accordingly

## Conversation Management

The app maintains conversation state by:

- Storing the current conversation ID
- Starting a new conversation if needed
- Allowing the user to reset the conversation
- Preserving conversation context across messages

## Message Types

The app handles the following message types:

- `USER_QUERY`: Messages sent by the user
- `ASSISTANT_RESPONSE`: Responses from the assistant
- `ACTION_REQUEST`: When the assistant needs to perform an action
- `ACTION_RESPONSE`: Result of the action

## Error Handling

The app includes robust error handling for various scenarios:

- Network connectivity issues
- Server errors
- API compatibility issues
- Conversation context errors
- Model-specific errors

## Usage

### Connecting to the Server

```dart
final config = GrpcConnectionConfig(
  host: 'your-grpc-server.com',
  port: 443,
  secure: true,
);

await ref.read(grpcConnectionProvider(config).future);
```

### Sending a Message

```dart
final chatGrpcClient = ref.read(chatGrpcClientProvider);
chatGrpcClient.chatStream(messages).listen(
  (response) {
    // Handle different message types
    switch (response.type) {
      case MessageType.ASSISTANT_RESPONSE:
        // Update UI with assistant response
        break;
      // Handle other message types
    }
  },
  onError: (error) {
    // Handle errors
  },
);
```

### Resetting a Conversation

```dart
final chatGrpcClient = ref.read(chatGrpcClientProvider);
chatGrpcClient.resetConversation();
```

## Troubleshooting

If you encounter issues with the gRPC connection:

1. Check network connectivity
2. Verify the server address and port
3. Ensure the proto definition matches the server
4. Check for firewall or permission issues
5. Try using Mock Mode for testing
6. Look for specific error messages in the logs

## Future Improvements

- Implement additional methods from the proto service
- Add support for batch message processing
- Improve error recovery mechanisms
- Add client-side caching for conversation history
