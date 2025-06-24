import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

// Import generated protobuf files
import 'generated/chat_service.pbgrpc.dart';

class ChatServiceImpl extends ChatServiceBase {
  final Logger _logger = Logger('ChatServiceImpl');
  final Map<String, String> _conversations = {};
  final Uuid _uuid = const Uuid();

  @override
  Stream<ChatMessage> chat(ServiceCall call, ChatMessage request) async* {
    _logger.info('Received chat request: ${request.content}');
    _logger.info('Conversation ID: ${request.conversationId}');

    // Validate the request
    if (request.content.isEmpty) {
      _logger.warning('Empty message content received');
      return;
    }

    // Ensure we have a conversation ID
    String conversationId = request.conversationId;
    if (conversationId.isEmpty) {
      conversationId = _uuid.v4();
      _logger.info('Generated new conversation ID: $conversationId');
    }

    // Store the conversation
    _conversations[conversationId] = request.content;

    // Simulate streaming response by sending the message word by word
    final words = [
      'Echo:',
      request.content,
      '(streaming',
      'response',
      'from',
      'Dart',
      'server)',
    ];

    for (int i = 0; i < words.length; i++) {
      final response = ChatMessage()
        ..messageId = _uuid.v4()
        ..content = '${words[i]} '
        ..type = MessageType.ASSISTANT_RESPONSE
        ..conversationId = conversationId;

      _logger.fine('Sending response chunk $i: ${response.content}');
      yield response;

      // Simulate processing time
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Send final completion message
    final finalResponse = ChatMessage()
      ..messageId = _uuid.v4()
      ..content = 'Response completed successfully!'
      ..type = MessageType.ASSISTANT_RESPONSE
      ..conversationId = conversationId;

    _logger.info('Chat stream completed for conversation: $conversationId');
    yield finalResponse;
  }

  @override
  Stream<ProgressUpdate> progress(
      ServiceCall call, ProgressRequest request) async* {
    _logger.info('Progress stream requested for: ${request.requestId}');

    // Simulate progress updates
    final progressSteps = [
      {'status': 'Starting', 'progress': 0.0, 'message': 'Initializing...'},
      {
        'status': 'Processing',
        'progress': 0.25,
        'message': 'Analyzing request...'
      },
      {
        'status': 'Processing',
        'progress': 0.5,
        'message': 'Generating response...'
      },
      {'status': 'Processing', 'progress': 0.75, 'message': 'Finalizing...'},
      {'status': 'Completed', 'progress': 1.0, 'message': 'Done!'},
    ];

    for (final step in progressSteps) {
      final update = ProgressUpdate()
        ..status = step['status'] as String
        ..progress = step['progress'] as double
        ..message = step['message'] as String;

      _logger.fine('Progress update: ${update.status} - ${update.progress}');
      yield update;

      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Future<StartConversationResponse> startConversation(
    ServiceCall call,
    StartConversationRequest request,
  ) async {
    _logger.info('Starting conversation for client: ${request.clientId}');

    String conversationId = request.conversationId;
    if (conversationId.isEmpty) {
      conversationId = _uuid.v4();
      _logger.info('Generated new conversation ID: $conversationId');
    }

    // Store the conversation
    _conversations[conversationId] = '';

    final response = StartConversationResponse()
      ..conversationId = conversationId;

    _logger.info('Conversation started: $conversationId');
    return response;
  }
}

Future<void> main(List<String> args) async {
  // Parse command line arguments
  final parser = ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '50051')
    ..addOption('host', abbr: 'h', defaultsTo: '0.0.0.0')
    ..addFlag('help', abbr: '?', help: 'Show this help message');

  try {
    final results = parser.parse(args);

    if (results['help']) {
      print('Usage: dart run bin/main.dart [options]');
      print(parser.usage);
      return;
    }

    final port = int.parse(results['port']);
    final host = results['host'];

    // Setup logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });

    final logger = Logger('Main');

    // Create the gRPC server
    final server = Server.create(services: [ChatServiceImpl()]);

    // Start the server
    await server.serve(port: port, address: InternetAddress(host));

    logger.info('Dart gRPC server listening on $host:$port');
    logger.info('This server echoes back user messages for testing purposes');
    logger.info('Available services:');
    logger.info('  - ChatService.Chat (streaming)');
    logger.info('  - ChatService.Progress (streaming)');
    logger.info('  - ChatService.StartConversation');

    // Keep the server running
  } catch (e) {
    print('Error: $e');
    print('Usage: dart run bin/main.dart [options]');
    print(parser.usage);
    exit(1);
  }
}
