import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:uuid/uuid.dart';
import 'lib/src/generated/chat.pbgrpc.dart';
import 'lib/src/generated/chat.pbenum.dart';
import 'lib/src/models/message.dart';
import 'lib/src/llm_client/grpc_chat_client.dart';
import 'lib/src/services/chat_service_client.dart';

void main() async {
  print('🔍 Testing gRPC UI message processing...');

  const host = 'grpc-server-4rwujpfquq-uc.a.run.app';
  const port = 443;

  try {
    // Create channel with TLS
    print('📡 Creating gRPC channel with TLS...');
    final channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: ChannelCredentials.secure(),
        codecRegistry: CodecRegistry(codecs: [GzipCodec(), IdentityCodec()]),
        connectionTimeout: Duration(seconds: 15),
      ),
    );

    // Create the underlying client
    final chatGrpcClient = ChatGrpcClient();
    await chatGrpcClient.init(host: host, port: port, secure: true);

    // Create the UI client wrapper
    final grpcChatClient = GrpcChatClient(chatGrpcClient);

    // Create test messages
    final messages = [
      Message(content: 'Hello from UI test!', isUser: true),
    ];

    print('💬 Testing UI message processing...');
    print('📤 Sending: ${messages.first.content}');

    // Test the UI client's chat method
    final responseStream = grpcChatClient.chat(messages: messages);

    int responseCount = 0;
    await for (final response in responseStream) {
      responseCount++;
      print('📥 UI Response $responseCount: $response');
    }

    print('✅ Received $responseCount UI responses');

    // Close channel
    await chatGrpcClient.shutdown();
    print('🔌 Channel closed');
  } catch (e) {
    print('❌ Error: $e');
    print('❌ Error type: ${e.runtimeType}');
    if (e is GrpcError) {
      print('❌ gRPC Error code: ${e.code}');
      print('❌ gRPC Error message: ${e.message}');
    }
  }
}
