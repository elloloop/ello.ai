import 'package:grpc/grpc.dart';
import '../models/message.dart' as app;
import '../generated/llm_gateway/llm_service.pbgrpc.dart';
import 'chat_client.dart';
import '../utils/logger.dart';

class GrpcClient implements ChatClient {
  final String host;
  final int port;
  final bool secure;
  final String defaultModel;

  GrpcClient({
    required this.host,
    required this.port,
    this.secure = false,
    this.defaultModel = 'gpt-3.5-turbo'
  }) {
    // Initialize the channel when the client is created
    _initializeChannel();
  }

  late ClientChannel _channel;
  late LLMServiceClient _stub;

  void _initializeChannel() {
    try {
      _channel = ClientChannel(
        host,
        port: port,
        options: ChannelOptions(
          credentials: secure
              ? ChannelCredentials.secure()
              : ChannelCredentials.insecure(),
          idleTimeout: const Duration(minutes: 1),
        ),
      );
      _stub = LLMServiceClient(_channel);
    } catch (e) {
      Logger.error('Error initializing gRPC channel: $e');
    }
  }

  void dispose() {
    try {
      _channel.shutdown();
    } catch (e) {
      Logger.error('Error shutting down gRPC channel: $e');
    }
  }

  @override
  Stream<String> chat(
      {required List<app.Message> messages, String? model}) async* {
    try {
      // Convert app messages to proto messages
      final protoMessages = messages
          .map((m) => Message(
                role: m.isUser ? 'user' : 'assistant',
                content: m.content,
              ))
          .toList();

      // Create the request
      final request = ChatRequest()
        ..model = model ?? defaultModel
        ..messages.addAll(protoMessages)
        ..temperature = 0.7
        ..maxTokens = 1000
        ..userId = 'flutter-client';

      try {
        // Make the streaming request
        final responses = _stub.chatCompletionStream(request);

        await for (final response in responses) {
          final content = response.choice.message.content;
          if (content.isNotEmpty) {
            yield content;
          }

          // End the stream if we're done
          if (response.done) {
            break;
          }
        }
      } catch (e) {
        yield 'Error connecting to LLM service: $e';
      }
    } catch (e) {
      yield 'Error preparing gRPC request: $e';
    }
  }
}
