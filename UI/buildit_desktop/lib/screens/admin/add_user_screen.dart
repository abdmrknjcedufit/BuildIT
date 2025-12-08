import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/user_provider.dart';
import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final UserProvider _userProvider = UserProvider();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _passwordConfirmError;
  String? _birthDateError;
  String? _userTypeError;

  bool _isLoading = false;
  DateTime? _selectedBirthDate;
  String? _selectedUserType;

  List<Map<String, String>> _userTypes = [];

  @override
  void initState() {
    super.initState();
    _loadUserTypes();
  }

  Future<void> _loadUserTypes() async {
    try {
      var url = "${BaseProvider.baseUrl}User/user-types";
      var uri = Uri.parse(url);
      var response = await http.get(uri);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _userTypes = data.map<Map<String, String>>((item) => {
              'value': item['value'] as String,
              'label': item['label'] as String,
            }).toList();
          });
          return;
        }
      }
    } catch (e) {
      print("⚠️ Error loading user types: $e");
    }
    setState(() {
      _userTypes = [
        {'value': 'Individual', 'label': 'Kupac/Fizičko lice'},
        {'value': 'Company', 'label': 'Firma/Pravno lice'},
      ];
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('dd.MM.yyyy').format(picked);
        _birthDateError = null;
      });
    }
  }

  Future<void> _saveUser() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var insertRequest = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'password': _passwordController.text.trim(),
        'passwordConfirm': _passwordConfirmController.text.trim(),
        'birthDate': _selectedBirthDate?.toIso8601String().split('T')[0],
        'userType': _selectedUserType ?? 'Individual',
      };

      await _userProvider.insert(insertRequest);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Korisnik je uspješno kreiran'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri kreiranju korisnika: $e'),
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
    final firstNameVal = _firstNameController.text;
    final lastNameVal = _lastNameController.text;
    final usernameVal = _usernameController.text;
    final emailVal = _emailController.text;
    final phoneVal = _phoneController.text;
    final passwordVal = _passwordController.text;
    final passwordConfirmVal = _passwordConfirmController.text;

    final firstNameValidation = inputRequired(firstNameVal);
    final lastNameValidation = inputRequired(lastNameVal);
    final usernameValidation = inputRequired(usernameVal) ?? minLength(usernameVal, 3);
    final emailValidation = inputRequired(emailVal) ?? emailFormat(emailVal);
    final phoneValidation = phoneVal.isNotEmpty ? minLength(phoneVal, 9) : null;
    final passwordValidation = inputRequired(passwordVal) ?? password(passwordVal);
    final passwordConfirmValidation = passwordVal != passwordConfirmVal 
        ? 'Lozinke se ne poklapaju' 
        : null;
    final birthDateValidation = _selectedBirthDate == null ? 'Datum rođenja je obavezan' : null;
    final userTypeValidation = _selectedUserType == null ? 'Tip korisnika je obavezan' : null;

    setState(() {
      _firstNameError = firstNameValidation;
      _lastNameError = lastNameValidation;
      _usernameError = usernameValidation;
      _emailError = emailValidation;
      _phoneError = phoneValidation;
      _passwordError = passwordValidation;
      _passwordConfirmError = passwordConfirmValidation;
      _birthDateError = birthDateValidation;
      _userTypeError = userTypeValidation;
    });

    return _firstNameError == null &&
        _lastNameError == null &&
        _usernameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _passwordConfirmError == null &&
        _birthDateError == null &&
        _userTypeError == null;
  }

  @override
  Widget build(BuildContext context) {
    if (_userTypes.isEmpty) {
      _userTypes = [
        {'value': 'Individual', 'label': 'Kupac/Fizičko lice'},
        {'value': 'Company', 'label': 'Firma/Pravno lice'},
      ];
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Dodaj korisnika'),
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
                  'Dodavanje novog korisnika',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Ime *',
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
                    labelText: 'Prezime *',
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
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Korisničko ime *',
                    prefixIcon: const Icon(Icons.account_circle, color: AppColors.darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _usernameError,
                    errorMaxLines: 2,
                  ),
                  onChanged: (value) {
                    if (_usernameError != null) {
                      setState(() {
                        _usernameError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email adresa *',
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
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Lozinka *',
                    prefixIcon: const Icon(Icons.lock, color: AppColors.darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _passwordError,
                    errorMaxLines: 3,
                  ),
                  onChanged: (value) {
                    if (_passwordError != null || _passwordConfirmError != null) {
                      setState(() {
                        _passwordError = null;
                        _passwordConfirmError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordConfirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Potvrdi lozinku *',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _passwordConfirmError,
                    errorMaxLines: 2,
                  ),
                  onChanged: (value) {
                    if (_passwordConfirmError != null) {
                      setState(() {
                        _passwordConfirmError = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Datum rođenja *',
                    prefixIcon: const Icon(Icons.calendar_today, color: AppColors.darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _birthDateError,
                    errorMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: _selectBirthDate,
                    ),
                  ),
                  onTap: _selectBirthDate,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  decoration: InputDecoration(
                    labelText: 'Tip korisnika *',
                    prefixIcon: const Icon(Icons.person_pin, color: AppColors.darkGray),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _userTypeError,
                  ),
                  items: _userTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUserType = value;
                        _userTypeError = null;
                      });
                    }
                  },
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
                      onPressed: _isLoading ? null : _saveUser,
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
                          : const Text('Dodaj korisnika'),
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

