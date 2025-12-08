import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/listing_provider.dart';
import 'package:buildit_mobile/providers/item_provider.dart';
import 'package:buildit_mobile/providers/city_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/models/item_model.dart';
import 'package:buildit_mobile/models/city_model.dart';
import 'package:buildit_mobile/utils/utils.dart';

class UserAddListingScreen extends StatefulWidget {
  final int? selectedItemId;
  
  const UserAddListingScreen({super.key, this.selectedItemId});

  @override
  State<UserAddListingScreen> createState() => _UserAddListingScreenState();
}

class _UserAddListingScreenState extends State<UserAddListingScreen> {
  final ListingProvider _listingProvider = ListingProvider();
  final ItemProvider _itemProvider = ItemProvider();
  final CityProvider _cityProvider = CityProvider();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _titleError;
  String? _descriptionError;
  String? _listingTypeError;
  String? _itemError;
  String? _minRentalDaysError;
  String? _maxRentalDaysError;

  bool _isLoading = false;
  bool _isFeatured = false;

  final List<String> _listingTypes = ['Kupoprodaja', 'Iznajmljivanje'];
  String? _selectedListingType;
  int? _selectedItemId;
  int? _selectedCityId;

  final TextEditingController _minRentalDaysController = TextEditingController();
  final TextEditingController _maxRentalDaysController = TextEditingController();

  List<Item> _items = [];
  List<City> _cities = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    if (widget.selectedItemId != null) {
      _selectedItemId = widget.selectedItemId;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      var itemsResult = await _itemProvider.get(
        page: 1,
        pageSize: 1000,
        filter: {'userId': AuthProvider.id?.toString()},
      );
      var citiesResult = await _cityProvider.get(page: 1, pageSize: 1000);

      setState(() {
        _items = itemsResult.result;
        _cities = citiesResult.result;
        _isLoadingData = false;
      });

      if (widget.selectedItemId != null && _items.isNotEmpty) {
        var selectedItem = _items.firstWhere(
          (item) => item.id == widget.selectedItemId,
          orElse: () => _items.first,
        );
        if (selectedItem != null) {
          setState(() {
            _titleController.text = selectedItem.title;
            _descriptionController.text = selectedItem.description;
          });
        }
      }
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
    _minRentalDaysController.dispose();
    _maxRentalDaysController.dispose();
    super.dispose();
  }


  Future<void> _saveListing() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (AuthProvider.id == null) {
        throw Exception("Korisnik nije prijavljen");
      }

      var insertRequest = {
        'itemId': _selectedItemId,
        'userId': AuthProvider.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'listingType': _selectedListingType,
        'status': 'Active',
        'cityId': _selectedCityId,
        'isFeatured': _isFeatured,
        'images': null,
      };

      if (_selectedListingType == 'Iznajmljivanje') {
        if (_minRentalDaysController.text.trim().isNotEmpty) {
          insertRequest['minRentalDays'] = int.tryParse(_minRentalDaysController.text.trim());
        }
        if (_maxRentalDaysController.text.trim().isNotEmpty) {
          insertRequest['maxRentalDays'] = int.tryParse(_maxRentalDaysController.text.trim());
        }
      }

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
    final itemValidation = _selectedItemId == null ? 'Proizvod je obavezan' : null;

    String? minDaysError;
    String? maxDaysError;

    if (_selectedListingType == 'Iznajmljivanje') {
      if (_minRentalDaysController.text.trim().isEmpty) {
        minDaysError = 'Minimalni broj dana je obavezan za iznajmljivanje';
      } else {
        final minDays = int.tryParse(_minRentalDaysController.text.trim());
        if (minDays == null || minDays <= 0) {
          minDaysError = 'Minimalni broj dana mora biti pozitivan broj';
        }
      }

      if (_maxRentalDaysController.text.trim().isEmpty) {
        maxDaysError = 'Maksimalni broj dana je obavezan za iznajmljivanje';
      } else {
        final maxDays = int.tryParse(_maxRentalDaysController.text.trim());
        if (maxDays == null || maxDays <= 0) {
          maxDaysError = 'Maksimalni broj dana mora biti pozitivan broj';
        } else if (_minRentalDaysController.text.trim().isNotEmpty) {
          final minDays = int.tryParse(_minRentalDaysController.text.trim());
          if (minDays != null && maxDays < minDays) {
            maxDaysError = 'Maksimalni broj dana mora biti veći ili jednak minimalnom';
          }
        }
      }
    }

    setState(() {
      _titleError = titleValidation;
      _descriptionError = descriptionValidation;
      _listingTypeError = listingTypeValidation;
      _itemError = itemValidation;
      _minRentalDaysError = minDaysError;
      _maxRentalDaysError = maxDaysError;
    });

    if (minDaysError != null || maxDaysError != null) {
      return false;
    }

    return _titleError == null &&
        _descriptionError == null &&
        _listingTypeError == null &&
        _itemError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Dodaj novi oglas'),
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
                          labelText: 'Proizvod *',
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
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              _selectedItemId = value;
                              _itemError = null;
                            });

                            try {
                              var selectedItem = await _itemProvider.getById(value);
                              if (selectedItem != null) {
                                setState(() {
                                  if (_titleController.text.isEmpty) {
                                    _titleController.text = selectedItem.title;
                                  }
                                  if (_descriptionController.text.isEmpty) {
                                    _descriptionController.text = selectedItem.description;
                                  }
                                });
                              }
                            } catch (e) {
                              print('Greška pri učitavanju podataka artikla: $e');
                            }
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
                      if (_selectedListingType == 'Iznajmljivanje') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minRentalDaysController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Minimalni broj dana iznajmljivanja *',
                                  prefixIcon: const Icon(Icons.calendar_today, color: AppColors.darkGray),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  errorText: _minRentalDaysError,
                                  errorMaxLines: 2,
                                ),
                                onChanged: (value) {
                                  if (_minRentalDaysError != null) {
                                    setState(() {
                                      _minRentalDaysError = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _maxRentalDaysController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Maksimalni broj dana iznajmljivanja *',
                                  prefixIcon: const Icon(Icons.calendar_today, color: AppColors.darkGray),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  errorText: _maxRentalDaysError,
                                  errorMaxLines: 2,
                                ),
                                onChanged: (value) {
                                  if (_maxRentalDaysError != null) {
                                    setState(() {
                                      _maxRentalDaysError = null;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Izdvojeni oglas'),
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

