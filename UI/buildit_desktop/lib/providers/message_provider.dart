import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/models/message_model.dart';

class MessageProvider extends BaseProvider<Message> {
  MessageProvider() : super("Message");

  @override
  Message fromJson(data) {
    return Message.fromJson(data);
  }

  Future<void> markAsRead(int messageId, int userId) async {
    final response = await http.post(
      Uri.parse('${BaseProvider.baseUrl}Message/$messageId/mark-read?userId=$userId'),
      headers: createHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Greška pri označavanju poruke kao pročitane: ${response.statusCode}');
    }
  }

  Future<void> markConversationAsRead(int conversationId, int userId) async {
    final response = await http.post(
      Uri.parse('${BaseProvider.baseUrl}Message/conversation/$conversationId/mark-read?userId=$userId'),
      headers: createHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Greška pri označavanju konverzacije kao pročitane: ${response.statusCode}');
    }
  }
}

