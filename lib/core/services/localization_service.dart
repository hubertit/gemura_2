import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _englishCode = 'en';
  static const String _kinyarwandaCode = 'rw';
  
  static const Locale englishLocale = Locale('en', 'US');
  static const Locale kinyarwandaLocale = Locale('rw', 'RW');
  
  static const List<Locale> supportedLocales = [
    englishLocale,
    kinyarwandaLocale,
  ];
  
  Locale _currentLocale = englishLocale;
  
  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageCode => _currentLocale.languageCode;
  
  bool get isEnglish => currentLanguageCode == _englishCode;
  bool get isKinyarwanda => currentLanguageCode == _kinyarwandaCode;
  
  LocalizationService() {
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null) {
        _currentLocale = _getLocaleFromCode(savedLanguage);
        notifyListeners();
      }
    } catch (e) {
      // If there's an error loading saved language, use English as default
      _currentLocale = englishLocale;
    }
  }
  
  Future<void> setLanguage(String languageCode) async {
    if (currentLanguageCode == languageCode) return;
    
    _currentLocale = _getLocaleFromCode(languageCode);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      // Handle error saving language preference
    }
    
    notifyListeners();
  }
  
  Future<void> setEnglish() async {
    await setLanguage(_englishCode);
  }
  
  Future<void> setKinyarwanda() async {
    await setLanguage(_kinyarwandaCode);
  }
  
  Locale _getLocaleFromCode(String languageCode) {
    switch (languageCode) {
      case _englishCode:
        return englishLocale;
      case _kinyarwandaCode:
        return kinyarwandaLocale;
      default:
        return englishLocale;
    }
  }
  
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case _englishCode:
        return 'English';
      case _kinyarwandaCode:
        return 'Ikinyarwanda';
      default:
        return 'English';
    }
  }
  
  String getLanguageNameInCurrentLanguage(String languageCode) {
    if (isKinyarwanda) {
      switch (languageCode) {
        case _englishCode:
          return 'Icyongereza';
        case _kinyarwandaCode:
          return 'Ikinyarwanda';
        default:
          return 'Icyongereza';
      }
    } else {
      return getLanguageName(languageCode);
    }
  }
}
