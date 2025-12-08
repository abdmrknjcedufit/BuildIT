import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/models/user_model.dart';
import 'package:buildit_mobile/models/city_model.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/providers/city_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/utils/utils.dart';
import 'package:intl/intl.dart';

class UserProfileEditScreen extends StatefulWidget {
  final User? user;
  final VoidCallback? onUserUpdated;

  const UserProfileEditScreen({super.key, this.user, this.onUserUpdated});

  @override
  State<UserProfileEditScreen> createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final UserProvider _userProvider = UserProvider();
  final CityProvider _cityProvider = CityProvider();
  bool _isEditMode = false;
  bool _isSaving = false;
  List<City> _cities = [];
  int? _selectedCityId;
  bool _isLoadingCities = true;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _loadCities();
    if (widget.user != null) {
      _loadUserData();
    }
  }

  Future<void> _loadCities() async {
    try {
      var result = await _cityProvider.get();
      setState(() {
        _cities = result.result;
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    _loadUserDataFromUser(widget.user);
  }

  void _loadUserDataFromUser(User? user) {
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _addressController.text = user?.address ?? '';
    _postalCodeController.text = user?.postalCode ?? '';
    _selectedCityId = user?.cityId;
  }

  Future<void> _saveChanges() async {
    if (!_validateInputs()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (AuthProvider.id == null) {
        throw Exception("Korisnik nije prijavljen");
      }

      var updateRequest = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'cityId': _selectedCityId,
        'postalCode': _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
      };

      await _userProvider.update(AuthProvider.id!, updateRequest);

      var updatedUser = await _userProvider.getById(AuthProvider.id!);
      
      setState(() {
        _isEditMode = false;
        _isSaving = false;
      });

      _loadUserDataFromUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Podaci su uspješno ažurirani'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (widget.onUserUpdated != null) {
          widget.onUserUpdated!();
        }
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri čuvanju podataka: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _validateInputs() {
    final firstNameVal = _firstNameController.text;
    final lastNameVal = _lastNameController.text;
    final emailVal = _emailController.text;
    final phoneVal = _phoneController.text;

    final firstNameValidation = inputRequired(firstNameVal);
    final lastNameValidation = inputRequired(lastNameVal);
    final emailValidation = inputRequired(emailVal) ?? emailFormat(emailVal);
    final phoneValidation = phoneVal.isNotEmpty ? minLength(phoneVal, 9) : null;

    setState(() {
      _firstNameError = firstNameValidation;
      _lastNameError = lastNameValidation;
      _emailError = emailValidation;
      _phoneError = phoneValidation;
    });

    return _firstNameError == null && 
           _lastNameError == null && 
           _emailError == null && 
           _phoneError == null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Center(
        child: Text(
          'Nema podataka o korisniku',
          style: TextStyle(fontSize: 16, color: AppColors.darkGray),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Moj profil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                if (!_isEditMode)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditMode = true;
                      });
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Uredi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isEditMode) ...[
              _buildEditableField('Ime', _firstNameController, _firstNameError),
              const SizedBox(height: 16),
              _buildEditableField('Prezime', _lastNameController, _lastNameError),
              const SizedBox(height: 16),
              _buildEditableField('Email', _emailController, _emailError),
              const SizedBox(height: 16),
              _buildEditableField('Telefonski broj', _phoneController, _phoneError),
              const SizedBox(height: 16),
              _buildEditableField('Adresa', _addressController, null),
              const SizedBox(height: 16),
              _buildCityDropdown(),
              const SizedBox(height: 16),
              _buildEditableField('Poštanski broj', _postalCodeController, null),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () {
                        setState(() {
                          _isEditMode = false;
                          _loadUserData();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightGray,
                        foregroundColor: AppColors.primaryBlack,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Otkaži'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Sačuvaj'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildReadOnlyField('Ime', widget.user!.firstName),
              const SizedBox(height: 16),
              _buildReadOnlyField('Prezime', widget.user!.lastName),
              const SizedBox(height: 16),
              _buildReadOnlyField('Email', widget.user!.email),
              const SizedBox(height: 16),
              _buildReadOnlyField('Telefonski broj', widget.user!.phone ?? 'N/A'),
              const SizedBox(height: 16),
              _buildReadOnlyField('Adresa', widget.user!.address ?? 'N/A'),
              const SizedBox(height: 16),
              _buildReadOnlyField('Grad', _getCityName()),
              const SizedBox(height: 16),
              _buildReadOnlyField('Poštanski broj', widget.user!.postalCode ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlack,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            errorText: error,
            errorMaxLines: 2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) {
            if (error != null) {
              setState(() {
                if (label == 'Ime') _firstNameError = null;
                if (label == 'Prezime') _lastNameError = null;
                if (label == 'Email') _emailError = null;
                if (label == 'Telefonski broj') _phoneError = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grad',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingCities
            ? const CircularProgressIndicator()
            : DropdownButtonFormField<int>(
                value: _selectedCityId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                hint: const Text('Odaberite grad'),
                items: _cities.map((city) {
                  return DropdownMenuItem<int>(
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
      ],
    );
  }

  String _getCityName() {
    if (widget.user?.cityId == null) {
      return 'N/A';
    }
    final city = _cities.firstWhere(
      (c) => c.id == widget.user!.cityId,
      orElse: () => City(id: 0, name: 'N/A', isActive: true),
    );
    return city.name;
  }
}

