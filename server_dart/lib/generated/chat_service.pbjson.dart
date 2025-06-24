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

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use messageTypeDescriptor instead')
const MessageType$json = {
  '1': 'MessageType',
  '2': [
    {'1': 'USER_QUERY', '2': 0},
    {'1': 'ASSISTANT_RESPONSE', '2': 1},
    {'1': 'ACTION_REQUEST', '2': 2},
    {'1': 'ACTION_RESPONSE', '2': 3},
  ],
};

/// Descriptor for `MessageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageTypeDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlVHlwZRIOCgpVU0VSX1FVRVJZEAASFgoSQVNTSVNUQU5UX1JFU1BPTlNFEAESEg'
    'oOQUNUSU9OX1JFUVVFU1QQAhITCg9BQ1RJT05fUkVTUE9OU0UQAw==');

@$core.Deprecated('Use chatMessageDescriptor instead')
const ChatMessage$json = {
  '1': 'ChatMessage',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {
      '1': 'type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.chat.MessageType',
      '10': 'type'
    },
    {'1': 'available_tools', '3': 4, '4': 3, '5': 9, '10': 'availableTools'},
    {
      '1': 'actions',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.chat.ActionRequest',
      '10': 'actions'
    },
    {'1': 'conversation_id', '3': 6, '4': 1, '5': 9, '10': 'conversationId'},
  ],
};

/// Descriptor for `ChatMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chatMessageDescriptor = $convert.base64Decode(
    'CgtDaGF0TWVzc2FnZRIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQSGAoHY29udGVudB'
    'gCIAEoCVIHY29udGVudBIlCgR0eXBlGAMgASgOMhEuY2hhdC5NZXNzYWdlVHlwZVIEdHlwZRIn'
    'Cg9hdmFpbGFibGVfdG9vbHMYBCADKAlSDmF2YWlsYWJsZVRvb2xzEi0KB2FjdGlvbnMYBSADKA'
    'syEy5jaGF0LkFjdGlvblJlcXVlc3RSB2FjdGlvbnMSJwoPY29udmVyc2F0aW9uX2lkGAYgASgJ'
    'Ug5jb252ZXJzYXRpb25JZA==');

@$core.Deprecated('Use actionRequestDescriptor instead')
const ActionRequest$json = {
  '1': 'ActionRequest',
  '2': [
    {'1': 'action_id', '3': 1, '4': 1, '5': 9, '10': 'actionId'},
    {'1': 'description', '3': 2, '4': 1, '5': 9, '10': 'description'},
    {'1': 'required_inputs', '3': 3, '4': 3, '5': 9, '10': 'requiredInputs'},
  ],
};

/// Descriptor for `ActionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List actionRequestDescriptor = $convert.base64Decode(
    'Cg1BY3Rpb25SZXF1ZXN0EhsKCWFjdGlvbl9pZBgBIAEoCVIIYWN0aW9uSWQSIAoLZGVzY3JpcH'
    'Rpb24YAiABKAlSC2Rlc2NyaXB0aW9uEicKD3JlcXVpcmVkX2lucHV0cxgDIAMoCVIOcmVxdWly'
    'ZWRJbnB1dHM=');

@$core.Deprecated('Use startConversationRequestDescriptor instead')
const StartConversationRequest$json = {
  '1': 'StartConversationRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'conversation_id', '3': 2, '4': 1, '5': 9, '10': 'conversationId'},
  ],
};

/// Descriptor for `StartConversationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startConversationRequestDescriptor =
    $convert.base64Decode(
        'ChhTdGFydENvbnZlcnNhdGlvblJlcXVlc3QSGwoJY2xpZW50X2lkGAEgASgJUghjbGllbnRJZB'
        'InCg9jb252ZXJzYXRpb25faWQYAiABKAlSDmNvbnZlcnNhdGlvbklk');

@$core.Deprecated('Use startConversationResponseDescriptor instead')
const StartConversationResponse$json = {
  '1': 'StartConversationResponse',
  '2': [
    {'1': 'conversation_id', '3': 1, '4': 1, '5': 9, '10': 'conversationId'},
  ],
};

/// Descriptor for `StartConversationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startConversationResponseDescriptor =
    $convert.base64Decode(
        'ChlTdGFydENvbnZlcnNhdGlvblJlc3BvbnNlEicKD2NvbnZlcnNhdGlvbl9pZBgBIAEoCVIOY2'
        '9udmVyc2F0aW9uSWQ=');

@$core.Deprecated('Use progressUpdateDescriptor instead')
const ProgressUpdate$json = {
  '1': 'ProgressUpdate',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {'1': 'progress', '3': 2, '4': 1, '5': 2, '10': 'progress'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `ProgressUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List progressUpdateDescriptor = $convert.base64Decode(
    'Cg5Qcm9ncmVzc1VwZGF0ZRIWCgZzdGF0dXMYASABKAlSBnN0YXR1cxIaCghwcm9ncmVzcxgCIA'
    'EoAlIIcHJvZ3Jlc3MSGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use progressRequestDescriptor instead')
const ProgressRequest$json = {
  '1': 'ProgressRequest',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
  ],
};

/// Descriptor for `ProgressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List progressRequestDescriptor = $convert.base64Decode(
    'Cg9Qcm9ncmVzc1JlcXVlc3QSHQoKcmVxdWVzdF9pZBgBIAEoCVIJcmVxdWVzdElk');
