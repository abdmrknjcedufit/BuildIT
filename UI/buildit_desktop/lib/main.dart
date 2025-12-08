import 'package:flutter/material.dart';
import 'package:buildit_desktop/screens/admin_login_screen.dart';
import 'package:buildit_desktop/app_colors.dart';
import 'package:buildit_desktop/providers/language_provider.dart';
import 'package:buildit_desktop/l10n/app_localizations.dart';
import 'package:buildit_desktop/l10n/app_localizations_bs.dart';
import 'package:buildit_desktop/l10n/app_localizations_en.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: 'BuildIT',
            locale: languageProvider.locale,
            localizationsDelegates: const [
              _AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
        fontFamily: 'OpenSans',
        primaryColor: AppColors.primaryOrange,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryOrange,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryOrange,
          primary: AppColors.primaryOrange,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryOrange,
          ),
          contentTextStyle: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryOrange),
        ),
      ),
            home: const AdminLoginScreen(),
          );
        },
      ),
    );
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'bs':
        return AppLocalizationsBs();
      case 'en':
        return AppLocalizationsEn();
      default:
        return AppLocalizationsBs();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

