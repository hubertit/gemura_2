import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/insurance_policy.dart';
import '../../../../shared/widgets/status_badge.dart';

class InsuranceCard extends StatelessWidget {
  final InsurancePolicy policy;
  final VoidCallback? onTap;

  const InsuranceCard({
    super.key,
    required this.policy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.name,
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        policy.providerName,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  status: policy.statusDisplayName,
                  color: policy.statusColor,
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacing12),
            
            // Policy Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Type',
                    policy.typeDisplayName,
                    Icons.category,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: _buildDetailItem(
                    'Premium',
                    'RWF ${NumberFormat('#,##0', 'en_US').format(policy.premiumAmount)}',
                    Icons.payment,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacing8),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Coverage',
                    'RWF ${NumberFormat('#,##0', 'en_US').format(policy.coverageAmount)}',
                    Icons.security,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: _buildDetailItem(
                    'Frequency',
                    policy.paymentFrequencyDisplayName,
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacing12),
            
            // Progress Bar
            if (policy.status == PolicyStatus.active) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Policy Progress',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${policy.progressPercentage.toStringAsFixed(1)}%',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  LinearProgressIndicator(
                    value: policy.progressPercentage / 100,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
            ],
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expires',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(policy.endDate),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                if (policy.daysUntilExpiry > 0 && policy.daysUntilExpiry <= 30)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8,
                      vertical: AppTheme.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.3),
                        width: AppTheme.thinBorderWidth,
                      ),
                    ),
                    child: Text(
                      '${policy.daysUntilExpiry} days left',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: AppTheme.spacing4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing2),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
} 