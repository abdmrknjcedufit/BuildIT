// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Listing _$ListingFromJson(Map<String, dynamic> json) => Listing(
  id: (json['id'] as num).toInt(),
  itemId: (json['itemId'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  listingType: json['listingType'] as String,
  status: json['status'] as String,
  cityId: (json['cityId'] as num?)?.toInt(),
  isFeatured: json['isFeatured'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  images: json['images'] as String?,
  minRentalDays: (json['minRentalDays'] as num?)?.toInt(),
  maxRentalDays: (json['maxRentalDays'] as num?)?.toInt(),
  item: json['item'] == null
      ? null
      : Item.fromJson(json['item'] as Map<String, dynamic>),
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
  city: json['city'] == null
      ? null
      : City.fromJson(json['city'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ListingToJson(Listing instance) => <String, dynamic>{
  'id': instance.id,
  'itemId': instance.itemId,
  'userId': instance.userId,
  'title': instance.title,
  'description': instance.description,
  'listingType': instance.listingType,
  'status': instance.status,
  'cityId': instance.cityId,
  'isFeatured': instance.isFeatured,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'images': instance.images,
  'minRentalDays': instance.minRentalDays,
  'maxRentalDays': instance.maxRentalDays,
  'item': instance.item,
  'user': instance.user,
  'city': instance.city,
};
