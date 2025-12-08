import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/utils/utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buildit_mobile/providers/base_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _phoneError;
  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _resetPassword() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    try {
      var url = "${BaseProvider.baseUrl}User/forgot-password";
      var uri = Uri.parse(url);
      
      var headers = {
        "Content-Type": "application/json",
      };

      var body = jsonEncode({"phone": _phoneController.text.trim()});

      print("🔵 Sending forgot password request to: $url");
      print("🔵 Body: $body");

      var response = await http.post(uri, headers: headers, body: body);

      print("🔵 Response status: ${response.statusCode}");
      print("🔵 Response body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        var data = jsonDecode(response.body);
        
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
      print("❌ Error resetting password: $e");
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
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
          content: Text(e.toString().replaceFirst("Exception: ", "")),
        ),
      );
    }
  }

  bool _validateInputs() {
    final phoneVal = _phoneController.text;

    final phoneValidation = inputRequired(phoneVal) ?? phoneValidator(phoneVal);

    setState(() {
      _phoneError = phoneValidation;
    });

    return _phoneError == null;
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
    return Column(
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
          'Reset lozinke',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Unesite vaš broj telefona i mi ćemo vam poslati SMS sa novom lozinkom.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.darkGray,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.darkGray),
            labelText: 'Broj telefona',
            hintText: '+38761123456',
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
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sjećate se lozinke? ',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkGray,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Text(
                'Nazad na prijavu',
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
          'Nova lozinka je poslana!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Provjerite vaš telefon. Poslali smo vam SMS sa novom lozinkom.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.darkGray,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Možete se prijaviti sa novom lozinkom.',
          style: TextStyle(
            fontSize: 14,
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
              Navigator.of(context).pop();
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

