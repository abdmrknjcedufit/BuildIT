import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/models/user_model.dart';
import 'package:buildit_mobile/utils/utils.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserProvider _userProvider = UserProvider();
  User? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (AuthProvider.id == null) {
        throw Exception("Korisnik nije prijavljen");
      }

      var user = await _userProvider.getById(AuthProvider.id!);
      
      setState(() {
        _currentUser = user;
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _emailController.text = user.email;
        _phoneController.text = user.phone ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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
      };

      var updatedUser = await _userProvider.update(AuthProvider.id!, updateRequest);

      setState(() {
        _currentUser = updatedUser;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Podaci su uspješno ažurirani'),
            backgroundColor: Colors.green,
          ),
        );
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
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Postavke'),
        backgroundColor: AppColors.primaryOrange,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryOrange,
              ),
            )
          : _currentUser == null
              ? const Center(
                  child: Text(
                    'Nema podataka o korisniku',
                    style: TextStyle(fontSize: 16, color: AppColors.darkGray),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfoCard(),
                      const SizedBox(height: 20),
                      _buildEditForm(),
                      const SizedBox(height: 20),
                      _buildSaveButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _currentUser!.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currentUser!.firstName} ${_currentUser!.lastName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser!.username,
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
          const SizedBox(height: 16),
          _buildInfoRow('Email', _currentUser!.email),
          if (_currentUser!.phone != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Telefon', _currentUser!.phone!),
          ],
          const SizedBox(height: 8),
          _buildInfoRow('Datum rođenja', DateFormat('dd.MM.yyyy').format(_currentUser!.birthDate)),
          const SizedBox(height: 8),
          _buildInfoRow('Tip korisnika', _currentUser!.userType ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryBlack,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            'Izmjena podataka',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'Ime',
              prefixIcon: const Icon(Icons.person, color: AppColors.darkGray),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: _firstNameError,
              errorMaxLines: 2,
            ),
            onChanged: (value) {
              if (_firstNameError != null) {
                setState(() {
                  _firstNameError = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Prezime',
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.darkGray),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: _lastNameError,
              errorMaxLines: 2,
            ),
            onChanged: (value) {
              if (_lastNameError != null) {
                setState(() {
                  _lastNameError = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email adresa',
              prefixIcon: const Icon(Icons.email, color: AppColors.darkGray),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: _emailError,
              errorMaxLines: 2,
            ),
            onChanged: (value) {
              if (_emailError != null) {
                setState(() {
                  _emailError = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Telefon (opcionalno)',
              prefixIcon: const Icon(Icons.phone, color: AppColors.darkGray),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: _phoneError,
              errorMaxLines: 2,
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              if (_phoneError != null) {
                setState(() {
                  _phoneError = null;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Sačuvaj izmjene',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }
}

