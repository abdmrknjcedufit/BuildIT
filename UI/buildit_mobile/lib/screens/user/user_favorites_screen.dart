import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/screens/listing_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:convert' show base64Encode, utf8;

class UserFavoritesScreen extends StatefulWidget {
  const UserFavoritesScreen({super.key});

  @override
  State<UserFavoritesScreen> createState() => _UserFavoritesScreenState();
}

class _UserFavoritesScreenState extends State<UserFavoritesScreen> {
  List<dynamic> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var url = "${BaseProvider.baseUrl}Favorite?UserId=${AuthProvider.id}";
      var uri = Uri.parse(url);
      
      var headers = {
        "Content-Type": "application/json",
        "Authorization": "Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}",
      };

      var response = await http.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        var data = jsonDecode(response.body);
        setState(() {
          _favorites = data['resultList'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(int listingId) async {
    try {
      var url = "${BaseProvider.baseUrl}Favorite/listing/$listingId";
      var uri = Uri.parse(url);
      
      var headers = {
        "Content-Type": "application/json",
        "Authorization": "Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}",
      };

      var response = await http.delete(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _loadFavorites();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).removedFromFavorites),
              backgroundColor: Colors.green,
            ),
          );
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

  Widget _buildImageFromBase64(String imagesString) {
    try {
      if (imagesString.isEmpty) {
        return Container(
          width: double.infinity,
          height: 200,
          color: AppColors.lightGray,
          child: const Center(
            child: Icon(Icons.image, size: 50, color: AppColors.darkGray),
          ),
        );
      }

      String imageToDecode = imagesString;
      if (imagesString.contains(',')) {
        imageToDecode = imagesString.split(',').first.trim();
      }

      // Handle data URLs or HTTP URLs
      if (imageToDecode.startsWith('data:image') || 
          imageToDecode.startsWith('http://') || 
          imageToDecode.startsWith('https://')) {
        return Image.network(
          imageToDecode,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 200,
              color: AppColors.lightGray,
              child: const Center(
                child: Icon(Icons.image, size: 50, color: AppColors.darkGray),
              ),
            );
          },
        );
      }

      final imageData = base64Decode(imageToDecode);
      return Image.memory(
        imageData,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        height: 200,
        color: AppColors.lightGray,
        child: const Center(
          child: Icon(Icons.image, size: 50, color: AppColors.darkGray),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).favoriteListings),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: AppColors.darkGray.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).noFavoriteListings,
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final favorite = _favorites[index];
                      final listing = favorite['listing'] as Map<String, dynamic>?;
                      if (listing == null) return const SizedBox.shrink();

                      final listingId = listing['id'] as int?;
                      final title = listing['title'] as String? ?? 'Nema naslova';
                      
                      final item = listing['item'] as Map<String, dynamic>?;
                      final price = item?['price'] as num? ?? listing['price'] as num? ?? 0.0;
                      final listingType = listing['listingType'] as String? ?? '';
                      
                      String images = '';
                      if (item != null && item['images'] != null && item['images'].toString().isNotEmpty) {
                        images = item['images'].toString();
                      } else if (listing['images'] != null && listing['images'].toString().isNotEmpty) {
                        images = listing['images'].toString();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightGray, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            if (listingId != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ListingDetailScreen(listingId: listingId),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGray,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: images.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                            child: _buildImageFromBase64(images),
                                          )
                                        : Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryOrange.withOpacity(0.1),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(12),
                                                topRight: Radius.circular(12),
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.landscape,
                                                size: 60,
                                                color: AppColors.primaryOrange,
                                              ),
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Omiljeni',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            if (listingId != null) {
                                              _removeFavorite(listingId);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlack,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: AppColors.primaryOrange,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '4.8 (124)',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.darkGray,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          listingType == 'Iznajmljivanje' 
                                              ? '${price.toStringAsFixed(2)} KM/dan'
                                              : '${price.toStringAsFixed(2)} KM',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryRed,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: listingType == 'Kupoprodaja' 
                                                ? AppColors.primaryRed.withOpacity(0.1)
                                                : AppColors.primaryOrange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            listingType,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: listingType == 'Kupoprodaja' 
                                                  ? AppColors.primaryRed
                                                  : AppColors.primaryOrange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

