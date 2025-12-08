import 'package:buildit_mobile/models/listing_model.dart';
import 'package:buildit_mobile/models/user_model.dart';

class Transaction {
  final int id;
  final int listingId;
  final int buyerId;
  final int sellerId;
  final double amount;
  final String status;
  final String paymentMethod;
  final String type;
  final DateTime transactionDate;
  final String? stripeTransactionId;
  final DateTime createdAt;
  final Listing? listing;
  final User? seller;
  final User? buyer;

  Transaction({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.type,
    required this.transactionDate,
    this.stripeTransactionId,
    required this.createdAt,
    this.listing,
    this.seller,
    this.buyer,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      listingId: json['listingId'] as int,
      buyerId: json['buyerId'] as int,
      sellerId: json['sellerId'] as int,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['paymentMethod'] as String,
      type: json['type'] as String,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      stripeTransactionId: json['stripeTransactionId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      listing: json['listing'] != null ? Listing.fromJson(json['listing'] as Map<String, dynamic>) : null,
      seller: json['seller'] != null ? User.fromJson(json['seller'] as Map<String, dynamic>) : null,
      buyer: json['buyer'] != null ? User.fromJson(json['buyer'] as Map<String, dynamic>) : null,
    );
  }
}

