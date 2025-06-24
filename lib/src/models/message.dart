class Message {
  Message({
    required this.content, 
    required this.isUser,
    this.isStreaming = false,
    this.id,
  });

  final String content;
  final bool isUser;
  final bool isStreaming;
  final String? id;

  factory Message.user(String content) =>
      Message(content: content, isUser: true);
  
  factory Message.assistant(String content, {bool isStreaming = false, String? id}) =>
      Message(content: content, isUser: false, isStreaming: isStreaming, id: id);

  Message appendContent(String chunk) =>
      Message(
        content: content + chunk, 
        isUser: isUser, 
        isStreaming: isStreaming,
        id: id,
      );

  Message copyWith({
    String? content,
    bool? isUser,
    bool? isStreaming,
    String? id,
  }) =>
      Message(
        content: content ?? this.content,
        isUser: isUser ?? this.isUser,
        isStreaming: isStreaming ?? this.isStreaming,
        id: id ?? this.id,
      );
}
