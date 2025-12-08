import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/screens/mobile_home_screen.dart';
import 'package:buildit_mobile/screens/user/user_products_screen.dart';
import 'package:buildit_mobile/screens/user/user_messages_screen.dart';
import 'package:buildit_mobile/screens/user/user_settings_screen.dart';
import 'package:buildit_mobile/providers/cart_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/providers/payment_provider.dart';
import 'package:buildit_mobile/models/cart_model.dart';
import 'package:buildit_mobile/widgets/stripe_payment_popup.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/screens/user_login_screen.dart';

class UserCartScreen extends StatefulWidget {
  const UserCartScreen({super.key});

  @override
  State<UserCartScreen> createState() => _UserCartScreenState();
}

class _UserCartScreenState extends State<UserCartScreen> {
  final CartProvider _cartProvider = CartProvider();
  final UserProvider _userProvider = UserProvider();
  final PaymentProvider _paymentProvider = PaymentProvider();
  List<Cart> _cartItems = [];
  bool _isLoading = true;
  int _currentStep = 0;
  int? _selectedDeliveryProviderId;
  String? _selectedDeliveryType;
  String _shippingAddress = '';

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (AuthProvider.id == null) {
        throw Exception(AppLocalizations.of(context).userNotLoggedIn);
      }

      var result = await _cartProvider.get(
        page: 1,
        pageSize: 1000,
        filter: {'userId': AuthProvider.id},
      );

