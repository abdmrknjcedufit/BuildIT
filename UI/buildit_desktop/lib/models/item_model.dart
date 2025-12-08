import 'package:json_annotation/json_annotation.dart';

part 'item_model.g.dart';

@JsonSerializable()
class Item {
  final int id;
  final String title;
  final String description;
  final double price;
  final String itemType;
  final String status;
  final String condition;
  final int? companyId;
  final int? userId;
  final int? categoryId;
  final int? minRentalPeriod;
  final int? maxRentalPeriod;
  final String? brand;
  final String? model;
  final int? year;
  final DateTime? availabilityDate;
  final int totalPurchases;
  final int totalRentals;
  final int totalOrders;
  final DateTime? lastSoldDate;
  final DateTime? lastRentedDate;
  final bool isAvailable;
  final DateTime createdAt;
  final String? images;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.itemType,
    required this.status,
    required this.condition,
    this.companyId,
    this.userId,
    this.categoryId,
    this.minRentalPeriod,
    this.maxRentalPeriod,
    this.brand,
    this.model,
    this.year,
    this.availabilityDate,
    required this.totalPurchases,
    required this.totalRentals,
    required this.totalOrders,
    this.lastSoldDate,
    this.lastRentedDate,
    required this.isAvailable,
    required this.createdAt,
    this.images,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

