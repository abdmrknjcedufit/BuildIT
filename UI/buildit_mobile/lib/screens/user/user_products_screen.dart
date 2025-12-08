import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/listing_provider.dart';
import 'package:buildit_mobile/models/listing_model.dart';
import 'package:buildit_mobile/screens/mobile_home_screen.dart';
import 'package:buildit_mobile/screens/user/user_cart_screen.dart';
import 'package:buildit_mobile/screens/user/user_messages_screen.dart';
import 'package:buildit_mobile/screens/user/user_settings_screen.dart';
import 'package:buildit_mobile/screens/user/user_items_screen.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/providers/review_provider.dart';
import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/screens/listing_detail_screen.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/screens/user_login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show base64Encode, utf8, jsonDecode;

class UserProductsScreen extends StatefulWidget {
  const UserProductsScreen({super.key});

  @override
  State<UserProductsScreen> createState() => _UserProductsScreenState();
}

class _UserProductsScreenState extends State<UserProductsScreen> {
  final ListingProvider _listingProvider = ListingProvider();
  final ReviewProvider _reviewProvider = ReviewProvider();
  List<Listing> _listings = [];
  bool _isLoading = true;
  String? _selectedSort;
  String? _selectedSortValue;
  double _minPrice = 0;
  double _maxPrice = 500;
  bool _availableOnly = true;
  bool _comingSoon = false;
  String? _selectedRating;
  String? _selectedListingType;
  Map<int, double> _listingRatings = {};
  Map<int, bool> _listingFavorites = {};
  Map<int, bool> _checkingFavorites = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        setState(() {
          _selectedSortValue = loc.mostPopular;
          _selectedSort = loc.mostPopular;
        });
      }
    });
    _loadListings();
  }

  Future<void> _checkFavorite(int listingId) async {
    if (AuthProvider.id == null) {
      setState(() {
        _checkingFavorites[listingId] = false;
        _listingFavorites[listingId] = false;
      });
      return;
    }

    try {
      var url = "${BaseProvider.baseUrl}Favorite?UserId=${AuthProvider.id}&ListingId=$listingId";
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
          _listingFavorites[listingId] = favorites.isNotEmpty;
          _checkingFavorites[listingId] = false;
        });
      } else {
        setState(() {
          _listingFavorites[listingId] = false;
          _checkingFavorites[listingId] = false;
        });
      }
    } catch (e) {
      setState(() {
        _listingFavorites[listingId] = false;
        _checkingFavorites[listingId] = false;
      });
    }
  }

  Future<void> _toggleFavorite(int listingId) async {
    if (AuthProvider.id == null) return;

    try {
      if (_listingFavorites[listingId] == true) {
        var url = "${BaseProvider.baseUrl}Favorite/listing/$listingId";
        var uri = Uri.parse(url);
        
        var headers = {
          "Content-Type": "application/json",
          "Authorization": "Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}",
        };

        var response = await http.delete(uri, headers: headers);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          setState(() {
            _listingFavorites[listingId] = false;
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
          "listingId": listingId,
        });

        var response = await http.post(uri, headers: headers, body: body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          setState(() {
            _listingFavorites[listingId] = true;
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

  Future<void> _loadListings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Listing> filteredListings = [];
      Map<String, dynamic> filter = {};
      if (_selectedListingType != null && _selectedListingType!.isNotEmpty) {
        filter['listingType'] = _selectedListingType;
      }

      var result = await _listingProvider.get(
        filter: filter.isNotEmpty ? filter : null,
        page: 1,
        pageSize: 50,
      );

      filteredListings = result.result;

      await _loadRatings(filteredListings);

      filteredListings = _applyFilters(filteredListings);
      filteredListings = _applySorting(filteredListings);

      setState(() {
        _listings = filteredListings;
        _isLoading = false;
      });
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
      }
    }
  }

  Future<void> _loadRatings(List<Listing> listings) async {
    try {
      _listingRatings.clear();
      
      for (var listing in listings) {
        try {
          var reviewsResult = await _reviewProvider.get(
            filter: {
              'targetType': 'Item',
              'targetId': listing.id,
              'isApproved': true,
            },
            page: 1,
            pageSize: 1000,
          );

          if (reviewsResult.result.isNotEmpty) {
            final averageRating = reviewsResult.result
                .map((r) => r.rating)
                .reduce((a, b) => a + b) /
                reviewsResult.result.length;
            _listingRatings[listing.id] = averageRating;
          } else {
            _listingRatings[listing.id] = 0.0;
          }
        } catch (e) {
          _listingRatings[listing.id] = 0.0;
        }
      }
    } catch (e) {
    }
  }

  List<Listing> _applyFilters(List<Listing> listings) {
    var filtered = listings;

    filtered = filtered.where((listing) {
      final price = listing.item?.price ?? 0;
      if (price < _minPrice || price > _maxPrice) {
        return false;
      }

      if (_availableOnly && listing.status != 'Active') {
        return false;
      }

      if (_comingSoon && listing.status != 'ComingSoon') {
        return false;
      }

      if (_selectedRating != null) {
        final minRating = int.tryParse(_selectedRating!);
        if (minRating != null) {
          final listingRating = _listingRatings[listing.id] ?? 0.0;
          if (listingRating < minRating) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    return filtered;
  }

  List<Listing> _applySorting(List<Listing> listings) {
    var sorted = List<Listing>.from(listings);
    final loc = AppLocalizations.of(context);

    if (_selectedSort == loc.priceLowToHigh) {
      sorted.sort((a, b) => (a.item?.price ?? 0).compareTo(b.item?.price ?? 0));
    } else if (_selectedSort == loc.priceHighToLow) {
      sorted.sort((a, b) => (b.item?.price ?? 0).compareTo(a.item?.price ?? 0));
    } else if (_selectedSort == loc.newest) {
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      sorted.sort((a, b) => (b.item?.price ?? 0).compareTo(a.item?.price ?? 0));
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => UserItemsScreen()),
          );
        },
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.inventory_2, color: AppColors.white),
        label: Text(
          AppLocalizations.of(context).myItems,
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTitle(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: _buildProductGrid(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MobileHomeScreen()),
                  (route) => false,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'BuildIT',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const MobileHomeScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(AppLocalizations.of(context).home, style: const TextStyle(color: AppColors.primaryBlack, fontSize: 13)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).browseProducts,
                    style: TextStyle(color: AppColors.primaryBlack, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(AppLocalizations.of(context).howItWorks, style: const TextStyle(color: AppColors.primaryBlack, fontSize: 13)),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(AppLocalizations.of(context).aboutUs, style: const TextStyle(color: AppColors.primaryBlack, fontSize: 13)),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: AppColors.primaryBlack, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const UserCartScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlack, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const UserMessagesScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.primaryBlack, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const UserSettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      AppLocalizations.of(context).logout,
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).logoutConfirm),
          content: Text(AppLocalizations.of(context).logoutConfirmMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final userProvider = UserProvider();
                  await userProvider.logout();
                } catch (e) {
                  // Ignore logout errors, continue with local logout
                }
                AuthProvider.logout();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text(AppLocalizations.of(context).logout, style: const TextStyle(color: AppColors.primaryRed)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).constructionMaterials,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_listings.length} oglasa dostupno',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.lightGray,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildListingTypeSection(),
            const SizedBox(height: 16),
            _buildSortSection(),
            const SizedBox(height: 16),
            _buildPriceSection(),
            const SizedBox(height: 16),
            _buildAvailabilitySection(),
            const SizedBox(height: 16),
            _buildRatingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildListingTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).listingType,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        RadioListTile<String?>(
          title: Text(AppLocalizations.of(context).allTypes, style: TextStyle(fontSize: 13)),
          value: null,
          groupValue: _selectedListingType,
          onChanged: (value) {
            setState(() {
              _selectedListingType = value;
              _loadListings();
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<String?>(
          title: Text(AppLocalizations.of(context).buySell, style: TextStyle(fontSize: 13)),
          value: 'Kupoprodaja',
          groupValue: _selectedListingType,
          onChanged: (value) {
            setState(() {
              _selectedListingType = value;
              _loadListings();
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<String?>(
          title: Text(AppLocalizations.of(context).rental, style: TextStyle(fontSize: 13)),
          value: 'Iznajmljivanje',
          groupValue: _selectedListingType,
          onChanged: (value) {
            setState(() {
              _selectedListingType = value;
              _loadListings();
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildSortSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).sorting,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final loc = AppLocalizations.of(context);
            final currentValue = _selectedSortValue ?? loc.mostPopular;
            
            return Column(
              children: [
                RadioListTile<String>(
                  title: Text(loc.mostPopular, style: TextStyle(fontSize: 13)),
                  value: loc.mostPopular,
                  groupValue: currentValue,
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                      _selectedSortValue = value!;
                      _loadListings();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(loc.priceLowToHigh, style: TextStyle(fontSize: 13)),
                  value: loc.priceLowToHigh,
                  groupValue: currentValue,
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                      _selectedSortValue = value!;
                      _loadListings();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(loc.priceHighToLow, style: TextStyle(fontSize: 13)),
                  value: loc.priceHighToLow,
                  groupValue: currentValue,
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                      _selectedSortValue = value!;
                      _loadListings();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: Text(loc.newest, style: TextStyle(fontSize: 13)),
                  value: loc.newest,
                  groupValue: currentValue,
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                      _selectedSortValue = value!;
                      _loadListings();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).pricePerDay,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).minPrice,
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _minPrice = double.tryParse(value) ?? 0;
                    _loadListings();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).maxPrice,
                  labelStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _maxPrice = double.tryParse(value) ?? 500;
                    _loadListings();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).availabilityFilter,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: Text(AppLocalizations.of(context).available, style: TextStyle(fontSize: 13)),
          value: _availableOnly,
          onChanged: (value) {
            setState(() {
              _availableOnly = value ?? true;
              _loadListings();
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        CheckboxListTile(
          title: Text(AppLocalizations.of(context).comingSoon, style: TextStyle(fontSize: 13)),
          value: _comingSoon,
          onChanged: (value) {
            setState(() {
              _comingSoon = value ?? false;
              _loadListings();
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    final ratingOptions = [
      {'value': null, 'label': AppLocalizations.of(context).allRatings},
      {'value': '5', 'label': '5 zvjezdica'},
      {'value': '4', 'label': '4+ zvjezdice'},
      {'value': '3', 'label': '3+ zvjezdice'},
      {'value': '2', 'label': '2+ zvjezdice'},
      {'value': '1', 'label': '1+ zvjezdica'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).ratingFilter,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: _selectedRating,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).selectRating,
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12),
          items: ratingOptions.map((option) {
            return DropdownMenuItem<String?>(
              value: option['value'] as String?,
              child: Text(option['label'] as String),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRating = value;
            });
            _loadListings();
          },
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
        ),
      );
    }

    if (_listings.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noListingsAvailable,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.darkGray,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 1200) {
          crossAxisCount = 2;
        }
        if (constraints.maxWidth < 800) {
          crossAxisCount = 1;
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: _listings.length,
          itemBuilder: (context, index) {
            final listing = _listings[index];
            return _buildProductCard(listing);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Listing listing) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ListingDetailScreen(listingId: listing.id),
          ),
        );
      },
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: _getListingImage(listing) != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: _buildImageFromBase64(_getListingImage(listing)!),
                          )
                        : Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: (_checkingFavorites[listing.id] == true)
                        ? const SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              _listingFavorites[listing.id] == true 
                                  ? Icons.favorite 
                                  : Icons.favorite_border,
                              color: AppColors.primaryRed,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => _toggleFavorite(listing.id),
                          ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.item?.itemType ?? AppLocalizations.of(context).nA,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.primaryRed,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '4.9 (203)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.darkGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${listing.item?.price.toStringAsFixed(0) ?? "0"}€ po danu',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ListingDetailScreen(listingId: listing.id),
                            ),
                          );
                        },
                        icon: Icon(
                          listing.listingType == 'Kupoprodaja' ? Icons.shopping_cart : Icons.flash_on,
                          size: 12,
                        ),
                        label: Text(
                          listing.listingType == AppLocalizations.of(context).buySell ? AppLocalizations.of(context).buy : AppLocalizations.of(context).rent,
                          style: const TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getListingImage(Listing listing) {
    if (listing.item?.images != null && listing.item!.images!.isNotEmpty) {
      return listing.item!.images;
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
}

