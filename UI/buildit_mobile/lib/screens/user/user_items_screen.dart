import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/item_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/models/item_model.dart';
import 'package:buildit_mobile/screens/user/user_add_item_screen.dart';
import 'package:buildit_mobile/screens/user/user_add_listing_screen.dart';
import 'package:buildit_mobile/screens/user/user_products_screen.dart';
import 'package:buildit_mobile/screens/user/user_cart_screen.dart';
import 'package:buildit_mobile/screens/user/user_messages_screen.dart';
import 'package:buildit_mobile/screens/user/user_settings_screen.dart';
import 'package:buildit_mobile/screens/mobile_home_screen.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/screens/user_login_screen.dart';

class UserItemsScreen extends StatefulWidget {
  const UserItemsScreen({super.key});

  @override
  State<UserItemsScreen> createState() => _UserItemsScreenState();
}

class _UserItemsScreenState extends State<UserItemsScreen> {
  final ItemProvider _itemProvider = ItemProvider();
  final UserProvider _userProvider = UserProvider();
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      setState(() {
        _isLoading = true;
      });

      var result = await _itemProvider.get(
        page: 1,
        pageSize: 1000,
        filter: {'userId': AuthProvider.id?.toString()},
      );

      setState(() {
        _items = result.result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju artikala: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(int itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: const Text('Da li ste sigurni da želite obrisati ovaj artikal?'),
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
        await _itemProvider.delete(itemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Artikal je uspješno obrisan'),
              backgroundColor: Colors.green,
            ),
          );
          _loadItems();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška pri brisanju artikla: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                      ),
                    )
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: AppColors.darkGray,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nemate artikala',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.darkGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Dodajte artikal da biste mogli kreirati oglas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.darkGray,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const UserAddItemScreen()),
                                  );
                                  if (result == true) {
                                    _loadItems();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Dodaj artikal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryOrange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('${item.price.toStringAsFixed(2)} KM'),
                                    if (item.brand != null || item.model != null)
                                      Text(
                                        '${item.brand ?? ''} ${item.model ?? ''}'.trim(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    Text(
                                      '${item.itemType} • ${item.condition}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.darkGray),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: AppColors.primaryOrange),
                                      onPressed: () async {
                                        final result = await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => UserAddListingScreen(selectedItemId: item.id),
                                          ),
                                        );
                                        if (result == true) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(builder: (context) => const UserProductsScreen()),
                                          );
                                        }
                                      },
                                      tooltip: 'Kreiraj oglas',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteItem(item.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserAddItemScreen()),
          );
          if (result == true) {
            _loadItems();
          }
        },
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'Dodaj artikal',
          style: TextStyle(color: AppColors.white),
        ),
      ),
    );
  }
}

