//
//  Generated code. Do not modify.
//  source: chat_service.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'chat_service.pb.dart' as $0;

export 'chat_service.pb.dart';

/// Service for handling chat interactions
@$pb.GrpcServiceName('chat.ChatService')
class ChatServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  static final _$chat = $grpc.ClientMethod<$0.ChatMessage, $0.ChatMessage>(
      '/chat.ChatService/Chat',
      ($0.ChatMessage value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ChatMessage.fromBuffer(value));
  static final _$progress = $grpc.ClientMethod<$0.ProgressRequest, $0.ProgressUpdate>(
      '/chat.ChatService/Progress',
      ($0.ProgressRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ProgressUpdate.fromBuffer(value));
  static final _$startConversation = $grpc.ClientMethod<$0.StartConversationRequest, $0.StartConversationResponse>(
      '/chat.ChatService/StartConversation',
      ($0.StartConversationRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.StartConversationResponse.fromBuffer(value));

  ChatServiceClient(super.channel, {super.options, super.interceptors});

  /// Chat method where client sends a single message and server streams responses
  /// Main chat stream for server-side streaming
  $grpc.ResponseStream<$0.ChatMessage> chat($0.ChatMessage request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$chat, $async.Stream.fromIterable([request]), options: options);
  }

  /// Stream for sending progress updates
  $grpc.ResponseStream<$0.ProgressUpdate> progress($0.ProgressRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$progress, $async.Stream.fromIterable([request]), options: options);
  }

  /// Starts a new conversation
  $grpc.ResponseFuture<$0.StartConversationResponse> startConversation($0.StartConversationRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$startConversation, request, options: options);
  }
}

@$pb.GrpcServiceName('chat.ChatService')
abstract class ChatServiceBase extends $grpc.Service {
  $core.String get $name => 'chat.ChatService';

  ChatServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ChatMessage, $0.ChatMessage>(
        'Chat',
        chat_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ChatMessage.fromBuffer(value),
        ($0.ChatMessage value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProgressRequest, $0.ProgressUpdate>(
        'Progress',
        progress_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ProgressRequest.fromBuffer(value),
        ($0.ProgressUpdate value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartConversationRequest, $0.StartConversationResponse>(
        'StartConversation',
        startConversation_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StartConversationRequest.fromBuffer(value),
        ($0.StartConversationResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.ChatMessage> chat_Pre($grpc.ServiceCall $call, $async.Future<$0.ChatMessage> $request) async* {
    yield* chat($call, await $request);
  }

  $async.Stream<$0.ProgressUpdate> progress_Pre($grpc.ServiceCall $call, $async.Future<$0.ProgressRequest> $request) async* {
    yield* progress($call, await $request);
  }

  $async.Future<$0.StartConversationResponse> startConversation_Pre($grpc.ServiceCall $call, $async.Future<$0.StartConversationRequest> $request) async {
    return startConversation($call, await $request);
  }

  $async.Stream<$0.ChatMessage> chat($grpc.ServiceCall call, $0.ChatMessage request);
  $async.Stream<$0.ProgressUpdate> progress($grpc.ServiceCall call, $0.ProgressRequest request);
  $async.Future<$0.StartConversationResponse> startConversation($grpc.ServiceCall call, $0.StartConversationRequest request);
}
