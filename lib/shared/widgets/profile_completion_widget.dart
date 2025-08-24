import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/user.dart';
import '../../features/home/presentation/screens/edit_profile_screen.dart';

class ProfileCompletionWidget extends StatelessWidget {
  final User user;

  const ProfileCompletionWidget({
    Key? key,
    required this.user,
  }) : super(key: key);

  Color _getCompletionColor(double percentage) {
    if (percentage >= 90) return AppTheme.successColor;
    if (percentage >= 70) return AppTheme.warningColor;
    if (percentage >= 50) return AppTheme.infoColor;
    return AppTheme.errorColor;
  }

  IconData _getCompletionIcon(double percentage) {
    if (percentage >= 90) return Icons.check_circle;
    if (percentage >= 70) return Icons.warning;
    if (percentage >= 50) return Icons.info;
    return Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = user.profileCompletionPercentage;
    final status = user.profileCompletionStatus;
    final color = _getCompletionColor(percentage);
    final icon = _getCompletionIcon(percentage);

    return GestureDetector(
      onTap: () {
        // Only navigate to edit profile if completion is low
        if (percentage < 70) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const EditProfileScreen(),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
        color: percentage < 70 ? AppTheme.surfaceColor : AppTheme.surfaceColor.withOpacity(0.8),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    'Profile Completion',
                    style: AppTheme.titleMedium,
                  ),
                  if (percentage >= 70)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing4,
                      vertical: AppTheme.spacing2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      status,
                      style: AppTheme.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11, // Reduced from 14 to 11 (about 50% smaller)
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}% Complete',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppTheme.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacing16),
              
              // KYC Status
              if (user.kycStatus != null)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: _getKycStatusColor(user.kycStatus!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    border: Border.all(
                      color: _getKycStatusColor(user.kycStatus!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getKycStatusIcon(user.kycStatus!),
                        color: _getKycStatusColor(user.kycStatus!),
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KYC Status',
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _getKycStatusText(user.kycStatus!),
                              style: AppTheme.bodyMedium.copyWith(
                                color: _getKycStatusColor(user.kycStatus!),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getKycStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getKycStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getKycStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Under Review';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Not Submitted';
    }
  }
}
