import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/referral_provider.dart';
import 'referral_stats_screen.dart';
import 'points_balance_screen.dart';
import 'onboard_user_screen.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    // Load referral code when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(referralCodeProvider.notifier).getReferralCode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final referralCodeState = ref.watch(referralCodeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Referrals & Rewards',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Referral Code Section
            _buildReferralCodeSection(referralCodeState),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Quick Actions
            _buildQuickActions(),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Stats Overview
            _buildStatsOverview(referralCodeState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.card_giftcard,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Earn Points & Rewards',
            style: AppTheme.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Refer friends and onboard users to earn points and unlock rewards',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection(ReferralCodeState state) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.share,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Your Referral Code',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          
          if (state.isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          else if (state.error != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: AppTheme.bodySmall.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            )
          else if (state.referralCode != null)
            Column(
              children: [
                // Referral Code Display
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        state.referralCode!.referralCode,
                        style: AppTheme.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Share this code with friends',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacing16),
                
                // Copy Button
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    onPressed: () => _copyReferralCode(state.referralCode!.referralCode),
                    label: 'Copy Referral Code',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'View Stats',
                subtitle: 'Track your referrals',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReferralStatsScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.account_balance_wallet,
                title: 'Points Balance',
                subtitle: 'Check your rewards',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PointsBalanceScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacing12),
        
        SizedBox(
          width: double.infinity,
          child: _buildActionCard(
            icon: Icons.person_add,
            title: 'Onboard User',
            subtitle: 'Directly register someone',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OnboardUserScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(ReferralCodeState state) {
    if (state.referralCode == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Performance',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Referrals',
                  state.referralCode!.totalReferrals.toString(),
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Points',
                  state.referralCode!.totalPoints.toString(),
                  Icons.stars,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          value,
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _copyReferralCode(String code) {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code copied: $code'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
