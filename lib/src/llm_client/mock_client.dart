import 'dart:async';
import '../models/message.dart';
import 'chat_client.dart';

class MockClient implements ChatClient {
  @override
  Stream<String> chat({required List<Message> messages, String? model}) async* {
    yield 'Hello from MockClient${model != null ? " using $model" : ""}!';
  }
}
