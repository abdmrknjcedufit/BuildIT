// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardStats _$DashboardStatsFromJson(Map<String, dynamic> json) =>
    DashboardStats(
      totalUsers: (json['totalUsers'] as num).toInt(),
      totalOrders: (json['totalOrders'] as num).toInt(),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      activeRentals: (json['activeRentals'] as num).toInt(),
      revenueTrend: (json['revenueTrend'] as List<dynamic>)
          .map((e) => MonthlyData.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderTrend: (json['orderTrend'] as List<dynamic>)
          .map((e) => MonthlyData.fromJson(e as Map<String, dynamic>))
          .toList(),
      productDistribution: (json['productDistribution'] as List<dynamic>)
          .map((e) => CategoryDistribution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardStatsToJson(DashboardStats instance) =>
    <String, dynamic>{
      'totalUsers': instance.totalUsers,
      'totalOrders': instance.totalOrders,
      'totalRevenue': instance.totalRevenue,
      'activeRentals': instance.activeRentals,
      'revenueTrend': instance.revenueTrend,
      'orderTrend': instance.orderTrend,
      'productDistribution': instance.productDistribution,
    };

MonthlyData _$MonthlyDataFromJson(Map<String, dynamic> json) => MonthlyData(
  month: json['month'] as String,
  value: (json['value'] as num).toDouble(),
);

Map<String, dynamic> _$MonthlyDataToJson(MonthlyData instance) =>
    <String, dynamic>{'month': instance.month, 'value': instance.value};

CategoryDistribution _$CategoryDistributionFromJson(
  Map<String, dynamic> json,
) => CategoryDistribution(
  category: json['category'] as String,
  percentage: (json['percentage'] as num).toDouble(),
);

Map<String, dynamic> _$CategoryDistributionToJson(
  CategoryDistribution instance,
) => <String, dynamic>{
  'category': instance.category,
  'percentage': instance.percentage,
};
