// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  itemType: json['itemType'] as String,
  status: json['status'] as String,
  condition: json['condition'] as String,
  companyId: (json['companyId'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  categoryId: (json['categoryId'] as num?)?.toInt(),
  minRentalPeriod: (json['minRentalPeriod'] as num?)?.toInt(),
  maxRentalPeriod: (json['maxRentalPeriod'] as num?)?.toInt(),
  brand: json['brand'] as String?,
  model: json['model'] as String?,
  year: (json['year'] as num?)?.toInt(),
  availabilityDate: json['availabilityDate'] == null
      ? null
      : DateTime.parse(json['availabilityDate'] as String),
  totalPurchases: (json['totalPurchases'] as num).toInt(),
  totalRentals: (json['totalRentals'] as num).toInt(),
  totalOrders: (json['totalOrders'] as num).toInt(),
  lastSoldDate: json['lastSoldDate'] == null
      ? null
      : DateTime.parse(json['lastSoldDate'] as String),
  lastRentedDate: json['lastRentedDate'] == null
      ? null
      : DateTime.parse(json['lastRentedDate'] as String),
  isAvailable: json['isAvailable'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  images: json['images'] as String?,
);

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'price': instance.price,
  'itemType': instance.itemType,
  'status': instance.status,
  'condition': instance.condition,
  'companyId': instance.companyId,
  'userId': instance.userId,
  'categoryId': instance.categoryId,
  'minRentalPeriod': instance.minRentalPeriod,
  'maxRentalPeriod': instance.maxRentalPeriod,
  'brand': instance.brand,
  'model': instance.model,
  'year': instance.year,
  'availabilityDate': instance.availabilityDate?.toIso8601String(),
  'totalPurchases': instance.totalPurchases,
  'totalRentals': instance.totalRentals,
  'totalOrders': instance.totalOrders,
  'lastSoldDate': instance.lastSoldDate?.toIso8601String(),
  'lastRentedDate': instance.lastRentedDate?.toIso8601String(),
  'isAvailable': instance.isAvailable,
  'createdAt': instance.createdAt.toIso8601String(),
  'images': instance.images,
};
