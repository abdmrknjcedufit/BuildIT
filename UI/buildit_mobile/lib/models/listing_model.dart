import 'package:json_annotation/json_annotation.dart';
import 'package:buildit_mobile/models/item_model.dart';
import 'package:buildit_mobile/models/user_model.dart';
import 'package:buildit_mobile/models/city_model.dart';

part 'listing_model.g.dart';

@JsonSerializable()
class Listing {
  final int id;
  final int itemId;
  final int userId;
  final String title;
  final String description;
  final String listingType;
  final String status;
  final int? cityId;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? images;
  final int? minRentalDays;
  final int? maxRentalDays;
  final Item? item;
  @JsonKey(name: 'user')
  final User? user;
  @JsonKey(name: 'city')
  final City? city;

  Listing({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.title,
    required this.description,
    required this.listingType,
    required this.status,
    this.cityId,
    required this.isFeatured,
    required this.createdAt,
    this.updatedAt,
    this.images,
    this.minRentalDays,
    this.maxRentalDays,
    this.item,
    this.user,
    this.city,
  });

  factory Listing.fromJson(Map<String, dynamic> json) => _$ListingFromJson(json);

  Map<String, dynamic> toJson() => _$ListingToJson(this);
}

