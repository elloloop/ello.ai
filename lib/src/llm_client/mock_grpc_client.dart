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

    // Simple response simulation
    yield 'Hello from MockGrpcClient! ';
    if (model != null) {
      yield 'Using model: $model. ';
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await Future.delayed(const Duration(milliseconds: 100));
    yield 'I\'m simulating a gRPC stream response. ';
    await Future.delayed(const Duration(milliseconds: 100));
    yield 'You said: ';
    await Future.delayed(const Duration(milliseconds: 100));

    // Echo back the message in chunks
    final words = lastUserMessage.content.split(' ');
    for (final word in words) {
      yield '$word ';
      await Future.delayed(const Duration(milliseconds: 50));
    }

    await Future.delayed(const Duration(milliseconds: 200));
    yield '\n\nThis is a simulated response since the actual gRPC server is not connected.';
  }
}
