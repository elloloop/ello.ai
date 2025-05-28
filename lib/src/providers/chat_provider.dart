import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../llm_client/chat_client.dart';
import 'llm_providers.dart';

final chatHistoryProvider = StateProvider<List<Message>>((ref) => []);

final chatProvider = StateNotifierProvider<ChatController, AsyncValue<void>>(
  (ref) => ChatController(ref.read),
);

class ChatController extends StateNotifier<AsyncValue<void>> {
  ChatController(this._read) : super(const AsyncData(null));

  final Reader _read;

  Future<void> sendMessage(String content) async {
    if (content.isEmpty) return;
    final history = _read(chatHistoryProvider);
    final newMessage = Message.user(content);
    history.state = [...history.state, newMessage];

    state = const AsyncLoading();
    final client = _read(currentChatClientProvider);

    await for (final chunk in client.chat(messages: history.state)) {
      if (history.state.isEmpty || history.state.last.isUser) {
        history.state = [...history.state, Message.assistant(chunk)];
      } else {
        final last = history.state.removeLast();
        history.state = [...history.state, last.appendContent(chunk)];
      }
    }
    state = const AsyncData(null);
  }
}
