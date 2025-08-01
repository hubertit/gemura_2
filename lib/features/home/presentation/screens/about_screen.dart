import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: AppTheme.primaryColor),
                  const SizedBox(height: 24),
                  Text('Gemura', style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Gemura helps you manage your finances, track transactions, and stay in control. Secure, simple, and built for you.',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Version 1.0.0', style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('© ${DateTime.now().year} Gemura', style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Powered by RWANDA ICT Chamber', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 