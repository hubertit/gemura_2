import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/localization_service.dart';

final localizationServiceProvider = ChangeNotifierProvider<LocalizationService>((ref) {
  return LocalizationService();
});

final currentLocaleProvider = Provider<Locale>((ref) {
  final localizationService = ref.watch(localizationServiceProvider);
  return localizationService.currentLocale;
});

final isEnglishProvider = Provider<bool>((ref) {
  final localizationService = ref.watch(localizationServiceProvider);
  return localizationService.isEnglish;
});

final isKinyarwandaProvider = Provider<bool>((ref) {
  final localizationService = ref.watch(localizationServiceProvider);
  return localizationService.isKinyarwanda;
});
