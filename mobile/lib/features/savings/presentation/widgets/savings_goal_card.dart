import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/savings_goal.dart';

class SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onAddMoney;
  final VoidCallback? onTap;

  const SavingsGoalCard({
    super.key,
    required this.goal,
    required this.onAddMoney,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercentage.clamp(0.0, 100.0);
    final isCompleted = progress >= 100;
    final isOverdue = goal.daysRemaining < 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: AppTheme.spacing16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          color: AppTheme.surfaceColor,
          border: Border.all(
              color: AppTheme.thinBorderColor, 
              width: AppTheme.thinBorderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.savings,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      if (goal.description.isNotEmpty)
                        Text(
                          goal.description,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    margin: const EdgeInsets.only(right: AppTheme.spacing8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8,
                      vertical: AppTheme.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    child: Text(
                      'Completed',
                      style: AppTheme.badge.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: onAddMoney,
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  tooltip: 'Add Money',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Progress Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing8),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : AppTheme.primaryColor,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Amount and Date Section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        NumberFormat('#,##0', 'en_US').format(goal.currentAmount.toInt()) + ' ${goal.currency}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        NumberFormat('#,##0', 'en_US').format(goal.targetAmount.toInt()) + ' ${goal.currency}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Days Left',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        goal.daysRemaining.toString(),
                        style: AppTheme.bodySmall.copyWith(
                          color: isOverdue ? Colors.red : AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            

          ],
        ),
      ),
    );
  }
} 