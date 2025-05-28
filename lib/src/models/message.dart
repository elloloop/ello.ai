class Message {
  Message({required this.content, required this.isUser});

  final String content;
  final bool isUser;

  factory Message.user(String content) => Message(content: content, isUser: true);
  factory Message.assistant(String content) =>
      Message(content: content, isUser: false);

  Message appendContent(String chunk) =>
      Message(content: content + chunk, isUser: isUser);
}
