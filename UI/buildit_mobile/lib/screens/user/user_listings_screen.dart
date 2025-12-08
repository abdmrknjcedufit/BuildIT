import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/listing_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/models/listing_model.dart';
import 'package:buildit_mobile/screens/user/user_edit_listing_screen.dart';
import 'package:buildit_mobile/screens/user/user_add_listing_screen.dart';
import 'package:buildit_mobile/screens/listing_detail_screen.dart';
import 'package:buildit_mobile/screens/mobile_home_screen.dart';

class UserListingsScreen extends StatefulWidget {
  const UserListingsScreen({super.key});

  @override
  State<UserListingsScreen> createState() => _UserListingsScreenState();
}

class _UserListingsScreenState extends State<UserListingsScreen> {
  final ListingProvider _listingProvider = ListingProvider();
  List<Listing> _listings = [];
  bool _isLoading = true;

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

      var result = await _listingProvider.get(
        page: 1,
        pageSize: 1000,
        filter: {'userId': AuthProvider.id},
      );

      setState(() {
        _listings = result.result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju oglasa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteListing(int listingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: const Text('Da li ste sigurni da želite obrisati ovaj oglas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _listingProvider.delete(listingId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oglas je uspješno obrisan'),
              backgroundColor: Colors.green,
            ),
          );
          _loadListings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška pri brisanju oglasa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String? _getListingImage(Listing listing) {
    if (listing.item?.images != null && listing.item!.images!.isNotEmpty) {
      return listing.item!.images;
    }
    if (listing.images != null && listing.images!.isNotEmpty) {
      return listing.images;
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
          Icons.image,
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
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MobileHomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserAddListingScreen()),
          ).then((value) {
            if (value == true) {
              _loadListings();
            }
          });
        },
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Dodaj oglas',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  )
                : _listings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inbox,
                              size: 64,
                              color: AppColors.darkGray,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nemate oglasa',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.darkGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const UserAddListingScreen()),
                                ).then((value) {
                                  if (value == true) {
                                    _loadListings();
                                  }
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Dodaj prvi oglas'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                foregroundColor: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _listings.length,
                        itemBuilder: (context, index) {
                          final listing = _listings[index];
                          return _buildListingCard(listing);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    final imageString = _getListingImage(listing);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ListingDetailScreen(listingId: listing.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (imageString != null)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.lightGray,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageFromBase64(imageString),
                ),
              )
            else
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.lightGray,
                ),
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 40,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                      ),
                      if (listing.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Izdvojeni',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: listing.status == 'Active' ? Colors.green : AppColors.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          listing.status,
                          style: TextStyle(
                            fontSize: 12,
                            color: listing.status == 'Active' ? Colors.white : AppColors.darkGray,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          listing.listingType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primaryOrange),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserEditListingScreen(listing: listing),
                            ),
                          ).then((value) {
                            if (value == true) {
                              _loadListings();
                            }
                          });
                        },
                        tooltip: 'Uredi',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteListing(listing.id),
                        tooltip: 'Obriši',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

