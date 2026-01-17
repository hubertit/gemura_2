import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class FinancialMetricsCard extends StatelessWidget {
  final double sales;
  final double expenses;
  final double profit;
  final String currency;
  final VoidCallback? onTap;

  const FinancialMetricsCard({
    super.key,
    required this.sales,
    required this.expenses,
    required this.profit,
    this.currency = 'RWF',
    this.onTap,
  });

  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentages
    final total = sales;
    final expensesPercent = total > 0 ? (expenses / total) * 100 : 0.0;
    final profitPercent = total > 0 ? (profit / total) * 100 : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          border: Border.all(
            color: AppTheme.thinBorderColor,
            width: AppTheme.thinBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  'Financial Overview',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Three equal metric cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Sales',
                    amount: sales,
                    currency: currency,
                    color: AppTheme.successColor,
                    icon: Icons.shopping_cart_rounded,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Expenses',
                    amount: expenses,
                    currency: currency,
                    color: AppTheme.warningColor,
                    icon: Icons.receipt_long_rounded,
                    percent: expensesPercent,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Profit',
                    amount: profit,
                    currency: currency,
                    color: AppTheme.primaryColor,
                    icon: Icons.account_balance_wallet_rounded,
                    percent: profitPercent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required double amount,
    required String currency,
    required Color color,
    required IconData icon,
    double? percent,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 12,
                ),
              ),
              const SizedBox(width: AppTheme.spacing4),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing4),
          // Amount
          Text(
            formatAmount(amount),
            style: AppTheme.titleSmall.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            currency,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textHintColor,
              fontSize: 10,
            ),
          ),
          // Percentage indicator (if provided)
          if (percent != null) ...[
            const SizedBox(height: AppTheme.spacing4),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (percent / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textHintColor,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
