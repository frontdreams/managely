enum MessageSender { employee, manager }

class Message {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  bool get isManager => sender == MessageSender.manager;
}
