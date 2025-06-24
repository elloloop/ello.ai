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

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Message types
class MessageType extends $pb.ProtobufEnum {
  static const MessageType USER_QUERY =
      MessageType._(0, _omitEnumNames ? '' : 'USER_QUERY');
  static const MessageType ASSISTANT_RESPONSE =
      MessageType._(1, _omitEnumNames ? '' : 'ASSISTANT_RESPONSE');
  static const MessageType ACTION_REQUEST =
      MessageType._(2, _omitEnumNames ? '' : 'ACTION_REQUEST');
  static const MessageType ACTION_RESPONSE =
      MessageType._(3, _omitEnumNames ? '' : 'ACTION_RESPONSE');

  static const $core.List<MessageType> values = <MessageType>[
    USER_QUERY,
    ASSISTANT_RESPONSE,
    ACTION_REQUEST,
    ACTION_RESPONSE,
  ];

  static final $core.List<MessageType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static MessageType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MessageType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
