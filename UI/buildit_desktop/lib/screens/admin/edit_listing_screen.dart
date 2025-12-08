import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/listing_provider.dart';
import 'package:buildit_desktop/models/listing_model.dart';
import 'package:buildit_desktop/utils/utils.dart';

class EditListingScreen extends StatefulWidget {
  final Listing listing;

  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final ListingProvider _listingProvider = ListingProvider();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _listingTypeController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  String? _titleError;
  String? _descriptionError;
  String? _listingTypeError;
  String? _statusError;

  bool _isLoading = false;
  bool _isFeatured = false;

  final List<String> _listingTypes = ['Kupovina', 'Iznajmljivanje'];
  final List<String> _statuses = ['Active', 'Inactive', 'Sold', 'Rented'];
  String? _selectedListingType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.listing.title;
    _descriptionController.text = widget.listing.description;
    _isFeatured = widget.listing.isFeatured;
    
    _selectedListingType = _listingTypes.contains(widget.listing.listingType) 
        ? widget.listing.listingType 
        : null;
    _listingTypeController.text = _selectedListingType ?? widget.listing.listingType;
    
    _selectedStatus = _statuses.contains(widget.listing.status) 
        ? widget.listing.status 
        : null;
    _statusController.text = _selectedStatus ?? widget.listing.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _listingTypeController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _saveListing() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var updateRequest = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'listingType': _listingTypeController.text.trim(),
        'status': _statusController.text.trim(),
        'isFeatured': _isFeatured,
      };

      await _listingProvider.update(widget.listing.id, updateRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oglas je uspješno ažuriran'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri čuvanju oglasa: $e'),
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
    final listingTypeVal = _listingTypeController.text;
    final statusVal = _statusController.text;

    final titleValidation = inputRequired(titleVal);
    final descriptionValidation = inputRequired(descriptionVal);
    final listingTypeValidation = inputRequired(listingTypeVal);
    final statusValidation = inputRequired(statusVal);

    setState(() {
      _titleError = titleValidation;
      _descriptionError = descriptionValidation;
      _listingTypeError = listingTypeValidation;
      _statusError = statusValidation;
    });

    return _titleError == null &&
        _descriptionError == null &&
        _listingTypeError == null &&
        _statusError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Izmjena oglasa'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: SingleChildScrollView(
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
                  'Izmjena podataka oglasa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 24),
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
                        _listingTypeController.text = value;
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
                        _statusController.text = value;
                        _statusError = null;
                      });
                    }
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
                          : const Text('Sačuvaj'),
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
