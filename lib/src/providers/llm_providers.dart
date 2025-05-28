import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../llm_client/chat_client.dart';
import '../llm_client/openai_client.dart';
import '../llm_client/mock_client.dart';

final modelProvider = StateProvider<String>((ref) => 'OpenAI');

final currentChatClientProvider = Provider<ChatClient>((ref) {
  final model = ref.watch(modelProvider);
  switch (model) {
    case 'OpenAI':
    default:
      final key = const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
        return key.isEmpty ? MockClient() : OpenAIClient(key);
  }
});
