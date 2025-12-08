import 'dart:convert';
import 'dart:typed_data';
import 'dart:convert' show base64Encode, utf8;
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/models/listing_model.dart';
import 'package:buildit_mobile/providers/listing_provider.dart';
import 'package:buildit_mobile/providers/cart_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/screens/user/user_detail_screen.dart';
import 'package:buildit_mobile/screens/user/user_cart_screen.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class ListingDetailScreen extends StatefulWidget {
  final int listingId;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final ListingProvider _listingProvider = ListingProvider();
  final CartProvider _cartProvider = CartProvider();
  Listing? _listing;
  bool _isLoading = true;
  int _selectedImageIndex = 0;
  int _rentalDays = 1;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  List<String> _occupiedDates = [];
  bool _isLoadingCalendar = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadListing();
    _checkFavorite();
  }

  Future<void> _loadRentalAvailability() async {
    if (_listing == null || _listing!.listingType != 'Iznajmljivanje') {
      return;
    }

    setState(() {
      _isLoadingCalendar = true;
    });

    try {
      var dates = await _listingProvider.getRentalAvailability(widget.listingId);
      setState(() {
        _occupiedDates = dates;
        _isLoadingCalendar = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCalendar = false;
      });
    }
  }

  Future<void> _checkFavorite() async {
    if (AuthProvider.id == null) {
      setState(() {
        _isCheckingFavorite = false;
      });
      return;
    }

    try {
      var url = "${BaseProvider.baseUrl}Favorite?UserId=${AuthProvider.id}&ListingId=${widget.listingId}";
      var uri = Uri.parse(url);
      
      var headers = {
        "Content-Type": "application/json",
        "Authorization": "Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}",
      };

      var response = await http.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        var data = jsonDecode(response.body);
        var favorites = data['resultList'] as List<dynamic>? ?? [];
        setState(() {
          _isFavorite = favorites.isNotEmpty;
          _isCheckingFavorite = false;
        });
      } else {
        setState(() {
          _isCheckingFavorite = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (AuthProvider.id == null) return;

    try {
      if (_isFavorite) {
        var url = "${BaseProvider.baseUrl}Favorite/listing/${widget.listingId}";
        var uri = Uri.parse(url);
        
        var headers = {
          "Content-Type": "application/json",
          "Authorization": "Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}",
        };

        var response = await http.delete(uri, headers: headers);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          setState(() {
            _isFavorite = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).removedFromFavorites),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        var url = "${BaseProvider.baseUrl}Favorite";
        var uri = Uri.parse(url);
        
        var headers = {
          "Content-Type": "application/json",
          "Authorization": "Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}",
        };

        var body = jsonEncode({
          "listingId": widget.listingId,
        });

        var response = await http.post(uri, headers: headers, body: body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          setState(() {
            _isFavorite = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).addedToFavorites),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadListing() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var listing = await _listingProvider.getById(widget.listingId);

      setState(() {
        _listing = listing;
        _isLoading = false;
        if (listing.minRentalDays != null) {
          _rentalDays = listing.minRentalDays!;
        }
      });

      if (listing.listingType == 'Iznajmljivanje') {
        _loadRentalAvailability();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorLoadingListing}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  List<String> _getImages() {
    if (_listing?.item?.images != null && _listing!.item!.images!.isNotEmpty) {
      return _listing!.item!.images!.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  Widget _buildImageFromBase64(String imageString) {
    try {
      if (imageString.startsWith('data:image') || 
          imageString.startsWith('http://') || 
          imageString.startsWith('https://')) {
        return Image.network(
          imageString,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.lightGray,
              child: const Icon(Icons.image, size: 50, color: AppColors.darkGray),
            );
          },
        );
      }

      Uint8List imageBytes = base64Decode(imageString);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.lightGray,
            child: const Icon(Icons.image, size: 50, color: AppColors.darkGray),
          );
        },
      );
    } catch (e) {
      return Container(
        color: AppColors.lightGray,
        child: const Icon(Icons.image, size: 50, color: AppColors.darkGray),
      );
    }
  }

  Future<void> _addToCart() async {
    if (_listing == null || AuthProvider.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).mustBeLoggedIn),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _cartProvider.insert({
        'userId': AuthProvider.id,
        'listingId': _listing!.id,
        'quantity': 1,
        'rentalDays': _listing!.listingType == 'Iznajmljivanje' ? _rentalDays : null,
      });

      if (mounted) {
        final shouldOpenCart = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).addedToCart),
            content: Text(AppLocalizations.of(context).doYouWantToOpenCart),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryOrange,
                ),
                child: Text(AppLocalizations.of(context).yes),
              ),
            ],
          ),
        );

        if (shouldOpenCart == true && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserCartScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorAddingToCart}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).details),
        backgroundColor: AppColors.primaryOrange,
        actions: [
          if (AuthProvider.id != null)
            _isCheckingFavorite
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : _listing == null
              ? Center(
                  child: Text(AppLocalizations.of(context).listingNotFound),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 16),
                            _buildPriceSection(),
                            const SizedBox(height: 16),
                            _buildDetailsSection(),
                            const SizedBox(height: 16),
                            _buildUserSection(),
                            const SizedBox(height: 16),
                            _buildLocationSection(),
                            const SizedBox(height: 16),
                            _buildDatesSection(),
                            const SizedBox(height: 24),
                            if (_listing!.listingType == 'Iznajmljivanje') _buildRentalDaysSection(),
                            if (_listing!.listingType == 'Iznajmljivanje') const SizedBox(height: 24),
                            if (_listing!.listingType == 'Iznajmljivanje') _buildRentalCalendar(),
                            if (_listing!.listingType == 'Iznajmljivanje') const SizedBox(height: 24),
                            _buildAddToCartButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildImageSection() {
    final images = _getImages();
    
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        color: AppColors.lightGray,
        child: const Icon(
          Icons.image,
          size: 80,
          color: AppColors.darkGray,
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 400,
          color: AppColors.lightGray,
          child: _buildImageFromBase64(images[_selectedImageIndex]),
        ),
        if (images.length > 1)
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedImageIndex == index
                            ? AppColors.primaryOrange
                            : AppColors.lightGray,
                        width: _selectedImageIndex == index ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageFromBase64(images[index]),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _listing!.item?.title ?? _listing!.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
            ),
            if (_listing!.isFeatured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context).featured,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _listing!.listingType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _listing!.status == 'Active'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _listing!.status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _listing!.status == 'Active' ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        if (_listing!.item != null && _listing!.item!.brand != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_listing!.item!.brand} ${_listing!.item!.model ?? ''}'.trim(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.darkGray,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final price = _listing!.item?.price ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).price,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGray,
                ),
              ),
              Text(
                '${price.toStringAsFixed(2)} KM',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
              if (_listing!.listingType == 'Iznajmljivanje')
                Text(
                  AppLocalizations.of(context).perDay,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.darkGray.withOpacity(0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).description,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _listing!.description,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.primaryBlack,
            height: 1.5,
          ),
        ),
        if (_listing!.item != null) ...[
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).itemDetails,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(AppLocalizations.of(context).itemType, _listing!.item!.itemType),
          if (_listing!.item!.condition.isNotEmpty)
            _buildDetailRow(AppLocalizations.of(context).condition, _listing!.item!.condition),
          if (_listing!.item!.year != null)
            _buildDetailRow(AppLocalizations.of(context).year, _listing!.item!.year.toString()),
          _buildDetailRow(
            AppLocalizations.of(context).availability,
            _listing!.item!.isAvailable ? AppLocalizations.of(context).available : AppLocalizations.of(context).unavailable,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSection() {
    if (_listing!.user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, color: AppColors.darkGray, size: 24),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context).userInfoNotAvailable,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
      );
    }

    final user = _listing!.user!;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(userId: user.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3), width: 2),
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
                const Icon(
                  Icons.person_outline,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).seller,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.darkGray,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${user.firstName[0]}${user.lastName[0]}',
                      style: const TextStyle(
                        fontSize: 24,
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
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (user.email.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16, color: AppColors.darkGray),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.darkGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: AppColors.darkGray),
                            const SizedBox(width: 4),
                            Text(
                              user.phone!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    if (_listing!.city == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.primaryOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).location,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkGray,
                  ),
                ),
                Text(
                  _listing!.city!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection() {
    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRow(AppLocalizations.of(context).published, formatDate(_listing!.createdAt)),
          if (_listing!.updatedAt != null)
            _buildDateRow(AppLocalizations.of(context).updated, formatDate(_listing!.updatedAt!)),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildRentalDaysSection() {
    if (_listing!.minRentalDays == null && _listing!.maxRentalDays == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).rentalDays,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 12),
          if (_listing!.minRentalDays != null && _listing!.maxRentalDays != null)
            Text(
              '${AppLocalizations.of(context).minDays}: ${_listing!.minRentalDays} ${AppLocalizations.of(context).days}, ${AppLocalizations.of(context).maxDays}: ${_listing!.maxRentalDays} ${AppLocalizations.of(context).days}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkGray,
              ),
            )
          else if (_listing!.minRentalDays != null)
            Text(
              '${AppLocalizations.of(context).minDays}: ${_listing!.minRentalDays} ${AppLocalizations.of(context).days}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkGray,
              ),
            )
          else if (_listing!.maxRentalDays != null)
            Text(
                  '${AppLocalizations.of(context).maxDays}: ${_listing!.maxRentalDays} ${AppLocalizations.of(context).days}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkGray,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (_listing!.minRentalDays != null && _rentalDays > _listing!.minRentalDays!) {
                    setState(() {
                      _rentalDays--;
                    });
                  }
                },
              ),
              Text(
                '$_rentalDays ${AppLocalizations.of(context).days}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  if (_listing!.maxRentalDays != null && _rentalDays < _listing!.maxRentalDays!) {
                    setState(() {
                      _rentalDays++;
                    });
                  } else if (_listing!.maxRentalDays == null) {
                    setState(() {
                      _rentalDays++;
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3), width: 1),
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
              const Icon(
                Icons.calendar_today,
                color: AppColors.primaryOrange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).availabilityForReservation,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingCalendar)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return day.year == _selectedDay.year &&
                       day.month == _selectedDay.month &&
                       day.day == _selectedDay.day;
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primaryOrange),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primaryOrange),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: const TextStyle(color: AppColors.darkGray),
                weekendStyle: const TextStyle(color: AppColors.darkGray),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, _) {
                  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  final isOccupied = _occupiedDates.contains(dateStr);
                  final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                  
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isPast
                          ? AppColors.lightGray
                          : isOccupied
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isOccupied ? Colors.red : Colors.green,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isPast
                              ? AppColors.darkGray
                              : isOccupied
                                  ? Colors.red.shade900
                                  : Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                todayBuilder: (context, date, _) {
                  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  final isOccupied = _occupiedDates.contains(dateStr);
                  
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? Colors.red.withOpacity(0.5)
                          : Colors.green.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryOrange,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isOccupied ? Colors.red.shade900 : Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  // Ako je izabran datum, resetuj rentalDays na 1 ili minRentalDays ako postoji
                  if (_listing != null && _listing!.listingType == 'Iznajmljivanje') {
                    if (_listing!.minRentalDays != null && _listing!.minRentalDays! > 0) {
                      _rentalDays = _listing!.minRentalDays!;
                    } else {
                      _rentalDays = 1;
                    }
                  }
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  border: Border.all(color: Colors.green, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).freeSlot,
                style: TextStyle(fontSize: 14, color: AppColors.primaryBlack),
              ),
              const SizedBox(width: 24),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  border: Border.all(color: Colors.red, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).occupied,
                style: TextStyle(fontSize: 14, color: AppColors.primaryBlack),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton() {
    if (AuthProvider.id == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.shopping_cart, size: 20),
                label: Text(
                  AppLocalizations.of(context).addToCart,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCheckingFavorite ? null : _toggleFavorite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isCheckingFavorite
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                      ),
                label: Text(
                  _isFavorite ? 'Ukloni iz omiljenih' : AppLocalizations.of(context).addToFavorites,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

