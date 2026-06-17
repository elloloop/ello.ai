//
//  Generated code. Do not modify.
//  source: llm_gateway/llm_service.proto
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

import 'llm_service.pb.dart' as $0;

export 'llm_service.pb.dart';

@$pb.GrpcServiceName('llm_gateway.LLMService')
class LLMServiceClient extends $grpc.Client {
  static final _$chatCompletionStream = $grpc.ClientMethod<$0.ChatRequest, $0.ChatResponse>(
      '/llm_gateway.LLMService/ChatCompletionStream',
      ($0.ChatRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ChatResponse.fromBuffer(value));
  static final _$chatCompletion = $grpc.ClientMethod<$0.ChatRequest, $0.ChatCompletionResponse>(
      '/llm_gateway.LLMService/ChatCompletion',
      ($0.ChatRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ChatCompletionResponse.fromBuffer(value));

  LLMServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseStream<$0.ChatResponse> chatCompletionStream($0.ChatRequest request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$chatCompletionStream, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ChatCompletionResponse> chatCompletion($0.ChatRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$chatCompletion, request, options: options);
  }
}

@$pb.GrpcServiceName('llm_gateway.LLMService')
abstract class LLMServiceBase extends $grpc.Service {
  $core.String get $name => 'llm_gateway.LLMService';

  LLMServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ChatRequest, $0.ChatResponse>(
        'ChatCompletionStream',
        chatCompletionStream_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ChatRequest.fromBuffer(value),
        ($0.ChatResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChatRequest, $0.ChatCompletionResponse>(
        'ChatCompletion',
        chatCompletion_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ChatRequest.fromBuffer(value),
        ($0.ChatCompletionResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.ChatResponse> chatCompletionStream_Pre(
      $grpc.ServiceCall call, $async.Future<$0.ChatRequest> request) async* {
    yield* chatCompletionStream(call, await request);
  }

  $async.Future<$0.ChatCompletionResponse> chatCompletion_Pre(
      $grpc.ServiceCall call, $async.Future<$0.ChatRequest> request) async {
    return chatCompletion(call, await request);
  }

  $async.Stream<$0.ChatResponse> chatCompletionStream($grpc.ServiceCall call, $0.ChatRequest request);
  $async.Future<$0.ChatCompletionResponse> chatCompletion($grpc.ServiceCall call, $0.ChatRequest request);
}