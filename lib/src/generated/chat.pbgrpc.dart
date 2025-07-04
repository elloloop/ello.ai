//
//  Generated code. Do not modify.
//  source: chat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'chat.pb.dart' as $0;

export 'chat.pb.dart';

@$pb.GrpcServiceName('chat.ChatService')
class ChatServiceClient extends $grpc.Client {
  static final _$chat = $grpc.ClientMethod<$0.ChatMessage, $0.ChatMessage>(
      '/chat.ChatService/Chat',
      ($0.ChatMessage value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ChatMessage.fromBuffer(value));
  static final _$progress =
      $grpc.ClientMethod<$0.ProgressRequest, $0.ProgressUpdate>(
          '/chat.ChatService/Progress',
          ($0.ProgressRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.ProgressUpdate.fromBuffer(value));
  static final _$startConversation = $grpc.ClientMethod<
          $0.StartConversationRequest, $0.StartConversationResponse>(
      '/chat.ChatService/StartConversation',
      ($0.StartConversationRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.StartConversationResponse.fromBuffer(value));

  ChatServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseStream<$0.ChatMessage> chat($0.ChatMessage request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$chat, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$0.ProgressUpdate> progress($0.ProgressRequest request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(
        _$progress, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.StartConversationResponse> startConversation(
      $0.StartConversationRequest request,
      {$grpc.CallOptions? options}) {
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
    $addMethod($grpc.ServiceMethod<$0.StartConversationRequest,
            $0.StartConversationResponse>(
        'StartConversation',
        startConversation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.StartConversationRequest.fromBuffer(value),
        ($0.StartConversationResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.ChatMessage> chat_Pre(
      $grpc.ServiceCall call, $async.Future<$0.ChatMessage> request) async* {
    yield* chat(call, await request);
  }

  $async.Stream<$0.ProgressUpdate> progress_Pre($grpc.ServiceCall call,
      $async.Future<$0.ProgressRequest> request) async* {
    yield* progress(call, await request);
  }

  $async.Future<$0.StartConversationResponse> startConversation_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.StartConversationRequest> request) async {
    return startConversation(call, await request);
  }

  $async.Stream<$0.ChatMessage> chat(
      $grpc.ServiceCall call, $0.ChatMessage request);
  $async.Stream<$0.ProgressUpdate> progress(
      $grpc.ServiceCall call, $0.ProgressRequest request);
  $async.Future<$0.StartConversationResponse> startConversation(
      $grpc.ServiceCall call, $0.StartConversationRequest request);
}
