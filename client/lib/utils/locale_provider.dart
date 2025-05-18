import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _localeKey = 'locale_code';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);
      
      if (savedLocale != null) {
        _locale = Locale(savedLocale);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  static List<Locale> get supportedLocales => const [
    Locale('en'), // English only
  ];
}
