import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../services/custom_localization_service.dart';

final localizationServiceProvider = ChangeNotifierProvider<CustomLocalizationService>((ref) {
  return CustomLocalizationService();
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

final isTranslationsLoadedProvider = Provider<bool>((ref) {
  final localizationService = ref.watch(localizationServiceProvider);
  return localizationService.isLoaded;
});
