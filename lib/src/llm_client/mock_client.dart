import 'dart:async';
import '../models/message.dart';
import 'chat_client.dart';

class MockClient implements ChatClient {
  @override
  Stream<String> chat({
    required List<Message> messages, 
    String? model,
    double? temperature,
    double? topP,
  }) async* {
    var responsePrefix = 'Hello from MockClient';
    if (model != null) {
      responsePrefix += ' using $model';
    }
    if (temperature != null) {
      responsePrefix += ' (temp: ${temperature.toStringAsFixed(1)})';
    }
    if (topP != null) {
      responsePrefix += ' (top_p: ${topP.toStringAsFixed(1)})';
    }
    yield '$responsePrefix!';
  }
}
