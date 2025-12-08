import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/models/conversation_model.dart';

class ConversationProvider extends BaseProvider<Conversation> {
  ConversationProvider() : super("Conversation");

  @override
  Conversation fromJson(data) {
    return Conversation.fromJson(data);
  }

  Future<Conversation> getOrCreate({
    required int user1Id,
    required int user2Id,
    int? listingId,
  }) async {
    final response = await http.post(
      Uri.parse('${BaseProvider.baseUrl}Conversation/get-or-create'),
      headers: createHeaders(),
      body: jsonEncode({
        'user1Id': user1Id,
        'user2Id': user2Id,
        'listingId': listingId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception('Greška pri kreiranju konverzacije: ${response.statusCode}');
    }
  }
}

