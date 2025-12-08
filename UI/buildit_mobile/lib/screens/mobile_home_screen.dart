import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/listing_provider.dart';
import 'package:buildit_mobile/models/listing_model.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/providers/notification_provider.dart';
import 'package:buildit_mobile/models/notification_model.dart' as notification_model;
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/screens/user/user_settings_screen.dart';
import 'package:buildit_mobile/screens/user/user_products_screen.dart';
import 'package:buildit_mobile/screens/user/user_messages_screen.dart';
import 'package:buildit_mobile/screens/user/user_cart_screen.dart';
import 'package:buildit_mobile/screens/user/user_listings_screen.dart';
import 'package:buildit_mobile/screens/user/user_favorites_screen.dart';
import 'package:buildit_mobile/screens/user/user_notifications_screen.dart';
import 'package:buildit_mobile/screens/user/user_sales_screen.dart';
import 'package:buildit_mobile/screens/historija_screen.dart';
import 'package:buildit_mobile/screens/listing_detail_screen.dart';
import 'package:buildit_mobile/screens/search_screen.dart';
import 'package:buildit_mobile/screens/user_login_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  final ListingProvider _listingProvider = ListingProvider();
  final UserProvider _userProvider = UserProvider();
  final NotificationProvider _notificationProvider = NotificationProvider();
  List<Listing> _popularListings = [];
  List<Listing> _recommendedListings = [];
  List<notification_model.Notification> _notifications = [];
  int _unreadNotificationsCount = 0;
  bool _isLoading = true;
  bool _isLoadingNotifications = false;
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadPopularListings();
    _loadNotifications();
    if (AuthProvider.id != null) {
      _loadRecommendations();
    }
  }

  Future<void> _loadPopularListings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var result = await _listingProvider.get(
        page: 1,
        pageSize: 4,
        filter: {'IsFeatured': true},
      );

      setState(() {
        _popularListings = result.result;
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

  Future<void> _loadNotifications() async {
    if (AuthProvider.id == null) return;

    try {
      setState(() {
        _isLoadingNotifications = true;
      });

      var result = await _notificationProvider.get(
        page: 1,
        pageSize: 5,
        filter: {'UserId': AuthProvider.id, 'IsRead': false},
      );

      setState(() {
        _notifications = result.result;
        _unreadNotificationsCount = result.count;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    if (AuthProvider.id == null) return;

    try {
      setState(() {
        _isLoadingRecommendations = true;
      });

      var recommendations = await _listingProvider.getRecommendations(AuthProvider.id!, count: 6);
      
      print('🔵 Loaded ${recommendations.length} recommendations for user ${AuthProvider.id}');

      setState(() {
        _recommendedListings = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      print('❌ Error loading recommendations: $e');
      setState(() {
        _isLoadingRecommendations = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildNotificationsSection(),
              _buildHeroSection(),
              _buildNavigationCards(),
              if (AuthProvider.id != null && (_recommendedListings.isNotEmpty || _isLoadingRecommendations)) 
                _buildRecommendedListingsSection(),
              _buildPopularProductsSection(),
              _buildWhyBuildITSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.white,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 400;
              if (isWideScreen) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.shopping_bag,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart, color: AppColors.darkGray),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const UserCartScreen()),
                            );
                          },
                        ),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: AppColors.darkGray),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const UserNotificationsScreen()),
                                ).then((_) => _loadNotifications());
                              },
                            ),
                            if (_unreadNotificationsCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRed,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    _unreadNotificationsCount > 9 ? '9+' : '$_unreadNotificationsCount',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: AppColors.darkGray),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const UserMessagesScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_money, color: AppColors.darkGray),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const UserSalesScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: AppColors.darkGray),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const UserSettingsScreen()),
                            );
                          },
                        ),
                      ],
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
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.shopping_bag,
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.shopping_cart, color: AppColors.darkGray),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const UserCartScreen()),
                                  );
                                },
                              ),
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_outlined, color: AppColors.darkGray),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => const UserNotificationsScreen()),
                                      ).then((_) => _loadNotifications());
                                    },
                                  ),
                                  if (_unreadNotificationsCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryRed,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          _unreadNotificationsCount > 9 ? '9+' : '$_unreadNotificationsCount',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.darkGray),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const UserMessagesScreen()),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.attach_money, color: AppColors.darkGray),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const UserSalesScreen()),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings, color: AppColors.darkGray),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const UserSettingsScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showLogoutDialog(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Odjavi se',
                            style: TextStyle(
                              color: AppColors.primaryRed,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ],
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
                  await _userProvider.logout();
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

  Widget _buildNotificationsSection() {
    if (AuthProvider.id == null || _notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppColors.primaryOrange, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).notifications,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_unreadNotificationsCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _unreadNotificationsCount > 9 ? '9+' : '$_unreadNotificationsCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UserNotificationsScreen()),
                  ).then((_) => _loadNotifications());
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppLocalizations.of(context).viewAll,
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_notifications.take(3).map((notification) => _buildNotificationItem(notification))),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(notification_model.Notification notification) {
    IconData icon;
    Color iconColor;

    switch (notification.notificationType) {
      case 'Order':
        icon = Icons.shopping_bag;
        iconColor = Colors.green;
        break;
      case 'Review':
        icon = Icons.star;
        iconColor = AppColors.primaryOrange;
        break;
      case 'Message':
        icon = Icons.chat_bubble;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppColors.darkGray;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const UserNotificationsScreen()),
        ).then((_) => _loadNotifications());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.white : AppColors.primaryOrange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: notification.isRead ? AppColors.lightGray : AppColors.primaryOrange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
      decoration: const BoxDecoration(
        color: AppColors.white,
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).welcome,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).welcomeSubtitle,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildSearchBar(),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UserProductsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth > 400 ? 32 : 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag, color: AppColors.white, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        AppLocalizations.of(context).searchProducts,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildNavigationCards() {
    final cards = [
      {
        'icon': Icons.shopping_bag,
        'label': AppLocalizations.of(context).browseProducts,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserProductsScreen()),
          );
        },
      },
      {
        'icon': Icons.list_alt,
        'label': AppLocalizations.of(context).myListings,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserListingsScreen()),
          );
        },
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': AppLocalizations.of(context).messages,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserMessagesScreen()),
          );
        },
      },
      {
        'icon': Icons.favorite,
        'label': AppLocalizations.of(context).favorites,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserFavoritesScreen()),
          );
        },
      },
      {
        'icon': Icons.history,
        'label': AppLocalizations.of(context).history,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const HistorijaScreen()),
          );
        },
      },
      {
        'icon': Icons.settings,
        'label': AppLocalizations.of(context).settings,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserSettingsScreen()),
          );
        },
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cards.take(3).map((card) {
              return Expanded(
                child: GestureDetector(
                  onTap: card['onTap'] as VoidCallback,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(0),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          card['icon'] as IconData,
                          color: AppColors.primaryOrange,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            card['label'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlack,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: cards.skip(3).take(3).map((card) {
              return Expanded(
                child: GestureDetector(
                  onTap: card['onTap'] as VoidCallback,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(0),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          card['icon'] as IconData,
                          color: AppColors.primaryOrange,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            card['label'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlack,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyBuildITSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).whyBuildIT,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              _buildFeatureCard(
                icon: Icons.flash_on,
                title: AppLocalizations.of(context).fastAndEasy,
                description: AppLocalizations.of(context).fastAndEasyDesc,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                icon: Icons.trending_up,
                title: AppLocalizations.of(context).bestPrices,
                description: AppLocalizations.of(context).bestPricesDesc,
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                icon: Icons.star_outline,
                title: AppLocalizations.of(context).trustedSellers,
                description: AppLocalizations.of(context).trustedSellersDesc,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedListingsSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  AppLocalizations.of(context).recommendations,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                flex: 1,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const UserProductsScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppLocalizations.of(context).viewAll,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _isLoadingRecommendations
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                )
              : _recommendedListings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 48,
                              color: AppColors.primaryOrange.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Preporuke će se pojaviti nakon što napravite neke narudžbe',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.darkGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: _recommendedListings.take(2).map((listing) => Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ListingDetailScreen(listingId: listing.id),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryOrange, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryOrange.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        height: 180,
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
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          listing.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBlack,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        if (listing.item != null)
                                          Text(
                                            '${listing.item!.price.toStringAsFixed(2)} KM',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryRed,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildPopularProductsSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.05),
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.primaryOrange.withOpacity(0.3), width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  AppLocalizations.of(context).popularListings,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                flex: 1,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const UserProductsScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppLocalizations.of(context).viewAll,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                )
              : _popularListings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          AppLocalizations.of(context).noProductsAvailable,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: _popularListings.take(2).map((listing) => Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ListingDetailScreen(listingId: listing.id),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryOrange, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryOrange.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      height: 180,
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
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryOrange,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context).featured,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                          ),
                                        ),
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
                                        listing.title,
                                        style: const TextStyle(
                                          fontSize: 16,
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
                                                fontSize: 13,
                                                color: AppColors.darkGray,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${listing.item?.price.toStringAsFixed(2) ?? "10.00"}/dan',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
        ],
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
            return Container(
              color: AppColors.primaryOrange.withOpacity(0.1),
              child: const Icon(
                Icons.landscape,
                size: 60,
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
          return Container(
            color: AppColors.primaryOrange.withOpacity(0.1),
            child: const Icon(
              Icons.landscape,
              size: 60,
              color: AppColors.primaryOrange,
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: AppColors.primaryOrange.withOpacity(0.1),
        child: const Icon(
          Icons.landscape,
          size: 60,
          color: AppColors.primaryOrange,
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        },
        readOnly: true,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).searchListingsAndUsers,
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

