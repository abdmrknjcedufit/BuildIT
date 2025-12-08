import 'package:buildit_desktop/models/user_model.dart';

class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final User? sender;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      conversationId: json['conversationId'] as int,
      senderId: json['senderId'] as int,
      content: json['content'] as String,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sender: json['sender'] != null ? User.fromJson(json['sender'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
    };
  }
}

