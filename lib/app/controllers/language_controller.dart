import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends GetxController {
  static LanguageController get instance => Get.find();

  final _localStorage = GetStorage();
  final String _storageKey = 'language';

  // Available locales
  final List<Locale> supportedLocales = [
    const Locale('en', 'US'), // English
    const Locale('ar'), // Arabic
    const Locale('fr', 'FR'), // French
  ];

  // Get the current locale
  Locale get currentLocale {
    String? languageCode = _localStorage.read(_storageKey);
    String? countryCode;

    if (languageCode != null) {
      if (languageCode == 'en') {
        countryCode = 'US';
      } else if (languageCode == 'fr') {
        countryCode = 'FR';
      }

      return Locale(languageCode, countryCode);
    }

    return const Locale('en', 'US'); // Default is English
  }

  // Change the language and save to storage
  void changeLanguage(String languageCode, String? countryCode) {
    Locale locale = Locale(languageCode, countryCode);

    // Save to storage
    _localStorage.write(_storageKey, languageCode);

    // Update the UI
    Get.updateLocale(locale);

    // Force UI refresh
    update();
  }

  // Initialize the language on app start
  void initLanguage() {
    Get.updateLocale(currentLocale);
  }
}
