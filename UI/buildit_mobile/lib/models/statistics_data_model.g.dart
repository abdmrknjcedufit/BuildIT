// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statistics_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatisticsData _$StatisticsDataFromJson(Map<String, dynamic> json) =>
    StatisticsData(
      averageOrderValue: (json['averageOrderValue'] as num).toDouble(),
      conversionRate: (json['conversionRate'] as num).toDouble(),
      userRetention: (json['userRetention'] as num).toDouble(),
      averageDeliveryTime: (json['averageDeliveryTime'] as num).toDouble(),
      monthlyOrders: (json['monthlyOrders'] as List<dynamic>)
          .map((e) => MonthlyOrderData.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestSellingItems: (json['bestSellingItems'] as List<dynamic>)
          .map((e) => BestSellingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StatisticsDataToJson(StatisticsData instance) =>
    <String, dynamic>{
      'averageOrderValue': instance.averageOrderValue,
      'conversionRate': instance.conversionRate,
      'userRetention': instance.userRetention,
      'averageDeliveryTime': instance.averageDeliveryTime,
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
