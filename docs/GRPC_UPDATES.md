# gRPC Integration Update

We've updated the app to better work with the Python-based LLM Gateway server. The following changes have been made:

## Proto Updates

- Updated the `chat.proto` file to include methods that match the server API:
  - `Chat(ChatRequest) returns (stream ChatResponse)`
  - `Progress(ProgressRequest) returns (stream ProgressResponse)`
  - `StartConversation(ConversationRequest) returns (ConversationResponse)`

## Client Improvements

- Added an adaptive client that tries multiple API patterns:
  1. First tries direct streaming with the `Chat` method
  2. Falls back to a two-step approach with `StartConversation` + `Progress`
- Enhanced error messages to provide more useful information when connections fail

## Using the Updated Client

The client API remains the same - use the `chatStreamProvider` as before:

```dart
// Assume messages is a List<YourMessageType>
ref.read(chatStreamProvider(messages)).when(
  data: (response) {
    // Handle each chunk from the stream
    if (response.isDone) {
      // Final message received
    } else {
      // Partial message, update UI
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

## Additional Functionality

New methods are available in the `ChatGrpcClient` class:

- `startConversation(userId: String, modelId: String)`: Explicitly start a new conversation
- `trackProgress(conversationId: String)`: Track progress of an ongoing conversation

These can be used directly if you need more control over the conversation flow.

## Troubleshooting

If you still encounter connection issues:

1. Check network permissions (especially on macOS)
2. Verify the server is running and accessible
3. Enable Mock Mode in settings as a fallback
