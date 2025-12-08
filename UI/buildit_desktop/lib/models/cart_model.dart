import 'package:buildit_desktop/models/listing_model.dart';

class Cart {
  final int id;
  final int userId;
  final int listingId;
  final int quantity;
  final int? rentalDays;
  final double? pricePerDay;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Listing? listing;

  Cart({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.quantity,
    this.rentalDays,
    this.pricePerDay,
    required this.totalPrice,
    required this.createdAt,
    this.updatedAt,
    this.listing,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] as int,
      userId: json['userId'] as int,
      listingId: json['listingId'] as int,
      quantity: json['quantity'] as int,
      rentalDays: json['rentalDays'] as int?,
      pricePerDay: json['pricePerDay'] != null ? (json['pricePerDay'] as num).toDouble() : null,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      listing: json['listing'] != null ? Listing.fromJson(json['listing'] as Map<String, dynamic>) : null,
    );
  }
}

