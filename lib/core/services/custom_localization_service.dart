import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomLocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _englishCode = 'en';
  static const String _kinyarwandaCode = 'rw';
  
  static const Locale englishLocale = Locale('en', 'US');
  static const Locale kinyarwandaLocale = Locale('rw', 'RW');
  
  static const List<Locale> supportedLocales = [
    kinyarwandaLocale, // Kinyarwanda first as default
    englishLocale,
  ];
  
  Locale _currentLocale = kinyarwandaLocale; // Default to Kinyarwanda
  Map<String, dynamic> _translations = {};
  bool _isLoaded = false;
  
  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  bool get isEnglish => currentLanguageCode == _englishCode;
  bool get isKinyarwanda => currentLanguageCode == _kinyarwandaCode;
  bool get isLoaded => _isLoaded;
  
  CustomLocalizationService() {
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null && (savedLanguage == _englishCode || savedLanguage == _kinyarwandaCode)) {
        _currentLocale = _getLocaleFromCode(savedLanguage);
      } else {
        // Default to Kinyarwanda
        _currentLocale = kinyarwandaLocale;
        await prefs.setString(_languageKey, _kinyarwandaCode);
      }
      
      await _loadTranslations();
      notifyListeners();
      print('🌍 CustomLocalizationService: Loaded locale ${_currentLocale.languageCode}');
    } catch (e) {
      // If there's an error loading saved language, use Kinyarwanda as default
      _currentLocale = kinyarwandaLocale;
      await _loadTranslations();
      notifyListeners();
      print('🌍 CustomLocalizationService: Error loading language, using Kinyarwanda default');
    }
  }
  
  Future<void> _loadTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/translations/${currentLanguageCode}.json',
      );
      _translations = json.decode(jsonString) as Map<String, dynamic>;
      _isLoaded = true;
    } catch (e) {
      print('🌍 CustomLocalizationService: Error loading translations: $e');
      _isLoaded = false;
    }
  }
  
  String translate(String key, {List<String>? args}) {
    if (!_isLoaded) {
      return key; // Return key if translations not loaded
    }
    
    String translation = _translations[key] ?? key;
    
    // Handle arguments if provided
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        translation = translation.replaceAll('{$i}', args[i]);
      }
    }
    
    return translation;
  }
  
  Future<void> setLanguage(String languageCode) async {
    if (currentLanguageCode == languageCode) return;
    
    _currentLocale = _getLocaleFromCode(languageCode);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      await _loadTranslations();
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
        return kinyarwandaLocale; // Default to Kinyarwanda
    }
  }
  
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case _englishCode:
        return 'English';
      case _kinyarwandaCode:
        return 'Ikinyarwanda';
      default:
        return 'Ikinyarwanda'; // Default to Kinyarwanda
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
          return 'Ikinyarwanda';
      }
    } else {
      return getLanguageName(languageCode);
    }
  }
}
