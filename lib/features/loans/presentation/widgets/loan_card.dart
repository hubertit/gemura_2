import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/loan.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback? onTap;

  const LoanCard({
    super.key,
    required this.loan,
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
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.name,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        loan.typeDisplayName,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: loan.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  ),
                  child: Text(
                    loan.statusDisplayName,
                    style: AppTheme.bodySmall.copyWith(
                      color: loan.statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacing12),
            
            // Amount and Progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${NumberFormat('#,##0', 'en_US').format(loan.amount.toInt())} RWF',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        '${loan.interestRate.toStringAsFixed(1)}% interest',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${loan.progressPercentage.toStringAsFixed(1)}%',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      '${loan.termInMonths} months',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacing12),
            
            // Progress Bar
            LinearProgressIndicator(
              value: loan.progressPercentage / 100,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                loan.isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
              ),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            
            const SizedBox(height: AppTheme.spacing12),
            
            // Footer Row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(loan.dueDate)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                if (loan.isOverdue)
                  Text(
                    '${loan.daysRemaining} days overdue',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (loan.status == LoanStatus.active)
                  Text(
                    '${loan.daysRemaining} days left',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
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