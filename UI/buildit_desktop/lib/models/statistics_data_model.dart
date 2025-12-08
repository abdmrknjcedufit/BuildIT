import 'package:json_annotation/json_annotation.dart';

part 'statistics_data_model.g.dart';

@JsonSerializable()
class StatisticsData {
  final double averageOrderValue;
  final double totalRevenue;
  final int totalOrders;
  final int totalActiveUsers;
  final int totalActiveListings;
  final double averageItemsPerOrder;
  final double averageRating;
  final List<MonthlyOrderData> monthlyOrders;
  final List<BestSellingItem> bestSellingItems;

  StatisticsData({
    required this.averageOrderValue,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalActiveUsers,
    required this.totalActiveListings,
    required this.averageItemsPerOrder,
    required this.averageRating,
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

