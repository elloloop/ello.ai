//
//  Generated code. Do not modify.
//  source: llm_gateway/llm_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use chatRequestDescriptor instead')
const ChatRequest$json = {
  '1': 'ChatRequest',
  '2': [
    {'1': 'model', '3': 1, '4': 1, '5': 9, '10': 'model'},
    {
      '1': 'messages',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.llm_gateway.Message',
      '10': 'messages'
    },
    {'1': 'temperature', '3': 3, '4': 1, '5': 2, '10': 'temperature'},
    {'1': 'max_tokens', '3': 4, '4': 1, '5': 5, '10': 'maxTokens'},
    {'1': 'user_id', '3': 5, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'top_p', '3': 6, '4': 1, '5': 2, '10': 'topP'},
  ],
};

/// Descriptor for `ChatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatRequestDescriptor = $convert.base64Decode(
    'CgtDaGF0UmVxdWVzdBIUCgVtb2RlbBgBIAEoCVIFbW9kZWwSMAoIbWVzc2FnZXMYAiADKAsyFC'
    '5sbG1fZ2F0ZXdheS5NZXNzYWdlUghtZXNzYWdlcxIgCgt0ZW1wZXJhdHVyZRgDIAEoAlILdGVt'
    'cGVyYXR1cmUSHQoKbWF4X3Rva2VucxgEIAEoBVIJbWF4VG9rZW5zEhcKB3VzZXJfaWQYBSABKA'
    'lSBnVzZXJJZBITCgV0b3BfcBgGIAEoAlIEdG9wUA==');

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'role', '3': 1, '4': 1, '5': 9, '10': 'role'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEhIKBHJvbGUYASABKAlSBHJvbGUSGAoHY29udGVudBgCIAEoCVIHY29udGVudA'
    '==');

@$core.Deprecated('Use chatResponseDescriptor instead')
const ChatResponse$json = {
  '1': 'ChatResponse',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'model', '3': 2, '4': 1, '5': 9, '10': 'model'},
    {
      '1': 'choice',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.llm_gateway.Choice',
      '10': 'choice'
    },
    {'1': 'created', '3': 4, '4': 1, '5': 4, '10': 'created'},
    {'1': 'done', '3': 5, '4': 1, '5': 8, '10': 'done'},
  ],
};

/// Descriptor for `ChatResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatResponseDescriptor = $convert.base64Decode(
    'CgxDaGF0UmVzcG9uc2USDgoCaWQYASABKAlSAmlkEhQKBW1vZGVsGAIgASgJUgVtb2RlbBIrCg'
    'ZjaG9pY2UYAyABKAsyEy5sbG1fZ2F0ZXdheS5DaG9pY2VSBmNob2ljZRIYCgdjcmVhdGVkGAQg'
    'ASgEUgdjcmVhdGVkEhIKBGRvbmUYBSABKAhSBGRvbmU=');

@$core.Deprecated('Use chatCompletionResponseDescriptor instead')
const ChatCompletionResponse$json = {
  '1': 'ChatCompletionResponse',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'model', '3': 2, '4': 1, '5': 9, '10': 'model'},
    {
      '1': 'choices',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.llm_gateway.Choice',
      '10': 'choices'
    },
    {'1': 'created', '3': 4, '4': 1, '5': 4, '10': 'created'},
    {
      '1': 'usage_prompt_tokens',
      '3': 5,
      '4': 1,
      '5': 4,
      '10': 'usagePromptTokens'
    },
    {
      '1': 'usage_completion_tokens',
      '3': 6,
      '4': 1,
      '5': 4,
      '10': 'usageCompletionTokens'
    },
    {
      '1': 'usage_total_tokens',
      '3': 7,
      '4': 1,
      '5': 4,
      '10': 'usageTotalTokens'
    },
  ],
};

/// Descriptor for `ChatCompletionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatCompletionResponseDescriptor = $convert.base64Decode(
    'ChZDaGF0Q29tcGxldGlvblJlc3BvbnNlEg4KAmlkGAEgASgJUgJpZBIUCgVtb2RlbBgCIAEoCV'
    'IFbW9kZWwSLQoHY2hvaWNlcxgDIAMoCzITLmxsbV9nYXRld2F5LkNob2ljZVIHY2hvaWNlcxIY'
    'CgdjcmVhdGVkGAQgASgEUgdjcmVhdGVkEi4KE3VzYWdlX3Byb21wdF90b2tlbnMYBSABKARSEX'
    'VzYWdlUHJvbXB0VG9rZW5zEjYKF3VzYWdlX2NvbXBsZXRpb25fdG9rZW5zGAYgASgEUhV1c2Fn'
    'ZUNvbXBsZXRpb25Ub2tlbnMSLAoSdXNhZ2VfdG90YWxfdG9rZW5zGAcgASgEUhB1c2FnZVRvdG'
    'FsVG9rZW5z');

@$core.Deprecated('Use choiceDescriptor instead')
const Choice$json = {
  '1': 'Choice',
  '2': [
    {
      '1': 'message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.llm_gateway.Message',
      '10': 'message'
    },
    {'1': 'finish_reason', '3': 2, '4': 1, '5': 9, '10': 'finishReason'},
    {'1': 'index', '3': 3, '4': 1, '5': 5, '10': 'index'},
  ],
};

/// Descriptor for `Choice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List choiceDescriptor = $convert.base64Decode(
    'CgZDaG9pY2USLgoHbWVzc2FnZRgBIAEoCzIULmxsbV9nYXRld2F5Lk1lc3NhZ2VSB21lc3NhZ2'
    'USIwoNZmluaXNoX3JlYXNvbhgCIAEoCVIMZmluaXNoUmVhc29uEhQKBWluZGV4GAMgASgFUgVp'
    'bmRleA==');