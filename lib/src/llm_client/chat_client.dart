import '../models/message.dart';

abstract class ChatClient {
  Stream<String> chat({
    required List<Message> messages, 
    String? model,
    double? temperature,
    double? topP,
  });
}
