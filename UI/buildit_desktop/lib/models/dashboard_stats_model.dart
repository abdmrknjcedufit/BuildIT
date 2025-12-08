import 'package:json_annotation/json_annotation.dart';

part 'dashboard_stats_model.g.dart';

@JsonSerializable()
class DashboardStats {
  final int totalUsers;
  final int totalOrders;
  final double totalRevenue;
  final int activeRentals;
  final List<MonthlyData> revenueTrend;
  final List<MonthlyData> orderTrend;
  final List<CategoryDistribution> productDistribution;

  DashboardStats({
    required this.totalUsers,
    required this.totalOrders,
    required this.totalRevenue,
    required this.activeRentals,
    required this.revenueTrend,
    required this.orderTrend,
    required this.productDistribution,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}

@JsonSerializable()
class MonthlyData {
  final String month;
  final double value;

  MonthlyData({
    required this.month,
    required this.value,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) =>
      _$MonthlyDataFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyDataToJson(this);
}

@JsonSerializable()
class CategoryDistribution {
  final String category;
  final double percentage;

  CategoryDistribution({
    required this.category,
    required this.percentage,
  });

  factory CategoryDistribution.fromJson(Map<String, dynamic> json) =>
      _$CategoryDistributionFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryDistributionToJson(this);
}

