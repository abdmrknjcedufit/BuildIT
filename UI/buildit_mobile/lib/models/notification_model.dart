class Notification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String notificationType;
  final int? referenceId;
  final bool isRead;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime createdAt;
  final String priority;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.referenceId,
    required this.isRead,
    required this.isSent,
    this.sentAt,
    required this.createdAt,
    required this.priority,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType: json['notificationType'] as String,
      referenceId: json['referenceId'] as int?,
      isRead: json['isRead'] as bool,
      isSent: json['isSent'] as bool,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      priority: json['priority'] as String,
    );
  }
}

