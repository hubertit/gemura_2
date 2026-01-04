import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const _FaqList(),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Contact Support'),
                  onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.infoSnackBar(message: 'Support contact coming soon!'),
      );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqList extends StatefulWidget {
  const _FaqList();
  @override
  State<_FaqList> createState() => _FaqListState();
}

class _FaqListState extends State<_FaqList> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How do I reset my password?',
        'a': 'Go to Settings > Change Password to reset your password.',
      },
      {
        'q': 'How do I contact support?',
        'a': 'Use the button below to contact our support team.',
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Frequently Asked Questions', style: AppTheme.titleMedium),
        const SizedBox(height: 16),
        ...List.generate(faqs.length, (i) => Column(
          children: [
            ExpansionTile(
              initiallyExpanded: _expandedIndex == i,
              onExpansionChanged: (expanded) {
                setState(() => _expandedIndex = expanded ? i : null);
              },
              title: Text(
                faqs[i]['q']!,
                style: AppTheme.bodyMedium.copyWith(
                  color: _expandedIndex == i ? AppTheme.primaryColor : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(faqs[i]['a']!, style: AppTheme.bodyMedium),
                ),
              ],
            ),
            if (i < faqs.length - 1)
              Divider(color: AppTheme.thinBorderColor, thickness: 1, height: 16),
          ],
        )),
      ],
    );
  }
} 