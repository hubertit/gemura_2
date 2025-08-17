import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../../core/providers/localization_provider.dart';
import '../../../../core/theme/app_theme.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  void _changeLanguageAndRestart(WidgetRef ref, String language) {
    final localizationService = ref.read(localizationServiceProvider);
    
    if (language == 'kinyarwanda') {
      localizationService.setKinyarwanda();
    } else {
      localizationService.setEnglish();
    }
    
    // Show a brief snackbar to indicate the change
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Text('Language changed to $language. Restarting app...'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Restart the app after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (Platform.isAndroid || Platform.isIOS) {
        SystemNavigator.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizationService = ref.watch(localizationServiceProvider);
    final isEnglish = ref.watch(isEnglishProvider);
    final isKinyarwanda = ref.watch(isKinyarwandaProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizationService.translate('language'),
          style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kinyarwanda Option (Default)
            _LanguageOption(
              title: 'Ikinyarwanda',
              subtitle: 'Kinyarwanda',
              isSelected: isKinyarwanda,
              onTap: () => _changeLanguageAndRestart(ref, 'kinyarwanda'),
              flag: '🇷🇼',
            ),
            
            const SizedBox(height: 16),
            
            // English Option
            _LanguageOption(
              title: localizationService.translate('english'),
              subtitle: 'English',
              isSelected: isEnglish,
              onTap: () => _changeLanguageAndRestart(ref, 'english'),
              flag: '🇺🇸',
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final String flag;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.flag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.thinBorderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
