import 'dart:async';
import '../models/message.dart';
import 'chat_client.dart';

class MockClient implements ChatClient {
  @override
  Stream<String> chat({required List<Message> messages, String? model}) async* {
    final response = 'Hello from MockClient${model != null ? " using $model" : ""}! This is a simulated streaming response that demonstrates how tokens appear one by one as they arrive from the server.';
    
    // Split response into words for streaming simulation
    final words = response.split(' ');
    
    for (int i = 0; i < words.length; i++) {
      // Add space before each word except the first
      final chunk = i == 0 ? words[i] : ' ${words[i]}';
      yield chunk;
      
      // Simulate realistic streaming delay
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}
