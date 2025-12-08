import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/providers/order_provider.dart';
import 'package:buildit_mobile/providers/review_provider.dart';
import 'package:buildit_mobile/providers/transaction_provider.dart';
import 'package:buildit_mobile/models/order_model.dart';
import 'package:buildit_mobile/models/review_model.dart';
import 'package:buildit_mobile/screens/user/order_detail_screen.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class UserOrderHistoryScreen extends StatefulWidget {
  const UserOrderHistoryScreen({super.key});

  @override
  State<UserOrderHistoryScreen> createState() => _UserOrderHistoryScreenState();
}

class _UserOrderHistoryScreenState extends State<UserOrderHistoryScreen> {
  final OrderProvider _orderProvider = OrderProvider();
  final ReviewProvider _reviewProvider = ReviewProvider();
  final TransactionProvider _transactionProvider = TransactionProvider();
  String? _selectedFilter;
  List<Order> _orders = [];
  bool _isLoading = true;
  Map<int, Review?> _orderReviews = {};
  Map<int, int> _orderListingIds = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _selectedFilter = AppLocalizations.of(context).allOrders;
      _initialized = true;
    }
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (AuthProvider.id == null) {
        throw Exception(AppLocalizations.of(context).userNotLoggedIn);
      }

      var result = await _orderProvider.get(
        page: 1,
        pageSize: 100,
        filter: {'userId': AuthProvider.id},
      );

      setState(() {
        _orders = result.result;
        _isLoading = false;
      });

      await _loadReviews();
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

  List<Order> get _filteredOrders {
    if (!_initialized) {
      return _orders;
    }
    final loc = AppLocalizations.of(context);
    if (_selectedFilter == null || _selectedFilter == loc.allOrders) {
      return _orders;
    } else if (_selectedFilter == loc.completed) {
      return _orders.where((o) => o.status == 'Completed' || o.status == 'Delivered').toList();
    } else if (_selectedFilter == loc.inProgress) {
      return _orders.where((o) => o.status == 'Pending' || o.status == 'Processing').toList();
    } else if (_selectedFilter == loc.cancelled) {
      return _orders.where((o) => o.status == 'Cancelled').toList();
    }
    return _orders;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'pending':
      case 'processing':
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
      case 'delivered':
        return loc.delivered;
      case 'pending':
        return loc.inProgress;
      case 'processing':
        return loc.processing;
      case 'cancelled':
        return loc.cancelled;
      default:
        return status;
    }
  }

  Future<void> _loadReviews() async {
    if (AuthProvider.id == null) return;

    try {
      final Map<int, Review?> reviews = {};
      final Map<int, int> listingIds = {};
      
      for (var order in _orders) {
        if (order.transactionId != null) {
          try {
            final transactionResult = await _transactionProvider.get(
              filter: {'id': order.transactionId},
              page: 1,
              pageSize: 1,
            );
            
            if (transactionResult.result.isNotEmpty) {
              final transaction = transactionResult.result.first;
              listingIds[order.id] = transaction.listingId;
              
              final reviewResult = await _reviewProvider.get(
                filter: {
                  'transactionId': order.transactionId,
                  'reviewerId': AuthProvider.id,
                },
                page: 1,
                pageSize: 1,
              );
              
              if (reviewResult.result.isNotEmpty) {
                reviews[order.id] = reviewResult.result.first;
              } else {
                reviews[order.id] = null;
              }
            } else {
              reviews[order.id] = null;
            }
          } catch (e) {
            reviews[order.id] = null;
          }
        } else {
          reviews[order.id] = null;
        }
      }

      setState(() {
        _orderReviews = reviews;
        _orderListingIds = listingIds;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _showReviewDialog(Order order) async {
    int selectedRating = 5;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).leaveReview),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).ratingLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return IconButton(
                      icon: Icon(
                        rating <= selectedRating ? Icons.star : Icons.star_border,
                        color: rating <= selectedRating ? Colors.amber : AppColors.darkGray,
                        size: 40,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          selectedRating = rating;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).commentOptional,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).writeComment,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final listingId = _orderListingIds[order.id];
                  if (listingId == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context).errorFindingListing),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  await _reviewProvider.insert({
                    'reviewerId': AuthProvider.id,
                    'targetType': 'Item',
                    'targetId': listingId,
                    'rating': selectedRating,
                    'comment': commentController.text.isNotEmpty ? commentController.text : null,
                    'transactionId': order.transactionId,
                  });

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).reviewCreated),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await _loadReviews();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${AppLocalizations.of(context).errorCreatingReview}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.white,
              ),
              child: Text(AppLocalizations.of(context).send),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: _buildOrderList(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFilters() {
    if (!_initialized) {
      return const SizedBox.shrink();
    }
    final loc = AppLocalizations.of(context);
    final filters = [loc.allOrders, loc.completed, loc.inProgress, loc.cancelled];
    
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
                  _loadOrders();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.primaryRed : AppColors.white,
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

  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
        ),
      );
    }

    if (_filteredOrders.isEmpty) {
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
              AppLocalizations.of(context).noOrders,
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
      onRefresh: _loadOrders,
      color: AppColors.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          final statusColor = _getStatusColor(order.status);
          final statusText = _getStatusText(order.status);
          final dateFormat = DateFormat('dd. MM. yyyy.');
          final formattedDate = dateFormat.format(order.createdAt);

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(orderId: order.id),
                ),
              );
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 12),
                      Text(
                        '${AppLocalizations.of(context).date}: $formattedDate',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGray,
                        ),
                      ),
                      if (order.deliveryType != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${AppLocalizations.of(context).delivery}: ${order.deliveryType}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ],
                      if (order.paymentStatus == 'Paid') ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context).paid,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (order.transactionId != null && 
                          (order.status == 'Completed' || order.status == 'Delivered') &&
                          order.paymentStatus == 'Paid') ...[
                        const SizedBox(height: 12),
                        _orderReviews[order.id] != null
                            ? Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${AppLocalizations.of(context).ratingLabel} ${_orderReviews[order.id]!.rating}/5',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.darkGray,
                                    ),
                                  ),
                                ],
                              )
                            : ElevatedButton.icon(
                                onPressed: () => _showReviewDialog(order),
                                icon: const Icon(Icons.rate_review, size: 18),
                                label: Text(AppLocalizations.of(context).leaveReview),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryOrange,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${order.finalAmount.toStringAsFixed(2)} KM',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
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

