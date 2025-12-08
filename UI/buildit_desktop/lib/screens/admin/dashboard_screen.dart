import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/dashboard_provider.dart';
import 'package:buildit_desktop/models/dashboard_stats_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:buildit_desktop/l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardProvider _dashboardProvider = DashboardProvider();
  DashboardStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
      });
      var stats = await _dashboardProvider.getStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorLoadingDashboard}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightGray,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).adminDashboard,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).overviewOfBuildITActivity,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  )
                : _stats == null
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context).noData,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.darkGray,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          _buildKPICards(),
                          const SizedBox(height: 32),
                          _buildRevenueChart(),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    if (_stats == null) return const SizedBox();
    
    final formatter = NumberFormat('#,###');
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            title: AppLocalizations.of(context).totalUsers,
            value: formatter.format(_stats!.totalUsers),
            change: '',
            icon: Icons.people,
            isPositive: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            title: AppLocalizations.of(context).allOrdersCount,
            value: formatter.format(_stats!.totalOrders),
            change: '',
            icon: Icons.shopping_cart,
            isPositive: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            title: AppLocalizations.of(context).totalRevenue,
            value: currencyFormatter.format(_stats!.totalRevenue),
            change: '',
            icon: Icons.attach_money,
            isPositive: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            title: AppLocalizations.of(context).activeRentals,
            value: formatter.format(_stats!.activeRentals),
            change: '',
            icon: Icons.trending_up,
            isPositive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).revenueAndOrdersTrend,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).monthlyOverviewLast7Months,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: _stats == null
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.lightGray,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (_stats == null) return const Text('');
                              if (value.toInt() >= 1 && value.toInt() <= _stats!.orderTrend.length) {
                                return Text(
                                  _stats!.orderTrend[value.toInt() - 1].month,
                                  style: const TextStyle(
                                    color: AppColors.darkGray,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: AppColors.darkGray,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      minX: 1,
                      maxX: _stats?.orderTrend.length.toDouble() ?? 7,
                      minY: 0,
                      maxY: _stats != null
                          ? [
                              ..._stats!.orderTrend.map((e) => e.value),
                              ..._stats!.revenueTrend.map((e) => e.value),
                            ].reduce((a, b) => a > b ? a : b) * 1.1
                          : 4000,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _stats != null
                              ? _stats!.orderTrend.asMap().entries.map((entry) {
                                  return FlSpot(entry.key + 1, entry.value.value);
                                }).toList()
                              : [],
                          isCurved: true,
                          color: AppColors.darkGray,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                        LineChartBarData(
                          spots: _stats != null
                              ? _stats!.revenueTrend.asMap().entries.map((entry) {
                                  return FlSpot(entry.key + 1, entry.value.value);
                                }).toList()
                              : [],
                          isCurved: true,
                          color: AppColors.primaryOrange,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppLocalizations.of(context).ordersLegend, AppColors.darkGray),
              const SizedBox(width: 24),
              _buildLegendItem(AppLocalizations.of(context).revenueLegend, AppColors.primaryOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkGray,
          ),
        ),
      ],
    );
  }
}

