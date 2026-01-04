import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InsuranceStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const InsuranceStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insurance Overview',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Policies',
                  '${stats['totalPolicies']}',
                  Icons.policy,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _buildStatItem(
                  'Active',
                  '${stats['activePolicies']}',
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing8),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Pending',
                  '${stats['pendingPolicies']}',
                  Icons.schedule,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _buildStatItem(
                  'Expired',
                  '${stats['expiredPolicies']}',
                  Icons.warning,
                  AppTheme.errorColor,
                ),
              ),
            ],
          ),
          

          
          if (stats['policiesNeedingRenewal'] > 0) ...[
            const SizedBox(height: AppTheme.spacing8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                  width: AppTheme.thinBorderWidth,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notification_important,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      '${stats['policiesNeedingRenewal']} policies need renewal',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


} 