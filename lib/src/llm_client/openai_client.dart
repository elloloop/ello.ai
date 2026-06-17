import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'chat_client.dart';

class OpenAIClient implements ChatClient {
  OpenAIClient(this.apiKey);

  final String apiKey;

  @override
  Stream<String> chat({
    required List<Message> messages, 
    String? model,
    double? temperature,
    double? topP,
  }) async* {
    final url = Uri.https('api.openai.com', '/v1/chat/completions');
    final body = <String, dynamic>{
      'model': model ?? 'gpt-3.5-turbo',
      'stream': true,
      'messages': [
        for (final m in messages)
          {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          }
      ],
    };

    // Add temperature if provided
    if (temperature != null) {
      body['temperature'] = temperature;
    }

    // Add top_p if provided
    if (topP != null) {
      body['top_p'] = topP;
    }

    final request = http.Request('POST', url)
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode(body);

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    await for (final chunk in response.stream
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())) {
      if (chunk.startsWith('data: ')) {
        final data = chunk.substring(6);
        if (data == '[DONE]') break;
        final json = jsonDecode(data) as Map<String, dynamic>;
        final content = json['choices'][0]['delta']['content'] as String?;
        if (content != null) yield content;
      }
    }
  }
}
