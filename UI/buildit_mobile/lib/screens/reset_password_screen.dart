import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/utils/utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/screens/user_login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var url = "${BaseProvider.baseUrl}User/reset-password";
      var uri = Uri.parse(url);
      
      var headers = {
        "Content-Type": "application/json",
      };

      var body = jsonEncode({
        "token": widget.token,
        "newPassword": _passwordController.text.trim()
      });

      var response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
      } else {
        var errorData = jsonDecode(response.body);
        String errorMessage = "Greška pri resetovanju lozinke";
        
        if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateInputs() {
    final passwordVal = _passwordController.text;
    final confirmPasswordVal = _confirmPasswordController.text;

    final passwordValidation = inputRequired(passwordVal);
    final confirmPasswordValidation = inputRequired(confirmPasswordVal);

    String? passwordError = passwordValidation;
    String? confirmPasswordError = confirmPasswordValidation;

    if (passwordVal.isNotEmpty && confirmPasswordVal.isNotEmpty && passwordVal != confirmPasswordVal) {
      confirmPasswordError = "Lozinke se ne podudaraju";
    }

    setState(() {
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    return _passwordError == null && _confirmPasswordError == null;
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
            width: 450,
            padding: const EdgeInsets.all(40),
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
            child: _isSuccess
                ? _buildSuccessView()
                : _buildResetForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Resetuj lozinku',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unesite novu lozinku za vaš nalog.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkGray),
              labelText: 'Nova lozinka',
              hintText: 'Unesite novu lozinku',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              errorText: _passwordError,
              errorMaxLines: 2,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.darkGray,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            onChanged: (value) {
              if (_passwordError != null) {
                setState(() {
                  _passwordError = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkGray),
              labelText: 'Potvrdite lozinku',
              hintText: 'Potvrdite novu lozinku',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              errorText: _confirmPasswordError,
              errorMaxLines: 2,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.darkGray,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            onChanged: (value) {
              if (_confirmPasswordError != null) {
                setState(() {
                  _confirmPasswordError = null;
                });
              }
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
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
                      'Resetuj lozinku',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          color: AppColors.primaryOrange,
          size: 80,
        ),
        const SizedBox(height: 24),
        const Text(
          'Lozinka je resetovana!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Vaša lozinka je uspješno resetovana. Sada se možete prijaviti sa novom lozinkom.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.darkGray,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Nazad na prijavu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

