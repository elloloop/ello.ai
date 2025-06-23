import 'package:fixnum/fixnum.dart';
import '../generated/chat.pb.dart';
import '../generated/chat.pbenum.dart';

/// Utility class to convert between app Message model and proto Message objects
class MessageConverter {
  /// Convert a list of app Message objects to proto Message objects
  static List<Message> toProtoMessages(List<dynamic> appMessages) {
    return appMessages.map((msg) => toProtoMessage(msg)).toList();
  }

  /// Convert a single app Message to a proto Message
  static Message toProtoMessage(dynamic appMsg) {
    return Message(
      content: appMsg.content,
      role: appMsg.role == 'user' ? Message_Role.USER : Message_Role.ASSISTANT,
      timestamp: Int64(appMsg.timestamp?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Convert a proto Message to an app Message
  static dynamic fromProtoMessage(Message protoMsg) {
    return AppMessage(
      content: protoMsg.content,
      role: protoMsg.role == Message_Role.USER ? 'user' : 'assistant',
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(protoMsg.timestamp.toInt()),
    );
  }
}

// Simple placeholder for app message - replace with your actual Message class
class AppMessage {
  final String content;
  final String role;
  final DateTime timestamp;

  AppMessage({
    required this.content,
    required this.role,
    required this.timestamp,
  });
}
