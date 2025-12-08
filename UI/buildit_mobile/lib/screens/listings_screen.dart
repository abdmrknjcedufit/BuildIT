import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/listing_provider.dart';
import 'package:buildit_mobile/models/listing_model.dart';
import 'package:buildit_mobile/screens/listing_detail_screen.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final ListingProvider _listingProvider = ListingProvider();
  List<Listing> _listings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedListingType;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print("🔵 Loading listings...");
      
      Map<String, dynamic> filter = {};
      if (_searchQuery.isNotEmpty) {
        filter['FTS'] = _searchQuery;
      }
      if (_selectedListingType != null && _selectedListingType!.isNotEmpty) {
        filter['listingType'] = _selectedListingType;
      }

      var result = await _listingProvider.get(
        filter: filter.isNotEmpty ? filter : null,
        page: 1,
        pageSize: 100,
      );

      print("✅ Loaded ${result.result.length} listings");
      print("✅ Total count: ${result.count}");
      
      if (result.result.isNotEmpty) {
        print("✅ First listing: ${result.result.first.title}");
        print("✅ First listing has item: ${result.result.first.item != null}");
        if (result.result.first.item != null) {
          print("✅ First listing item title: ${result.result.first.item!.title}");
        }
      }

      setState(() {
        _listings = result.result;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print("❌ Error loading listings: $e");
      print("❌ Stack trace: $stackTrace");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju oglasa: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Oglasi'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  )
                : _listings.isEmpty
                    ? const Center(
                        child: Text(
                          'Nema oglasa',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.darkGray,
                          ),
                        ),
                      )
                    : _buildListingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Pretraži oglase...',
          prefixIcon: Icon(Icons.search, color: AppColors.darkGray),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onSubmitted: (_) {
          _loadListings();
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const Icon(Icons.filter_list, color: AppColors.darkGray),
          const SizedBox(width: 12),
          const Text(
            'Tip oglasa:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedListingType,
              isExpanded: true,
              hint: const Text('Svi tipovi'),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Svi tipovi'),
                ),
                const DropdownMenuItem<String>(
                  value: 'Kupoprodaja',
                  child: Text('Kupoprodaja'),
                ),
                const DropdownMenuItem<String>(
                  value: 'Iznajmljivanje',
                  child: Text('Iznajmljivanje'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedListingType = value;
                });
                _loadListings();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _listings.length,
      itemBuilder: (context, index) {
        final listing = _listings[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ListingDetailScreen(listingId: listing.id),
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
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (listing.item?.images != null && listing.item!.images!.isNotEmpty)
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(listing.item!.images!.split(',').first),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image,
                              size: 40,
                              color: AppColors.primaryOrange,
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  Expanded(
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
                        const SizedBox(height: 4),
                        if (listing.item != null) ...[
                          Text(
                            listing.item!.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkGray,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (listing.item!.brand != null || listing.item!.model != null)
                            Text(
                              '${listing.item!.brand ?? ''} ${listing.item!.model ?? ''}'.trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGray,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ] else
                          Text(
                            listing.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkGray,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (listing.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '⭐',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (listing.item != null) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.item!.itemType,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkGray.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.item!.condition,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: listing.item!.isAvailable
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.item!.isAvailable ? 'Dostupno' : 'Nedostupno',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: listing.item!.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${listing.item!.price.toStringAsFixed(2)} KM',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    if (listing.item!.year != null)
                      Text(
                        'Godina: ${listing.item!.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGray,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.listingType,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: listing.status == 'Active'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: listing.status == 'Active' ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

