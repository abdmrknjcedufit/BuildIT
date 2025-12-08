import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/utils/utils.dart';
import 'package:buildit_mobile/screens/user_login_screen.dart';
import 'package:intl/intl.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  
  String? _userType = "Individual";
  bool _isLoading = false;
  final UserProvider _userProvider = UserProvider();

  String? _firstNameError;
  String? _lastNameError;
  String? _usernameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _passwordConfirmError;
  String? _birthDateError;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      helpText: 'Odaberite datum rođenja',
      cancelText: 'Otkaži',
      confirmText: 'Potvrdi',
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        _birthDateError = null;
      });
    }
  }

  Future<void> _register() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'password': _passwordController.text,
        'passwordConfirm': _passwordConfirmController.text,
        'birthDate': _birthDateController.text,
        'userType': _userType,
        'role': 'User',
      };

      print("🔵 Registering user...");
      print("🔵 Request: $request");

      var user = await _userProvider.insert(request, requireAuth: false);

      print("✅ Registration successful! User ID: ${user.id}");

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registracija uspješna'),
          content: const Text('Vaš nalog je uspješno kreiran. Sada se možete prijaviti.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const UserLoginScreen(),
                  ),
                );
              },
              child: const Text('U redu'),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Registration error: $e");
      if (!mounted) return;
      
      String errorMessage = "Greška pri registraciji";
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Greška"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("U redu"),
            ),
          ],
          content: Text(errorMessage),
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  bool _validateInputs() {
    bool isValid = true;

    final firstNameVal = _firstNameController.text;
    final lastNameVal = _lastNameController.text;
    final usernameVal = _usernameController.text;
    final emailVal = _emailController.text;
    final phoneVal = _phoneController.text;
    final passwordVal = _passwordController.text;
    final passwordConfirmVal = _passwordConfirmController.text;
    final birthDateVal = _birthDateController.text;

    setState(() {
      _firstNameError = inputRequired(firstNameVal);
      _lastNameError = inputRequired(lastNameVal);
      _usernameError = inputRequired(usernameVal) ?? minLength(usernameVal, 3) ?? maxLength(usernameVal, 20);
      _emailError = inputRequired(emailVal) ?? emailFormat(emailVal);
      _phoneError = phoneVal.isNotEmpty ? phoneValidator(phoneVal) : null;
      _passwordError = inputRequired(passwordVal);
      _passwordConfirmError = inputRequired(passwordConfirmVal);
      _birthDateError = inputRequired(birthDateVal, 'Datum rođenja je obavezan.');
    });

    if (_passwordError == null && _passwordConfirmError == null) {
      if (passwordVal != passwordConfirmVal) {
        setState(() {
          _passwordConfirmError = 'Lozinka i potvrda lozinke se ne podudaraju';
        });
        isValid = false;
      }
    }

    if (_firstNameError != null ||
        _lastNameError != null ||
        _usernameError != null ||
        _emailError != null ||
        _phoneError != null ||
        _passwordError != null ||
        _passwordConfirmError != null ||
        _birthDateError != null) {
      isValid = false;
    }

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'B',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BuildIT',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlack,
                              ),
                            ),
                            Text(
                              'Prodaja i iznajmljivanje građevinskog materijala',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Registracija',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'Ime *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText: _firstNameError,
                          ),
                          onChanged: (value) {
                            if (_firstNameError != null) {
                              setState(() {
                                _firstNameError = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Prezime *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText: _lastNameError,
                          ),
                          onChanged: (value) {
                            if (_lastNameError != null) {
                              setState(() {
                                _lastNameError = null;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Korisničko ime *',
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
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email adresa *',
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
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Telefon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: _phoneError,
                      errorMaxLines: 2,
                    ),
                    onChanged: (value) {
                      if (_phoneError != null) {
                        setState(() {
                          _phoneError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _birthDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Datum rođenja *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                      errorText: _birthDateError,
                    ),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _userType,
                    decoration: InputDecoration(
                      labelText: 'Tip korisnika *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Individual',
                        child: Text('Pojedinac'),
                      ),
                      DropdownMenuItem(
                        value: 'Company',
                        child: Text('Firma'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _userType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Lozinka *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: _passwordError,
                      errorMaxLines: 3,
                    ),
                    onChanged: (value) {
                      if (_passwordError != null) {
                        setState(() {
                          _passwordError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordConfirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Potvrdi lozinku *',
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
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.white,
                              ),
                            )
                          : const Text(
                              'Registruj se',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Već imate nalog? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGray,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const UserLoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Prijavite se',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

