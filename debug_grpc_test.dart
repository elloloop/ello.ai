import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:uuid/uuid.dart';
import 'lib/src/generated/chat.pbgrpc.dart';
import 'lib/src/generated/chat.pbenum.dart';

void main() async {
  print('🔍 Testing gRPC connection to Cloud Run server...');

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

    // Create client
    final client = ChatServiceClient(channel);

    // Test connection
    print('🔗 Testing connection...');
    await channel.getConnection().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Connection timeout'),
        );
    print('✅ Connection established!');

    // Generate IDs
    final uuid = Uuid();
    final clientId = 'test-client-${uuid.v4()}';
    final conversationId = 'test-conv-${uuid.v4()}';

    print('🆔 Client ID: $clientId');
    print('🆔 Conversation ID: $conversationId');

    // Start conversation
    print('🚀 Starting conversation...');
    final startRequest = StartConversationRequest()
      ..clientId = clientId
      ..conversationId = conversationId;

    final startResponse = await client.startConversation(startRequest);
    print('✅ Conversation started: ${startResponse.conversationId}');

    // Send a test message
    print('💬 Sending test message...');
    final chatMessage = ChatMessage()
      ..messageId = 'test-msg-${uuid.v4()}'
      ..content = 'Hello from Flutter test!'
      ..type = MessageType.USER_QUERY
      ..conversationId = startResponse.conversationId;

    print('📤 Sending: ${chatMessage.content}');

    // Get streaming response
    final responses = client.chat(chatMessage);
    int responseCount = 0;

    await for (final response in responses) {
      responseCount++;
      print('📥 Response $responseCount: ${response.content}');
      print('📥 Type: ${response.type}');
      print('📥 Message ID: ${response.messageId}');
      print('📥 Conversation ID: ${response.conversationId}');
      print('---');
    }

    print('✅ Received $responseCount responses');

    // Close channel
    await channel.shutdown();
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
