import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ello_ai/src/core/dependencies.dart';
import 'package:ello_ai/src/models/message.dart';

void main() {
  group('Chat History Streaming Tests', () {
    test('ChatHistoryNotifier handles streaming messages correctly', () {
      final container = ProviderContainer();
      final notifier = container.read(chatHistoryProvider.notifier);

      // Add a user message
      notifier.addUserMessage('Hello');
      expect(container.read(chatHistoryProvider).length, 1);
      expect(container.read(chatHistoryProvider).first.content, 'Hello');
      expect(container.read(chatHistoryProvider).first.isUser, true);

      // Add a streaming assistant message
      notifier.addAssistantMessage('Hi', isStreaming: true);
      expect(container.read(chatHistoryProvider).length, 2);
      expect(container.read(chatHistoryProvider).last.content, 'Hi');
      expect(container.read(chatHistoryProvider).last.isUser, false);
      expect(container.read(chatHistoryProvider).last.isStreaming, true);

      // Append to the streaming message
      notifier.appendToLastMessageImmediate(' there!');
      expect(container.read(chatHistoryProvider).length, 2);
      expect(container.read(chatHistoryProvider).last.content, 'Hi there!');
      expect(container.read(chatHistoryProvider).last.isStreaming, true);

      // Finish streaming
      notifier.finishStreamingMessage();
      expect(container.read(chatHistoryProvider).last.isStreaming, false);

      container.dispose();
    });

    test('Message model supports streaming state', () {
      final userMessage = Message.user('Hello');
      expect(userMessage.isUser, true);
      expect(userMessage.isStreaming, false);

      final streamingMessage = Message.assistant('Hi', isStreaming: true);
      expect(streamingMessage.isUser, false);
      expect(streamingMessage.isStreaming, true);

      final updatedMessage = streamingMessage.appendContent(' there!');
      expect(updatedMessage.content, 'Hi there!');
      expect(updatedMessage.isStreaming, true);

      final finishedMessage = updatedMessage.copyWith(isStreaming: false);
      expect(finishedMessage.content, 'Hi there!');
      expect(finishedMessage.isStreaming, false);
    });

    test('Clear functionality resets streaming state', () {
      final container = ProviderContainer();
      final notifier = container.read(chatHistoryProvider.notifier);

      notifier.addUserMessage('Hello');
      notifier.addAssistantMessage('Hi', isStreaming: true);
      expect(container.read(chatHistoryProvider).length, 2);

      notifier.clear();
      expect(container.read(chatHistoryProvider).length, 0);

      container.dispose();
    });
  });
}