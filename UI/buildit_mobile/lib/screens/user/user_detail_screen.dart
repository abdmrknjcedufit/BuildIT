import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:convert' show base64Encode, utf8;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class UserReview {
  final int id;
  final int reviewerId;
  final Map<String, dynamic>? reviewer;
  final int rating;
  final String? comment;
  final int? transactionId;
  final DateTime createdAt;

  UserReview({
    required this.id,
    required this.reviewerId,
    this.reviewer,
    required this.rating,
    this.comment,
    this.transactionId,
    required this.createdAt,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      id: json['id'] as int,
      reviewerId: json['reviewerId'] as int,
      reviewer: json['reviewer'] as Map<String, dynamic>?,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      transactionId: json['transactionId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final UserProvider _userProvider = UserProvider();
  User? _user;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  List<UserReview> _reviews = [];
  bool _isLoading = true;
  Map<String, dynamic>? _profitStats;
  bool _isLoadingProfit = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadProfitStats();
  }

  Future<void> _loadProfitStats() async {
    if (AuthProvider.id != widget.userId) return;
    
    setState(() {
      _isLoadingProfit = true;
    });

    try {
      var url = "${BaseProvider.baseUrl}User/${widget.userId}/profit";
      var uri = Uri.parse(url);
      
      var headers = {
        "Content-Type": "application/json",
        "Authorization": "Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}",
      };

      var response = await http.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        var data = jsonDecode(response.body);
        setState(() {
          _profitStats = data;
          _isLoadingProfit = false;
        });
      } else {
        setState(() {
          _isLoadingProfit = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProfit = false;
      });
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = await _userProvider.getById(widget.userId);
      
      try {
        final reviewsResponse = await http.get(
          Uri.parse('${BaseProvider.baseUrl}User/${widget.userId}/reviews'),
        );

        if (reviewsResponse.statusCode == 200) {
          final reviewsData = jsonDecode(reviewsResponse.body) as Map<String, dynamic>;
          
          if (reviewsData['reviews'] != null) {
            _reviews = (reviewsData['reviews'] as List)
                .map((r) => UserReview.fromJson(r as Map<String, dynamic>))
                .toList();
          }
          
          _averageRating = (reviewsData['averageRating'] as num?)?.toDouble() ?? 0.0;
          _totalReviews = reviewsData['totalReviews'] as int? ?? 0;
        }
      } catch (e) {
        print('Greška pri učitavanju review-a: $e');
      }

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorLoadingUser}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).userProfile),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : _user == null
              ? Center(
                  child: Text(AppLocalizations.of(context).userNotFound),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 16),
                      if (AuthProvider.id == widget.userId && _profitStats != null) ...[
                        _buildProfitSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildRatingSection(),
                      const SizedBox(height: 16),
                      if (_reviews.isNotEmpty) ...[
                        _buildReviewsSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildUserInfo(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${_user!.firstName[0]}${_user!.lastName[0]}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOrange,
                  AppColors.primaryOrange.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '${_user!.firstName} ${_user!.lastName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_user!.username.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '@${_user!.username}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star,
            color: Colors.amber,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _averageRating > 0 ? _averageRating.toStringAsFixed(1) : '0.0',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
              Text(
                _totalReviews > 0 
                    ? '$_totalReviews ${_totalReviews == 1 ? AppLocalizations.of(context).rating : AppLocalizations.of(context).ratings}'
                    : AppLocalizations.of(context).noRatings,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final dateFormat = DateFormat('dd. MM. yyyy.');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.reviews, color: AppColors.primaryOrange, size: 24),
              SizedBox(width: 8),
              Text(
                'Ocjene i komentari',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).noRatings,
                  style: const TextStyle(
                    color: AppColors.darkGray,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                final reviewerName = review.reviewer != null
                    ? '${review.reviewer!['firstName']} ${review.reviewer!['lastName']}'
                    : 'Nepoznat korisnik';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.lightGray,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              reviewerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlack,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              ...List.generate(5, (i) {
                                return Icon(
                                  i < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${review.rating}/5',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlack,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (review.comment != null && review.comment!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          review.comment!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        dateFormat.format(review.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final dateFormat = DateFormat('dd. MM. yyyy.');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informacije',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 16),
          if (_user!.email.isNotEmpty)
            _buildInfoRow(Icons.email, 'Email', _user!.email),
          if (_user!.phone != null && _user!.phone!.isNotEmpty)
            _buildInfoRow(Icons.phone, 'Telefon', _user!.phone!),
          if (_user!.address != null && _user!.address!.isNotEmpty)
            _buildInfoRow(Icons.location_on, 'Adresa', _user!.address!),
          if (_user!.postalCode != null && _user!.postalCode!.isNotEmpty)
            _buildInfoRow(Icons.markunread_mailbox, 'Poštanski broj', _user!.postalCode!),
          _buildInfoRow(Icons.cake, 'Datum rođenja', dateFormat.format(_user!.birthDate)),
          _buildInfoRow(Icons.badge, 'Tip korisnika', _user!.userType == 'Individual' ? 'Fizičko lice' : 'Pravno lice'),
          _buildInfoRow(
            Icons.check_circle,
            'Status',
            _user!.isActive ? 'Aktivan' : 'Neaktivan',
            _user!.isActive ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitSection() {
    if (_profitStats == null || _isLoadingProfit) {
      return const SizedBox.shrink();
    }

    final totalProfit = (_profitStats!['totalProfit'] as num?)?.toDouble() ?? 0.0;
    final totalSales = _profitStats!['totalSales'] as int? ?? 0;
    final dailyProfits = _profitStats!['dailyProfits'] as List<dynamic>? ?? [];
    final monthlyProfits = _profitStats!['monthlyProfits'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.primaryOrange, size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).profitAndSales,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).totalProfit,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${NumberFormat.currency(symbol: 'KM ', decimalDigits: 2).format(totalProfit)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).totalSales,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalSales',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (dailyProfits.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).dailyProfitLast30Days,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyProfits.asMap().entries.map((e) {
                        final index = e.key.toDouble();
                        final amount = (e.value['amount'] as num?)?.toDouble() ?? 0.0;
                        return FlSpot(index, amount);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primaryOrange,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryOrange.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

