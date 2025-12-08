import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/utils/utils.dart';
import 'package:buildit_mobile/screens/mobile_home_screen.dart';
import 'package:buildit_mobile/screens/forgot_password_screen.dart';
import 'package:buildit_mobile/screens/registration_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _usernameError;
  String? _passwordError;
  bool _isLoading = false;
  final UserProvider _userProvider = UserProvider();

  void _login() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    AuthProvider.username = _usernameController.text;
    AuthProvider.password = _passwordController.text;

    try {
      print("🔵 Attempting login with username: ${_usernameController.text.trim()}");
      
      var user = await _userProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      print("✅ Login successful! User ID: ${user.id}, Roles: ${user.roles}");

      AuthProvider.id = user.id;
      AuthProvider.userType = user.userType;

      if (!mounted) return;

      _usernameController.clear();
      _passwordController.clear();

      // Mobile aplikacija - samo obični korisnici
      bool isAdmin = user.roles.contains('Admin');
      
      if (isAdmin) {
        throw Exception("Administratori moraju koristiti desktop aplikaciju.");
      }
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MobileHomeScreen(),  // Mobile verzija za obične korisnike
        ),
      );
    } catch (e) {
      print("❌ Login error: $e");
      if (!mounted) return;
      
      String errorMessage = AppLocalizations.of(context).loginError;
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).loginError),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).ok),
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
    final usernameVal = _usernameController.text;
    final passwordVal = _passwordController.text;

    final usernameValidation = inputRequired(usernameVal);
    final passwordValidation = inputRequired(passwordVal);

    setState(() {
      _usernameError = usernameValidation;
      _passwordError = passwordValidation;
    });

    return _usernameError == null && _passwordError == null;
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
                Text(
                  AppLocalizations.of(context).loginToAccount,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.darkGray),
                    labelText: AppLocalizations.of(context).username,
                    hintText: AppLocalizations.of(context).enterUsername,
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
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkGray),
                    labelText: AppLocalizations.of(context).password,
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
                  onSubmitted: (_) {
                    _login();
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
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
                        : Text(
                            AppLocalizations.of(context).login,
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
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.primaryGray,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppLocalizations.of(context).or,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.primaryGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${AppLocalizations.of(context).dontHaveAccount} ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGray,
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegistrationScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context).register,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context).resetPassword,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                          ),
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
    );
  }
}

