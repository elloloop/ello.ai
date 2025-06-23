import 'dart:async';
import '../generated/chat.pbenum.dart';
import '../models/message.dart';
import '../services/chat_service_client.dart';
import 'chat_client.dart';

class GrpcChatClient implements ChatClient {
  final ChatGrpcClient _client;

  GrpcChatClient(this._client);

  @override
  Stream<String> chat({required List<Message> messages, String? model}) {
    // Stream the responses and filter for assistant responses
    return _client
        .chatStream(messages)
        .where((message) => message.type == MessageType.ASSISTANT_RESPONSE)
        .map((response) => response.content);
  }
}
