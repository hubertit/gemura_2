import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/loan.dart';
import 'loan_payment_screen.dart';
import '../widgets/repayment_history_widget.dart';

class LoanDetailsScreen extends ConsumerWidget {
  final Loan loan;

  const LoanDetailsScreen({
    super.key,
    required this.loan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Loan Details'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
        ),
        actions: [
          if (loan.status == LoanStatus.pending)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Loan',
              onPressed: () {
                // TODO: Implement edit functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.infoSnackBar(message: 'Edit functionality coming soon!'),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          // Loan Card
          _buildLoanCard(),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Progress Section
          _buildProgressSection(),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Loan Details
          _buildLoanDetails(),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Guarantors Section
          _buildGuarantorsSection(),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Collateral Section (if applicable)
          if (loan.collateral != null) ...[
            _buildCollateralSection(),
            const SizedBox(height: AppTheme.spacing16),
          ],
          
          // Repayment History Section
          RepaymentHistoryWidget(loanId: loan.id),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Actions Section
          _buildActionsSection(context),
        ],
      ),
    );
  }

  Widget _buildLoanCard() {
    return Container(
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.name,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
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
          
          const SizedBox(height: AppTheme.spacing16),
          
          Text(
            '${NumberFormat('#,##0', 'en_US').format(loan.amount.toInt())} RWF',
            style: AppTheme.headlineLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing8),
          
          Text(
            loan.description,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
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
          Text(
            'Progress',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  'Progress',
                  '${loan.progressPercentage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: _buildProgressItem(
                  'Days Left',
                  '${loan.daysRemaining}',
                  Icons.schedule,
                  loan.isOverdue ? AppTheme.errorColor : AppTheme.successColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          LinearProgressIndicator(
            value: loan.progressPercentage / 100,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              loan.isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetails() {
    return Container(
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
          Text(
            'Loan Details',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          _buildDetailRow('Interest Rate', '${loan.interestRate.toStringAsFixed(1)}%'),
          _buildDetailRow('Term', '${loan.termInMonths} months'),
          _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy').format(loan.startDate)),
          _buildDetailRow('Due Date', DateFormat('MMM dd, yyyy').format(loan.dueDate)),
          if (loan.monthlyPayment != null)
            _buildDetailRow('Monthly Payment', '${NumberFormat('#,##0', 'en_US').format(loan.monthlyPayment!.toInt())} RWF'),
          if (loan.totalRepayment != null)
            _buildDetailRow('Total Repayment', '${NumberFormat('#,##0', 'en_US').format(loan.totalRepayment!.toInt())} RWF'),
          if (loan.remainingBalance != null)
            _buildDetailRow('Remaining Balance', '${NumberFormat('#,##0', 'en_US').format(loan.remainingBalance!.toInt())} RWF'),
          if (loan.purpose != null)
            _buildDetailRow('Purpose', loan.purpose!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantorsSection() {
    return Container(
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
          Text(
            'Guarantors',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          ...loan.guarantors.map((guarantor) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    guarantor.isNotEmpty ? guarantor[0].toUpperCase() : 'G',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    guarantor,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCollateralSection() {
    return Container(
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
          Text(
            'Collateral',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          ...loan.collateral!.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
            child: _buildDetailRow(
              entry.key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
              entry.value.toString(),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Container(
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
          Text(
            'Actions',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          if (loan.status == LoanStatus.active || loan.status == LoanStatus.approved) ...[
            _buildActionButton(
              'Make Payment',
              Icons.payment,
              AppTheme.primaryColor,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LoanPaymentScreen(loan: loan),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing12),
          ],
          
          if (loan.status == LoanStatus.pending) ...[
            _buildActionButton(
              'Cancel Application',
              Icons.cancel,
              AppTheme.errorColor,
              () {
                // TODO: Implement cancel functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.infoSnackBar(message: 'Cancel functionality coming soon!'),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing12),
          ],
          
          _buildActionButton(
            'Download Statement',
            Icons.download,
            AppTheme.textSecondaryColor,
            () {
              // TODO: Implement download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                AppTheme.infoSnackBar(message: 'Download functionality coming soon!'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          border: Border.all(
            color: color.withOpacity(0.1),
            width: AppTheme.thinBorderWidth,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppTheme.spacing12),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
} 