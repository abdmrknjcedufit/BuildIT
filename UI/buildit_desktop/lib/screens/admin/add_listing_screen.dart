import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/listing_provider.dart';
import 'package:buildit_desktop/providers/item_provider.dart';
import 'package:buildit_desktop/providers/user_provider.dart';
import 'package:buildit_desktop/providers/city_provider.dart';
import 'package:buildit_desktop/providers/auth_provider.dart';
import 'package:buildit_desktop/models/item_model.dart';
import 'package:buildit_desktop/models/user_model.dart';
import 'package:buildit_desktop/models/city_model.dart';
import 'package:buildit_desktop/utils/utils.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final ListingProvider _listingProvider = ListingProvider();
  final ItemProvider _itemProvider = ItemProvider();
  final UserProvider _userProvider = UserProvider();
  final CityProvider _cityProvider = CityProvider();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _titleError;
  String? _descriptionError;
  String? _listingTypeError;
  String? _statusError;
  String? _itemError;
  String? _userError;

  bool _isLoading = false;
  bool _isFeatured = false;

  final List<String> _listingTypes = ['Kupovina', 'Iznajmljivanje'];
  final List<String> _statuses = ['Active', 'Inactive', 'Sold', 'Rented'];
  String? _selectedListingType;
  String? _selectedStatus;
  int? _selectedItemId;
  int? _selectedUserId;
  int? _selectedCityId;

  List<Item> _items = [];
  List<User> _users = [];
  List<City> _cities = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      var itemsResult = await _itemProvider.get(page: 1, pageSize: 1000);
      var usersResult = await _userProvider.get(page: 1, pageSize: 1000);
      var citiesResult = await _cityProvider.get(page: 1, pageSize: 1000);

      setState(() {
        _items = itemsResult.result;
        _users = usersResult.result;
        _cities = citiesResult.result;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri učitavanju podataka: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveListing() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var insertRequest = {
        'itemId': _selectedItemId,
        'userId': _selectedUserId ?? AuthProvider.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'listingType': _selectedListingType,
        'status': _selectedStatus ?? 'Active',
        'cityId': _selectedCityId,
        'isFeatured': _isFeatured,
      };

      await _listingProvider.insert(insertRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oglas je uspješno kreiran'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri kreiranju oglasa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateInputs() {
    final titleVal = _titleController.text;
    final descriptionVal = _descriptionController.text;

    final titleValidation = inputRequired(titleVal);
    final descriptionValidation = inputRequired(descriptionVal);
    final listingTypeValidation = _selectedListingType == null ? 'Tip oglasa je obavezan' : null;
    final statusValidation = _selectedStatus == null ? 'Status je obavezan' : null;
    final itemValidation = _selectedItemId == null ? 'Artikal je obavezan' : null;
    final userValidation = _selectedUserId == null ? 'Korisnik je obavezan' : null;

    setState(() {
      _titleError = titleValidation;
      _descriptionError = descriptionValidation;
      _listingTypeError = listingTypeValidation;
      _statusError = statusValidation;
      _itemError = itemValidation;
      _userError = userValidation;
    });

    return _titleError == null &&
        _descriptionError == null &&
        _listingTypeError == null &&
        _statusError == null &&
        _itemError == null &&
        _userError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Dodaj oglas'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
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
                      const Text(
                        'Dodavanje novog oglasa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<int>(
                        value: _selectedItemId,
                        decoration: InputDecoration(
                          labelText: 'Artikal *',
                          prefixIcon: const Icon(Icons.inventory_2, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _itemError,
                        ),
                        items: _items.map((item) {
                          return DropdownMenuItem(
                            value: item.id,
                            child: Text('${item.title} (${item.price.toStringAsFixed(2)} KM)'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedItemId = value;
                              _itemError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedUserId,
                        decoration: InputDecoration(
                          labelText: 'Korisnik *',
                          prefixIcon: const Icon(Icons.person, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _userError,
                        ),
                        items: _users.map((user) {
                          return DropdownMenuItem(
                            value: user.id,
                            child: Text('${user.firstName} ${user.lastName} (${user.username})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUserId = value;
                              _userError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Naslov *',
                          prefixIcon: const Icon(Icons.title, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _titleError,
                          errorMaxLines: 2,
                        ),
                        onChanged: (value) {
                          if (_titleError != null) {
                            setState(() {
                              _titleError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Opis *',
                          prefixIcon: const Icon(Icons.description, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _descriptionError,
                          errorMaxLines: 2,
                        ),
                        onChanged: (value) {
                          if (_descriptionError != null) {
                            setState(() {
                              _descriptionError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedListingType,
                        decoration: InputDecoration(
                          labelText: 'Tip oglasa *',
                          prefixIcon: const Icon(Icons.category, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _listingTypeError,
                        ),
                        items: _listingTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedListingType = value;
                              _listingTypeError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status *',
                          prefixIcon: const Icon(Icons.info, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _statusError,
                        ),
                        items: _statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                              _statusError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedCityId,
                        decoration: InputDecoration(
                          labelText: 'Grad (opcionalno)',
                          prefixIcon: const Icon(Icons.location_city, color: AppColors.darkGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _cities.map((city) {
                          return DropdownMenuItem(
                            value: city.id,
                            child: Text(city.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCityId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Featured oglas'),
                        value: _isFeatured,
                        onChanged: (value) {
                          setState(() {
                            _isFeatured = value ?? false;
                          });
                        },
                        activeColor: AppColors.primaryOrange,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Otkaži'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveListing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              foregroundColor: AppColors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Text('Dodaj oglas'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

