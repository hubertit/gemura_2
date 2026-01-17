import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/referral_provider.dart';

class PointsBalanceScreen extends ConsumerStatefulWidget {
  const PointsBalanceScreen({super.key});

  @override
  ConsumerState<PointsBalanceScreen> createState() => _PointsBalanceScreenState();
}

class _PointsBalanceScreenState extends ConsumerState<PointsBalanceScreen> {
  @override
  void initState() {
    super.initState();
    // Load points balance when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pointsBalanceProvider.notifier).getPointsBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(pointsBalanceProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Points Balance',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: balanceState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : balanceState.error != null
              ? _buildErrorState(balanceState.error!)
              : balanceState.balance != null
                  ? _buildBalanceContent(balanceState.balance!)
                  : const Center(
                      child: Text('No data available'),
                    ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Error Loading Balance',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              error,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: () {
                ref.read(pointsBalanceProvider.notifier).getPointsBalance();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceContent(balance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Overview Card
          _buildPointsOverviewCard(balance.userInfo),
          
          const SizedBox(height: AppTheme.spacing24),
          
          // Points Breakdown
          if (balance.pointsBreakdown.isNotEmpty) ...[
            _buildPointsBreakdown(balance.pointsBreakdown),
            const SizedBox(height: AppTheme.spacing24),
          ],
          
          // Recent Activities
          if (balance.recentActivities.isNotEmpty) ...[
            _buildRecentActivities(balance.recentActivities),
          ],
        ],
      ),
    );
  }

  Widget _buildPointsOverviewCard(userInfo) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
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
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                'Your Points Balance',
                style: AppTheme.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing24),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Points',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      '${userInfo.availablePoints}',
                      style: AppTheme.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Points',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '${userInfo.totalPoints}',
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Referrals',
                  userInfo.referralCount.toString(),
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Onboarded',
                  userInfo.onboardedCount.toString(),
                  Icons.person_add,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rank',
                  '#${userInfo.leaderboardPosition}',
                  Icons.emoji_events,
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
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsBreakdown(pointsBreakdown) {
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
            'Points Breakdown',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          
          ...pointsBreakdown.map<Widget>((breakdown) => _buildBreakdownItem(breakdown)).toList(),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(breakdown) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: _getSourceColor(breakdown.source).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: Icon(
              _getSourceIcon(breakdown.source),
              color: _getSourceColor(breakdown.source),
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breakdown.source.toUpperCase(),
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  '${breakdown.activities} activities',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${breakdown.points} pts',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: _getSourceColor(breakdown.source),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(recentActivities) {
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
            'Recent Activities',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          
          ...recentActivities.map<Widget>((activity) => _buildActivityItem(activity)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: _getSourceColor(activity.source).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: Icon(
              _getSourceIcon(activity.source),
              color: _getSourceColor(activity.source),
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  '${activity.source.toUpperCase()} • ${_formatDate(activity.date)}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${activity.points}',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'referral':
        return AppTheme.primaryColor;
      case 'onboarding':
        return Colors.green;
      case 'bonus':
        return Colors.orange;
      case 'reward':
        return Colors.purple;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source.toLowerCase()) {
      case 'referral':
        return Icons.people;
      case 'onboarding':
        return Icons.person_add;
      case 'bonus':
        return Icons.card_giftcard;
      case 'reward':
        return Icons.stars;
      default:
        return Icons.star;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'now';
      }
    } catch (e) {
      return dateString;
    }
  }
}
