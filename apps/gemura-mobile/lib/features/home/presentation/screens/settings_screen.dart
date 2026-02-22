import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'edit_profile_screen.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/providers/localization_provider.dart';
import '../../../settings/presentation/screens/language_selection_screen.dart';
import '../../../invite/presentation/screens/invite_people_screen.dart';

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizationService = ref.watch(localizationServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizationService.translate('settings')),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(localizationService.translate('editProfile'), style: AppTheme.bodyMedium),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(localizationService.translate('changePassword'), style: AppTheme.bodyMedium),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implement ChangePasswordScreen
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(Icons.person_add, color: AppTheme.primaryColor),
              title: Text('Invite People', style: AppTheme.bodyMedium),
              subtitle: Text('Share Gemura with friends and earn rewards', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InvitePeopleScreen(),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(localizationService.translate('notifications'), style: AppTheme.bodyMedium),
                  trailing: Consumer(
                    builder: (context, ref, _) {
                      final enabled = ref.watch(notificationsEnabledProvider);
                      return Switch(
                        value: enabled,
                        onChanged: (val) => ref.read(notificationsEnabledProvider.notifier).state = val,
                        activeColor: AppTheme.primaryColor,
                        inactiveThumbColor: AppTheme.errorColor.withOpacity(0.7),
                        inactiveTrackColor: AppTheme.errorColor.withOpacity(0.3),
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(localizationService.translate('language'), style: AppTheme.bodyMedium),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LanguageSelectionScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(localizationService.translate('about'), style: AppTheme.bodyMedium),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Gemura',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 Gemura',
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: AppTheme.errorColor),
              title: Text(localizationService.translate('logout'), style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor)),
              onTap: () async {
                // TODO: Implement logout logic
              },
            ),
          ),
        ],
      ),
    );
  }
} 