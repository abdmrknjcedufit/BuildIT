import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/providers/transaction_provider.dart';
import 'package:buildit_mobile/models/transaction_model.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/screens/listing_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:buildit_mobile/providers/base_provider.dart';
import 'dart:convert' show base64Encode, utf8;

class UserSalesScreen extends StatefulWidget {
  const UserSalesScreen({super.key});

  @override
  State<UserSalesScreen> createState() => _UserSalesScreenState();
}

class _UserSalesScreenState extends State<UserSalesScreen> {
  final TransactionProvider _transactionProvider = TransactionProvider();
  List<Transaction> _transactions = [];
  Map<String, dynamic>? _profitStats;
  bool _isLoading = true;
  bool _isLoadingProfit = false;
  String? _selectedFilter;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadSales();
    _loadProfitStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _selectedFilter = AppLocalizations.of(context).all;
      _initialized = true;
    }
  }

  Future<void> _loadSales() async {
    if (AuthProvider.id == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      var result = await _transactionProvider.get(
        page: 1,
        pageSize: 1000,
        filter: {'sellerId': AuthProvider.id},
      );

      setState(() {
        _transactions = result.result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorLoadingOrders}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProfitStats() async {
    if (AuthProvider.id == null) return;

    try {
      setState(() {
        _isLoadingProfit = true;
      });

      var url = "${BaseProvider.baseUrl}User/${AuthProvider.id}/profit";
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

  List<Transaction> get _filteredTransactions {
    if (!_initialized) {
      return _transactions;
    }
    final loc = AppLocalizations.of(context);
    if (_selectedFilter == null || _selectedFilter == loc.all) {
      return _transactions;
    } else if (_selectedFilter == loc.completed) {
      return _transactions.where((t) => t.status == 'Completed').toList();
    } else if (_selectedFilter == loc.pending) {
      return _transactions.where((t) => t.status == 'Pending').toList();
    } else if (_selectedFilter == loc.cancelled) {
      return _transactions.where((t) => t.status == 'Cancelled').toList();
    }
    return _transactions;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.darkGray;
    }
  }

  String _getStatusText(String status) {
    final loc = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'completed':
        return loc.completed;
      case 'pending':
        return loc.pending;
      case 'cancelled':
        return loc.cancelled;
      default:
        return status;
    }
  }

  String? _getListingImage(Transaction transaction) {
    if (transaction.listing?.item?.images != null && transaction.listing!.item!.images!.isNotEmpty) {
      return transaction.listing!.item!.images;
    }
    if (transaction.listing?.images != null && transaction.listing!.images!.isNotEmpty) {
      return transaction.listing!.images;
    }
    return null;
  }

  Widget _buildImageFromBase64(String imagesString) {
    try {
      String firstImage = imagesString.split(',').first.trim();
      
      if (firstImage.startsWith('data:image') || firstImage.startsWith('http://') || firstImage.startsWith('https://')) {
        return Image.network(
          firstImage,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.image,
                size: 50,
                color: AppColors.primaryOrange,
              ),
            );
          },
        );
      }
      
      Uint8List imageBytes = base64Decode(firstImage);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image,
              size: 50,
              color: AppColors.primaryOrange,
            ),
          );
        },
      );
    } catch (e) {
      return const Center(
        child: Icon(
          Icons.broken_image,
          size: 50,
          color: AppColors.primaryOrange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).profitAndSales),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : Column(
              children: [
                if (_profitStats != null) _buildProfitSummary(),
                _buildFilters(),
                Expanded(
                  child: _buildTransactionsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildProfitSummary() {
    if (_isLoadingProfit || _profitStats == null) {
      return const SizedBox.shrink();
    }

    final totalProfit = (_profitStats!['totalProfit'] as num?)?.toDouble() ?? 0.0;
    final totalSales = _profitStats!['totalSales'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildFilters() {
    if (!_initialized) {
      return const SizedBox.shrink();
    }
    final loc = AppLocalizations.of(context);
    final filters = [loc.all, loc.completed, loc.pending, loc.cancelled];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter != null && _selectedFilter == filter;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.primaryOrange : AppColors.white,
                  foregroundColor: isSelected ? AppColors.white : AppColors.darkGray,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  filter,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: AppColors.darkGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Nemate prodanih artikala',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSales,
      color: AppColors.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _filteredTransactions[index];
          final statusColor = _getStatusColor(transaction.status);
          final statusText = _getStatusText(transaction.status);
          final dateFormat = DateFormat('dd. MM. yyyy.');
          final formattedDate = dateFormat.format(transaction.transactionDate);

          return GestureDetector(
            onTap: () {
              if (transaction.listing != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ListingDetailScreen(listingId: transaction.listingId),
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
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
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _getListingImage(transaction) != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImageFromBase64(_getListingImage(transaction)!),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppColors.darkGray,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.listing?.title ?? 'Nepoznat oglas',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlack,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Datum: $formattedDate',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkGray,
                          ),
                        ),
                        if (transaction.buyer != null)
                          Text(
                            'Kupac: ${transaction.buyer!.firstName} ${transaction.buyer!.lastName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${transaction.amount.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.darkGray,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

