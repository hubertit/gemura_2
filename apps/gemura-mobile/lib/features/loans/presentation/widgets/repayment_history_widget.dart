import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/loan_repayment.dart';
import '../providers/loans_provider.dart';

class RepaymentHistoryWidget extends ConsumerWidget {
  final String loanId;

  const RepaymentHistoryWidget({
    super.key,
    required this.loanId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repayments = ref.watch(loanRepaymentHistoryProvider(loanId));
    final totalRepaid = ref.watch(loanTotalRepaidProvider(loanId));

    if (repayments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.1),
            width: AppTheme.thinBorderWidth,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Repayment History',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Icon(
              Icons.history,
              size: 48,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'No repayment history yet',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Repayment History',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                child: Text(
                  '${repayments.length} payments',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Total Repaid Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              border: Border.all(
                color: AppTheme.thinBorderColor,
                width: AppTheme.thinBorderWidth,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Repaid',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        '${totalRepaid.toInt()} RWF',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Repayment List
          ...repayments.map((repayment) => _buildRepaymentItem(repayment)).toList(),
        ],
      ),
    );
  }

  Widget _buildRepaymentItem(LoanRepayment repayment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: _getStatusColor(repayment.status).withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(repayment.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getStatusIcon(repayment.status),
              size: 20,
              color: _getStatusColor(repayment.status),
            ),
          ),
          
          const SizedBox(width: AppTheme.spacing12),
          
          // Payment Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      repayment.formattedAmount,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Container(
                                             padding: const EdgeInsets.symmetric(
                         horizontal: 6,
                         vertical: AppTheme.spacing2,
                       ),
                       decoration: BoxDecoration(
                         color: _getStatusColor(repayment.status).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(4),
                       ),
                      child: Text(
                        repayment.statusDisplayName,
                        style: AppTheme.bodySmall.copyWith(
                          color: _getStatusColor(repayment.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spacing4),
                
                Text(
                  repayment.paymentMethodDisplayName,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacing2),
                
                Text(
                  '${repayment.formattedDate} at ${repayment.formattedTime}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RepaymentStatus status) {
    switch (status) {
      case RepaymentStatus.completed:
        return AppTheme.successColor;
      case RepaymentStatus.pending:
        return AppTheme.warningColor;
      case RepaymentStatus.failed:
        return AppTheme.errorColor;
    }
  }

  IconData _getStatusIcon(RepaymentStatus status) {
    switch (status) {
      case RepaymentStatus.completed:
        return Icons.check_circle;
      case RepaymentStatus.pending:
        return Icons.schedule;
      case RepaymentStatus.failed:
        return Icons.error;
    }
  }
} 