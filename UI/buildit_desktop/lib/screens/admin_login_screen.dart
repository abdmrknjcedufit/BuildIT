import 'package:flutter/material.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/user_provider.dart';
import 'package:buildit_desktop/providers/auth_provider.dart';
import 'package:buildit_desktop/utils/utils.dart';
import 'package:buildit_desktop/screens/admin/admin_home_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
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
      var user = await _userProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        clientType: "desktop",
      );

      // Proveri da li je korisnik admin
      bool isAdmin = user.roles.contains('Admin');
      
      if (!isAdmin) {
        throw Exception("Samo administratori mogu pristupiti desktop aplikaciji.");
      }

      AuthProvider.id = user.id;
      AuthProvider.userType = "Admin";

      if (!mounted) return;

      _usernameController.clear();
      _passwordController.clear();

      // Admin ide na desktop admin panel
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AdminHomeScreen(),  // Desktop admin panel
        ),
      );
    } on Exception catch (e) {
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
          content: Text(e.toString()),
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
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'B',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'BuildIT Admin',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Administratorski pristup',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Korisničko ime',
                    hintText: 'Unesite vaše korisničko ime',
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
                    labelText: 'Lozinka',
                    hintText: 'Unesite vašu lozinku',
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
                        : const Text(
                            'Prijava kao Admin',
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
          ),
        ),
      ),
    );
  }
}

