import '../models/message.dart';

abstract class ChatClient {
  Stream<String> chat({required List<Message> messages});
}
