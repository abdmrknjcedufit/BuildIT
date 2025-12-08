import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/dashboard_provider.dart';
import 'package:buildit_desktop/models/statistics_data_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:buildit_desktop/l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DashboardProvider _dashboardProvider = DashboardProvider();
  StatisticsData? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
      });
      var stats = await _dashboardProvider.getStatistics();
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
            content: Text('${AppLocalizations.of(context).errorLoadingStatistics}: $e'),
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
              AppLocalizations.of(context).detailedStatistics,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).detailedAnalytics,
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildMonthlyOrdersChart(),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildBestSellingItemsChart(),
                              ),
                            ],
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    if (_stats == null) return const SizedBox();
    
    final currencyFormatter = NumberFormat.currency(symbol: 'KM ', decimalDigits: 2);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                title: AppLocalizations.of(context).averageOrderValue,
                value: currencyFormatter.format(_stats!.averageOrderValue),
                change: '',
                icon: Icons.shopping_bag,
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
                title: AppLocalizations.of(context).totalOrdersCount,
                value: _stats!.totalOrders.toString(),
                change: '',
                icon: Icons.receipt_long,
                isPositive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                title: AppLocalizations.of(context).activeUsersCount,
                value: _stats!.totalActiveUsers.toString(),
                change: '',
                icon: Icons.people,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                title: AppLocalizations.of(context).activeListingsCount,
                value: _stats!.totalActiveListings.toString(),
                change: '',
                icon: Icons.inventory_2,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                title: AppLocalizations.of(context).averageRating,
                value: _stats!.averageRating > 0 
                    ? '${_stats!.averageRating.toStringAsFixed(1)} ⭐'
                    : 'N/A',
                change: '',
                icon: Icons.star,
                isPositive: true,
              ),
            ),
          ],
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
    bool isFaster = false,
  }) {
    return SizedBox(
      height: 200,
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
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
            const Spacer(),
            Row(
              children: [
                Icon(
                  isFaster
                      ? Icons.arrow_downward
                      : (isPositive ? Icons.arrow_upward : Icons.arrow_downward),
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  change,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyOrdersChart() {
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
            AppLocalizations.of(context).monthlyOrders,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).completedVsPending,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _stats != null && _stats!.monthlyOrders.isNotEmpty
                    ? _stats!.monthlyOrders
                        .map((e) => (e.completed + e.pending).toDouble())
                        .reduce((a, b) => a > b ? a : b) * 1.1
                    : 400,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (_stats == null) return const Text('');
                        if (value.toInt() >= 1 && value.toInt() <= _stats!.monthlyOrders.length) {
                          return Text(
                            _stats!.monthlyOrders[value.toInt() - 1].month,
                            style: const TextStyle(
                              color: AppColors.darkGray,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.lightGray),
                ),
                barGroups: _stats != null && _stats!.monthlyOrders.isNotEmpty
                    ? _stats!.monthlyOrders.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: index + 1,
                          barRods: [
                            BarChartRodData(
                              toY: data.completed.toDouble(),
                              color: AppColors.primaryOrange,
                              width: 20,
                            ),
                            BarChartRodData(
                              toY: data.pending.toDouble(),
                              color: AppColors.darkGray,
                              width: 20,
                            ),
                          ],
                        );
                      }).toList()
                    : [],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppLocalizations.of(context).pending, AppColors.darkGray),
              const SizedBox(width: 24),
              _buildLegendItem(AppLocalizations.of(context).completed, AppColors.primaryOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellingItemsChart() {
    if (_stats == null || _stats!.bestSellingItems.isEmpty) {
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
        child: const Center(
          child: Text('Nema podataka'),
        ),
      );
    }

    final items = _stats!.bestSellingItems;
    
    if (items.isEmpty) {
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
        child: const Center(
          child: Text(
            'Nema podataka',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
        ),
      );
    }
    
    final maxValue = items.map((e) => e.salesCount).reduce((a, b) => a > b ? a : b);

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
            AppLocalizations.of(context).bestSellingItems,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).top5ProductsBySales,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: Column(
              children: items.map((item) {
                final percentage = maxValue > 0 
                    ? (item.salesCount / maxValue).clamp(0.0, 1.0)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkGray,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.lightGray,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percentage,
                              child: Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 50,
                        child: Text(
                          item.salesCount.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlack,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
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

