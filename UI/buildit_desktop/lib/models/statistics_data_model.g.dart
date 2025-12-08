// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatisticsData _$StatisticsDataFromJson(Map<String, dynamic> json) =>
    StatisticsData(
      averageOrderValue: (json['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalActiveUsers: (json['totalActiveUsers'] as num?)?.toInt() ?? 0,
      totalActiveListings: (json['totalActiveListings'] as num?)?.toInt() ?? 0,
      averageItemsPerOrder: (json['averageItemsPerOrder'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      monthlyOrders: (json['monthlyOrders'] as List<dynamic>?)
              ?.map((e) => MonthlyOrderData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bestSellingItems: (json['bestSellingItems'] as List<dynamic>?)
              ?.map((e) => BestSellingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$StatisticsDataToJson(StatisticsData instance) =>
    <String, dynamic>{
      'averageOrderValue': instance.averageOrderValue,
      'totalRevenue': instance.totalRevenue,
      'totalOrders': instance.totalOrders,
      'totalActiveUsers': instance.totalActiveUsers,
      'totalActiveListings': instance.totalActiveListings,
      'averageItemsPerOrder': instance.averageItemsPerOrder,
      'averageRating': instance.averageRating,
      'monthlyOrders': instance.monthlyOrders,
      'bestSellingItems': instance.bestSellingItems,
    };

MonthlyOrderData _$MonthlyOrderDataFromJson(Map<String, dynamic> json) =>
    MonthlyOrderData(
      month: json['month'] as String,
      completed: (json['completed'] as num).toInt(),
      pending: (json['pending'] as num).toInt(),
    );

Map<String, dynamic> _$MonthlyOrderDataToJson(MonthlyOrderData instance) =>
    <String, dynamic>{
      'month': instance.month,
      'completed': instance.completed,
      'pending': instance.pending,
    };

BestSellingItem _$BestSellingItemFromJson(Map<String, dynamic> json) =>
    BestSellingItem(
      name: json['name'] as String,
      salesCount: (json['salesCount'] as num).toInt(),
    );

Map<String, dynamic> _$BestSellingItemToJson(BestSellingItem instance) =>
    <String, dynamic>{'name': instance.name, 'salesCount': instance.salesCount};
