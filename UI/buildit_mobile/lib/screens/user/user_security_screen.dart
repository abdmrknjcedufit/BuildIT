import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/utils/utils.dart';
import 'dart:convert' show base64Encode, utf8, jsonEncode, jsonDecode;
import 'package:http/http.dart' as http;
import 'package:buildit_mobile/providers/base_provider.dart';

class UserSecurityScreen extends StatefulWidget {
  const UserSecurityScreen({super.key});

  @override
  State<UserSecurityScreen> createState() => _UserSecurityScreenState();
}

class _UserSecurityScreenState extends State<UserSecurityScreen> {

  Future<void> _changePassword() async {
    if (!mounted) return;

    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? oldPasswordError;
    String? newPasswordError;
    String? confirmPasswordError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Promijeni lozinku'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Stara lozinka',
                    border: const OutlineInputBorder(),
                    errorText: oldPasswordError,
                  ),
                  enabled: !isLoading,
                  onChanged: (value) {
                    if (oldPasswordError != null) {
                      setDialogState(() => oldPasswordError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nova lozinka',
                    border: const OutlineInputBorder(),
                    errorText: newPasswordError,
                  ),
                  enabled: !isLoading,
                  onChanged: (value) {
                    if (newPasswordError != null) {
                      setDialogState(() => newPasswordError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Potvrdi novu lozinku',
                    border: const OutlineInputBorder(),
                    errorText: confirmPasswordError,
                  ),
                  enabled: !isLoading,
                  onChanged: (value) {
                    if (confirmPasswordError != null) {
                      setDialogState(() => confirmPasswordError = null);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () {
                oldPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final oldPassword = oldPasswordController.text;
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;

                bool hasError = false;
                setDialogState(() {
                  oldPasswordError = inputRequired(oldPassword);
                  newPasswordError = inputRequired(newPassword);
                  confirmPasswordError = inputRequired(confirmPassword);
                  
                  if (confirmPasswordError == null && newPassword != confirmPassword) {
                    confirmPasswordError = 'Lozinke se ne podudaraju';
                    hasError = true;
                  }
                  
                  if (oldPasswordError != null || newPasswordError != null || confirmPasswordError != null) {
                    hasError = true;
                  }
                });

                if (hasError) return;

                setDialogState(() => isLoading = true);

                try {
                  var url = "${BaseProvider.baseUrl}User/change-password";
                  var uri = Uri.parse(url);
                  
                  var headers = {
                    "Content-Type": "application/json",
                    "Authorization": "Basic ${base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'))}",
                  };

                  var body = jsonEncode({
                    "oldPassword": oldPassword,
                    "newPassword": newPassword,
                    "newPasswordConfirm": confirmPassword
                  });

                  var response = await http.post(uri, headers: headers, body: body);

                  if (response.statusCode >= 200 && response.statusCode < 300) {
                    var data = jsonDecode(response.body);
                    
                    oldPasswordController.dispose();
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();
                    
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(data['message'] ?? 'Lozinka je uspješno promijenjena.'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } else {
                    var errorData = jsonDecode(response.body);
                    String errorMessage = "Greška pri promjeni lozinke";
                    
                    if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
                      errorMessage = errorData['message'];
                    }
                    
                    throw Exception(errorMessage);
                  }
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceFirst("Exception: ", "")),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text(
                      'Promijeni',
                      style: TextStyle(color: AppColors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Sigurnost naloga',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 24),
            _buildSecurityOption(
              context,
              'Promijeni lozinku',
              Icons.lock_outline,
              _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGray),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlack, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlack,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.darkGray,
            ),
          ],
        ),
      ),
    );
  }
}

