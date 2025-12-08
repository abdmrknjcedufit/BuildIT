import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/order_provider.dart';
import 'package:buildit_mobile/providers/review_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/models/order_model.dart';
import 'package:buildit_mobile/models/review_model.dart';
import 'package:buildit_mobile/screens/listing_detail_screen.dart';
import 'package:buildit_mobile/screens/user/user_detail_screen.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderProvider _orderProvider = OrderProvider();
  final ReviewProvider _reviewProvider = ReviewProvider();
  Order? _order;
  Review? _existingReview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final order = await _orderProvider.getById(widget.orderId);
      
      if (order.transactionId != null && AuthProvider.id != null) {
        try {
          final reviewResult = await _reviewProvider.get(
            filter: {
              'transactionId': order.transactionId,
              'reviewerId': AuthProvider.id,
            },
            page: 1,
            pageSize: 1,
          );
          
          if (reviewResult.result.isNotEmpty) {
            _existingReview = reviewResult.result.first;
          }
        } catch (e) {
          // Ignore review errors
        }
      }

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorLoadingOrderDetails}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showReviewDialog() async {
    if (_order?.transaction?.listing == null || AuthProvider.id == null) {
      return;
    }

    int selectedRating = 5;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppLocalizations.of(context).leaveRating,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).ratingLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedRating = rating;
                          });
                        },
                        child: Icon(
                          rating <= selectedRating ? Icons.star : Icons.star_border,
                          color: rating <= selectedRating ? Colors.amber : AppColors.darkGray,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).commentOptional,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).writeComment,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.lightGray,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context).cancel,
                style: TextStyle(
                  color: AppColors.darkGray,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                try {
                  final listing = _order!.transaction!.listing;
                  if (listing == null) {
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
                    'targetId': listing.id,
                    'rating': selectedRating,
                    'comment': commentController.text.isNotEmpty ? commentController.text : null,
                    'transactionId': _order!.transactionId,
                  });

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).reviewCreated),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await _loadOrderDetails();
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
              child: Text(
                AppLocalizations.of(context).send,
                style: TextStyle(fontSize: 16),
              ),
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).orderDetails),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : _order == null
              ?               Center(
                  child: Text(AppLocalizations.of(context).orderNotFound),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderInfo(),
                      const SizedBox(height: 16),
                      if (_order!.transaction != null) ...[
                        _buildListingInfo(),
                        const SizedBox(height: 16),
                        _buildSellerInfo(),
                        const SizedBox(height: 16),
                      ],
                      _buildReviewSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderInfo() {
    final dateFormat = DateFormat('dd. MM. yyyy. HH:mm');
    
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _order!.orderNumber,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order!.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(_order!.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(_order!.status),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Datum', dateFormat.format(_order!.createdAt)),
          _buildInfoRow('Status plaćanja', _order!.paymentStatus),
          _buildInfoRow('Način plaćanja', _order!.paymentMethod),
          if (_order!.deliveryType != null)
            _buildInfoRow('Dostava', _order!.deliveryType!),
          if (_order!.shippingAddress != null)
            _buildInfoRow('Adresa dostave', _order!.shippingAddress!),
          const Divider(height: 24),
          _buildInfoRow('Ukupno', '${_order!.totalAmount.toStringAsFixed(2)} KM'),
          if (_order!.taxAmount != null)
            _buildInfoRow('PDV', '${_order!.taxAmount!.toStringAsFixed(2)} KM'),
          if (_order!.discountAmount != null)
            _buildInfoRow('Popust', '-${_order!.discountAmount!.toStringAsFixed(2)} KM'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).totalToPay,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_order!.finalAmount.toStringAsFixed(2)} KM',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingInfo() {
    final listing = _order!.transaction!.listing;
    if (listing == null) return const SizedBox.shrink();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, color: AppColors.primaryOrange, size: 24),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).listing,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ListingDetailScreen(listingId: listing.id),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.item?.title ?? listing.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                if (listing.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    listing.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkGray,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${listing.item?.price ?? 0.0} KM',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.darkGray),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    final seller = _order!.transaction!.seller;
    if (seller == null) return const SizedBox.shrink();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppColors.primaryOrange, size: 24),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).seller,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserDetailScreen(userId: seller.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${seller.firstName[0]}${seller.lastName[0]}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${seller.firstName} ${seller.lastName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                        if (seller.email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            seller.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkGray,
                            ),
                          ),
                        ],
                        if (seller.phone != null && seller.phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            seller.phone!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.darkGray),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    if (_order!.transaction == null || _order!.transaction!.listing == null) {
      return const SizedBox.shrink();
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppColors.primaryOrange, size: 24),
              SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).rating,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_existingReview != null) ...[
            Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < _existingReview!.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${_existingReview!.rating}/5',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_existingReview!.comment != null && _existingReview!.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _existingReview!.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
            ],
          ] else ...[
            Text(
              AppLocalizations.of(context).leaveRatingForOrder,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showReviewDialog,
              icon: const Icon(Icons.star),
              label: Text(AppLocalizations.of(context).leaveRating),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlack,
            ),
          ),
        ],
      ),
    );
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
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Završeno';
      case 'delivered':
        return 'Isporučeno';
      case 'pending':
        return 'U toku';
      case 'processing':
        return 'U obradi';
      case 'cancelled':
        return 'Otkazano';
      default:
        return status;
    }
  }
}

