import 'package:buildit_mobile/models/user_model.dart';
import 'package:buildit_mobile/models/listing_model.dart';
import 'package:buildit_mobile/models/message_model.dart';

class Conversation {
  final int id;
  final int user1Id;
  final int user2Id;
  final int? listingId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final User? user1;
  final User? user2;
  final Listing? listing;
  final List<Message>? messages;
  final int unreadCount;
  final Message? lastMessage;

  Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.listingId,
    required this.createdAt,
    this.updatedAt,
    this.user1,
    this.user2,
    this.listing,
    this.messages,
    this.unreadCount = 0,
    this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      user1Id: json['user1Id'] as int,
      user2Id: json['user2Id'] as int,
      listingId: json['listingId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      user1: json['user1'] != null ? User.fromJson(json['user1'] as Map<String, dynamic>) : null,
      user2: json['user2'] != null ? User.fromJson(json['user2'] as Map<String, dynamic>) : null,
      listing: json['listing'] != null ? Listing.fromJson(json['listing'] as Map<String, dynamic>) : null,
      messages: json['messages'] != null
          ? (json['messages'] as List).map((m) => Message.fromJson(m as Map<String, dynamic>)).toList()
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
    );
  }
}

