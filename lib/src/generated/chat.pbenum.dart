//
//  Generated code. Do not modify.
//  source: chat.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Message types
class MessageType extends $pb.ProtobufEnum {
  static const MessageType USER_QUERY = MessageType._(0, _omitEnumNames ? '' : 'USER_QUERY');
  static const MessageType ASSISTANT_RESPONSE = MessageType._(1, _omitEnumNames ? '' : 'ASSISTANT_RESPONSE');
  static const MessageType ACTION_REQUEST = MessageType._(2, _omitEnumNames ? '' : 'ACTION_REQUEST');
  static const MessageType ACTION_RESPONSE = MessageType._(3, _omitEnumNames ? '' : 'ACTION_RESPONSE');

  static const $core.List<MessageType> values = <MessageType> [
    USER_QUERY,
    ASSISTANT_RESPONSE,
    ACTION_REQUEST,
    ACTION_RESPONSE,
  ];

  static final $core.Map<$core.int, MessageType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MessageType? valueOf($core.int value) => _byValue[value];

  const MessageType._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
