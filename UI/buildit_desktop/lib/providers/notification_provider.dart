import 'dart:convert';
import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/models/notification_model.dart';
import 'package:http/http.dart' as http;

class NotificationProvider extends BaseProvider<Notification> {
  NotificationProvider() : super("Notification");

  @override
  Notification fromJson(data) {
    return Notification.fromJson(data);
  }

  Future<void> markAsRead(int notificationId) async {
    await update(notificationId, {'isRead': true});
  }
}

