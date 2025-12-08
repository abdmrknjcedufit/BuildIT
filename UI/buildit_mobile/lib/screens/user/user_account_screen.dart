import 'package:flutter/material.dart';
import 'package:buildit_mobile/app_colors.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:buildit_mobile/providers/user_provider.dart';
import 'package:buildit_mobile/providers/language_provider.dart';
import 'package:buildit_mobile/l10n/app_localizations.dart';
import 'package:buildit_mobile/screens/user_login_screen.dart';
import 'package:provider/provider.dart';

class UserAccountScreen extends StatelessWidget {
  const UserAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLocale = languageProvider.locale;
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
            Text(
              AppLocalizations.of(context).accountOptions,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 24),
            _buildLanguageOption(context, languageProvider, currentLocale),
            const SizedBox(height: 16),
            _buildAccountOption(
              context,
              AppLocalizations.of(context).logout,
              Icons.exit_to_app,
              AppColors.primaryBlack,
              () {
                _showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 16),
            _buildAccountOption(
              context,
              AppLocalizations.of(context).deleteAccount,
              Icons.delete_outline,
              AppColors.primaryRed,
              () {
                _showDeleteAccountDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
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
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).logoutConfirm),
          content: Text(AppLocalizations.of(context).logoutConfirmMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final userProvider = UserProvider();
                  await userProvider.logout();
                } catch (e) {
                  // Ignore logout errors, continue with local logout
                }
                AuthProvider.logout();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Text(AppLocalizations.of(context).logout, style: const TextStyle(color: AppColors.primaryRed)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).deleteAccountConfirm),
          content: Text(AppLocalizations.of(context).deleteAccountMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement delete account functionality
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).deleteAccountSoon),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: AppColors.primaryRed)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, LanguageProvider languageProvider, Locale currentLocale) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context).selectLanguageTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Radio<Locale>(
                      value: const Locale('bs'),
                      groupValue: currentLocale,
                      onChanged: (Locale? value) {
                        if (value != null) {
                          languageProvider.setLocale(value);
                          Navigator.of(dialogContext).pop();
                        }
                      },
                    ),
                    title: Text(AppLocalizations.of(context).bosnian),
                    onTap: () {
                      languageProvider.setLocale(const Locale('bs'));
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  ListTile(
                    leading: Radio<Locale>(
                      value: const Locale('en'),
                      groupValue: currentLocale,
                      onChanged: (Locale? value) {
                        if (value != null) {
                          languageProvider.setLocale(value);
                          Navigator.of(dialogContext).pop();
                        }
                      },
                    ),
                    title: Text(AppLocalizations.of(context).english),
                    onTap: () {
                      languageProvider.setLocale(const Locale('en'));
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGray),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.language, color: AppColors.primaryOrange, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).language,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentLocale.languageCode == 'bs' ? AppLocalizations.of(context).bosnian : AppLocalizations.of(context).english,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.darkGray, size: 16),
          ],
        ),
      ),
    );
  }
}

