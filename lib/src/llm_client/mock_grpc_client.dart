import '../models/message.dart' as app;
import 'chat_client.dart';

/// A mock gRPC client that simulates responses from a gRPC server
/// Used for testing when the actual server is not available
class MockGrpcClient implements ChatClient {
  @override
  Stream<String> chat(
      {required List<app.Message> messages, String? model}) async* {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Get the last user message
    final lastUserMessage = messages.lastWhere((m) => m.isUser);

    // Create a longer, more realistic response to demonstrate streaming
    final responses = [
      'Hello from MockGrpcClient! ',
      'I received your message: "${lastUserMessage.content}". ',
      'This is a simulated streaming response that demonstrates ',
      'how tokens appear progressively as they arrive from the server. ',
      'Each chunk is delivered with realistic timing to simulate ',
      'the experience of a real language model generating text. ',
      '\n\nThe streaming implementation includes:\n',
      '• Debounced UI updates to prevent jank\n',
      '• Efficient text rendering with StreamingText widget\n', 
      '• Interrupt capability to stop responses early\n',
      '• Visual indicators for active streaming\n',
      '• Smooth user experience during token arrival\n\n',
      'Model used: ${model ?? "default"}\n',
      'Response completed successfully! ✅'
    ];

    for (final chunk in responses) {
      yield chunk;
      // Vary the delay to simulate realistic LLM response timing
      await Future.delayed(Duration(milliseconds: 30 + (chunk.length * 2)));
    }
  }
}
