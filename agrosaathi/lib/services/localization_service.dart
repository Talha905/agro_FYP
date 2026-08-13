import 'package:flutter/foundation.dart';
import '../constants/app_translations.dart';
import 'user_service.dart';

/// Centralized localization service allowing instant language switching
/// between English ('en'), Hindi ('hi'), and Marathi ('mr').
class LocalizationService {
  static final ValueNotifier<String> currentLocale = ValueNotifier<String>('en');

  static void init() {
    final userLang = UserService.currentUser?.preferredLanguage.toLowerCase();
    if (userLang == 'hindi' || userLang == 'hi') {
      currentLocale.value = 'hi';
    } else if (userLang == 'marathi' || userLang == 'mr') {
      currentLocale.value = 'mr';
    } else {
      currentLocale.value = 'en';
    }
  }

  static void setLocale(String langCode) {
    if (['en', 'hi', 'mr'].contains(langCode)) {
      currentLocale.value = langCode;
    }
  }

  static String tr(String key) {
    return AppTranslations.get(key, lang: currentLocale.value);
  }

  static String getLanguageName(String code) {
    switch (code) {
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'mr':
        return 'मराठी (Marathi)';
      case 'en':
      default:
        return 'English';
    }
  }
}
