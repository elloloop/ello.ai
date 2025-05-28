import 'dart:async';
import '../models/message.dart';
import 'chat_client.dart';

class MockClient implements ChatClient {
  @override
  Stream<String> chat({required List<Message> messages}) async* {
    yield 'Hello from MockClient!';
  }
}