      setState(() {
        _cartItems = result.result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorLoadingCart}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double get _subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get _tax => _subtotal * 0.10;
  double get _deliveryCost {
    if (_selectedDeliveryType == 'BH Pošta') {
      return 5.00;
    } else if (_selectedDeliveryType == 'X Express') {
      return 7.00;
    } else if (_selectedDeliveryType == 'EuroExpress') {
      return 8.00;
    }
    return 0.0;
  }
  double get _total => _subtotal + _tax + _deliveryCost;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    )
                  : _cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: AppColors.darkGray,
                              ),
                              const SizedBox(height: 16),
                                Text(
                                AppLocalizations.of(context).cartEmpty,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.darkGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) => const UserProductsScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryOrange,
                                  foregroundColor: AppColors.white,
                                ),
                                child: Text(AppLocalizations.of(context).browseListings),
                              ),
                            ],
                          ),
                        )
                      : _buildCurrentStep(),
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
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const MobileHomeScreen()),
                        (route) => false,
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
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const UserProductsScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(AppLocalizations.of(context).browseProducts, style: const TextStyle(color: AppColors.primaryBlack, fontSize: 13)),
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
                    icon: const Icon(Icons.shopping_cart, color: AppColors.primaryRed, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {},
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

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCartReview(),
                    _buildOrderSummary(),
                  ],
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildCartReview(),
                ),
                Expanded(
                  flex: 1,
                  child: _buildOrderSummary(),
                ),
              ],
            );
          },
        );
      case 1:
        return _buildDeliveryStep();
      case 2:
        return _buildPaymentStep();
      default:
        return _buildCartReview();
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStep(1, AppLocalizations.of(context).cart, _currentStep == 0),
                    const SizedBox(width: 8),
                    _buildStep(2, AppLocalizations.of(context).delivery, _currentStep == 1),
                    const SizedBox(width: 8),
                    _buildStep(3, AppLocalizations.of(context).paymentMethod, _currentStep == 2),
                  ],
                ),
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStep(1, AppLocalizations.of(context).cart, _currentStep == 0),
              Flexible(child: _buildStepLine()),
              _buildStep(2, AppLocalizations.of(context).delivery, _currentStep == 1),
              Flexible(child: _buildStepLine()),
              _buildStep(3, AppLocalizations.of(context).paymentMethod, _currentStep == 2),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep(int stepNumber, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primaryRed : AppColors.darkGray,
              width: 2,
            ),
            color: isActive ? AppColors.primaryRed : AppColors.white,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                color: isActive ? AppColors.white : AppColors.darkGray,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryRed : AppColors.darkGray,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      color: AppColors.lightGray,
    );
  }

  Widget _buildCartReview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVertical = constraints.maxWidth < 1000;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: isVertical ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Text(
                AppLocalizations.of(context).cartReview,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 24),
              if (isVertical)
                ..._cartItems.map((item) => _buildCartItem(item))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cartItems.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _currentStep = 1;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).continueToDelivery,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItem(Cart item) {
    final listing = item.listing;
    final listingTitle = listing?.title ?? AppLocalizations.of(context).nA;
    final itemPrice = listing?.item?.price ?? 0.0;
    final imageString = listing?.item?.images;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.darkGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageString != null && imageString.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageFromBase64(imageString),
                  )
                : const Icon(Icons.image, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listingTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (item.rentalDays != null)
                  Text(
                    '${item.rentalDays} dana iznajmljivanja',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkGray,
                    ),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context).quantity,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkGray,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: AppColors.primaryRed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: item.quantity > 1
                          ? () async {
                              try {
                                await _cartProvider.update(item.id, {
                                  'quantity': item.quantity - 1,
                                  'rentalDays': item.rentalDays,
                                });
                                _loadCartItems();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${AppLocalizations.of(context).errorUpdatingCart}: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      color: AppColors.primaryRed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () async {
                        try {
                          await _cartProvider.update(item.id, {
                            'quantity': item.quantity + 1,
                            'rentalDays': item.rentalDays,
                          });
                          _loadCartItems();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${AppLocalizations.of(context).errorUpdatingCart}: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.totalPrice.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context).removeFromCart),
                  content: Text(AppLocalizations.of(context).removeFromCartConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(AppLocalizations.of(context).delete),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await _cartProvider.delete(item.id);
                  _loadCartItems();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                        content: Text(AppLocalizations.of(context).itemRemovedFromCart),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${AppLocalizations.of(context).errorDeletingFromCart}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String imagesString) {
    try {
      String firstImage = imagesString.split(',').first.trim();

      if (firstImage.startsWith('data:image') || firstImage.startsWith('http://') || firstImage.startsWith('https://')) {
        return Image.network(
          firstImage,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.image,
                size: 30,
                color: AppColors.white,
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
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.image,
              size: 30,
              color: AppColors.white,
            ),
          );
        },
      );
    } catch (e) {
      return const Center(
        child: Icon(
          Icons.image,
          size: 30,
          color: AppColors.white,
        ),
      );
    }
  }

  Widget _buildOrderSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVertical = constraints.maxWidth < 1000;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            border: isVertical
                ? const Border(
                    top: BorderSide(color: AppColors.lightGray, width: 1),
                  )
                : const Border(
                    left: BorderSide(color: AppColors.lightGray, width: 1),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).orderSummary,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 24),
              ..._cartItems.map((item) {
                final listingTitle = item.listing?.title ?? AppLocalizations.of(context).nA;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Text(
                          '$listingTitle x${item.quantity}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryBlack,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Text(
                          '${item.totalPrice.toStringAsFixed(2)} KM',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryBlack,
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${AppLocalizations.of(context).service}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${_subtotal.toStringAsFixed(2)} KM',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryBlack,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${AppLocalizations.of(context).tax} (10%):',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${_tax.toStringAsFixed(2)} KM',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryBlack,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (_currentStep >= 1 && _deliveryCost > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${AppLocalizations.of(context).delivery}${_selectedDeliveryType != null ? ' (${_selectedDeliveryType})' : ''}:',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${_deliveryCost.toStringAsFixed(2)} KM',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryBlack,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${AppLocalizations.of(context).total}:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${_total.toStringAsFixed(2)} KM',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeliverySelection(),
                _buildOrderSummary(),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildDeliverySelection(),
            ),
            Expanded(
              flex: 1,
              child: _buildOrderSummary(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeliverySelection() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            AppLocalizations.of(context).selectDeliveryMethod,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 16),
          RadioListTile<String?>(
            title: Text(AppLocalizations.of(context).personalPickup),
            subtitle: Text(AppLocalizations.of(context).free),
            value: AppLocalizations.of(context).personalPickup,
            groupValue: _selectedDeliveryType,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryType = value;
                _selectedDeliveryProviderId = null;
              });
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          ),
          RadioListTile<String?>(
            title: const Text('BH Pošta'),
            subtitle: const Text('5.00 KM'),
            value: 'BH Pošta',
            groupValue: _selectedDeliveryType,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryType = value;
                _selectedDeliveryProviderId = 1;
              });
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          ),
          RadioListTile<String?>(
            title: const Text('X Express'),
            subtitle: const Text('7.00 KM'),
            value: 'X Express',
            groupValue: _selectedDeliveryType,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryType = value;
                _selectedDeliveryProviderId = 2;
              });
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          ),
          RadioListTile<String?>(
            title: const Text('EuroExpress'),
            subtitle: const Text('8.00 KM'),
            value: 'EuroExpress',
            groupValue: _selectedDeliveryType,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryType = value;
                _selectedDeliveryProviderId = 3;
              });
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          ),
          if (_selectedDeliveryType != null && _selectedDeliveryType != AppLocalizations.of(context).personalPickup) ...[
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).shippingAddress,
                border: OutlineInputBorder(),
                hintText: AppLocalizations.of(context).shippingAddress,
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _shippingAddress = value;
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Nazad'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedDeliveryType == null
                      ? null
                      : (_selectedDeliveryType != AppLocalizations.of(context).personalPickup && _shippingAddress.isEmpty)
                          ? null
                          : () {
                              setState(() {
                                _currentStep = 2;
                              });
                            },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).continueToPayment,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaymentSelection(),
                _buildOrderSummary(),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildPaymentSelection(),
            ),
            Expanded(
              flex: 1,
              child: _buildOrderSummary(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).selectPaymentMethod,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryOrange, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: AppColors.primaryOrange, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stripe',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).secureCardPayment,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 1;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Nazad'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _processPayment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).completeOrder,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    try {
      print('🔵 FLUTTER: _processPayment počinje');
      
      if (AuthProvider.id == null) {
        print('❌ FLUTTER: Korisnik nije prijavljen');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text(AppLocalizations.of(context).mustBeLoggedInToComplete),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_cartItems.isEmpty) {
        print('❌ FLUTTER: Korpa je prazna');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text(AppLocalizations.of(context).cartIsEmpty),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final totalWithDelivery = _total;
      final cartIds = _cartItems.map((cart) => cart.id).toList();
      
      print('🔵 FLUTTER: Kreiranje checkout sesije - userId=${AuthProvider.id}, amount=$totalWithDelivery, cartIds=$cartIds');

      final checkoutResponse = await _paymentProvider.createCheckoutSession(
        amount: totalWithDelivery,
        userId: AuthProvider.id!,
        cartIds: cartIds,
        deliveryProviderId: _selectedDeliveryProviderId,
        deliveryType: _selectedDeliveryType,
        shippingAddress: _shippingAddress.isNotEmpty ? _shippingAddress : null,
        description: '${AppLocalizations.of(context).orders} BuildIT',
        successUrl: 'buildit://payment-success',
        cancelUrl: 'buildit://payment-cancel',
      );

      print('✅ FLUTTER: Checkout sesija kreirana - sessionId=${checkoutResponse['sessionId']}, url=${checkoutResponse['url']}');

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (checkoutResponse['url'] != null && checkoutResponse['sessionId'] != null) {
        final urlString = checkoutResponse['url'] as String;
        final sessionId = checkoutResponse['sessionId'] as String;
        
        print('🔵 FLUTTER: Otvaranje Stripe checkout popup-a: $urlString');
        
        // Prikaži WebView popup umesto otvaranja browsera
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => StripePaymentPopup(
              checkoutUrl: urlString,
              sessionId: sessionId,
              onSuccess: (String sessionId) async {
                print('✅ FLUTTER: Payment success callback pozvan za sessionId=$sessionId');
                
                // Verifikuj plaćanje
                try {
                  final verifyResponse = await _paymentProvider.verifyPayment(sessionId);
                  
                  if (verifyResponse is Map<String, dynamic>) {
                    final success = verifyResponse['success'];
                    
                    if (success == true || success == 'true') {
                      final orderNumber = verifyResponse['orderNumber'] ?? 'N/A';
                      print('✅ FLUTTER: Plaćanje verifikovano! OrderNumber=$orderNumber');
                      
                      if (mounted) {
                        await _loadCartItems();
                        
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const UserProductsScreen()),
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${AppLocalizations.of(context).paymentSuccessful} ${AppLocalizations.of(context).orderCreated}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    } else {
                      print('⚠️ FLUTTER: Plaćanje nije verifikovano');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context).paymentCancelled),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  print('❌ FLUTTER: Greška pri verifikaciji plaćanja: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${AppLocalizations.of(context).errorVerifyingPayment}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              onCancel: () {
                print('⚠️ FLUTTER: Payment cancelled by user');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).paymentCancelled),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              onError: (String error) {
                print('❌ FLUTTER: Payment error: $error');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppLocalizations.of(context).paymentError}: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          );
        }
      } else {
        print('❌ FLUTTER: Checkout response ne sadrži url ili sessionId');
        throw Exception('Stripe checkout URL nije dostupan');
      }
    } catch (e) {
      print('❌ FLUTTER: Kritična greška u _processPayment: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri plaćanju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
