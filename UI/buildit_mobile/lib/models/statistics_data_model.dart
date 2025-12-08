import 'package:json_annotation/json_annotation.dart';

part 'statistics_data_model.g.dart';

@JsonSerializable()
class StatisticsData {
  final double averageOrderValue;
  final double conversionRate;
  final double userRetention;
  final double averageDeliveryTime;
  final List<MonthlyOrderData> monthlyOrders;
  final List<BestSellingItem> bestSellingItems;

  StatisticsData({
    required this.averageOrderValue,
    required this.conversionRate,
    required this.userRetention,
    required this.averageDeliveryTime,
    required this.monthlyOrders,
    required this.bestSellingItems,
  });

  factory StatisticsData.fromJson(Map<String, dynamic> json) =>
      _$StatisticsDataFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsDataToJson(this);
}

@JsonSerializable()
class MonthlyOrderData {
  final String month;
  final int completed;
  final int pending;

  MonthlyOrderData({
    required this.month,
    required this.completed,
    required this.pending,
  });

  factory MonthlyOrderData.fromJson(Map<String, dynamic> json) =>
      _$MonthlyOrderDataFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyOrderDataToJson(this);
}

@JsonSerializable()
class BestSellingItem {
  final String name;
  final int salesCount;

  BestSellingItem({
    required this.name,
    required this.salesCount,
  });

  factory BestSellingItem.fromJson(Map<String, dynamic> json) =>
      _$BestSellingItemFromJson(json);

  Map<String, dynamic> toJson() => _$BestSellingItemToJson(this);
}

