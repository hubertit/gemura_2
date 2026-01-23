import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class ArApSummaryWidget extends StatelessWidget {
  final double? totalReceivables;
  final double? totalPayables;
  final VoidCallback? onReceivablesTap;
  final VoidCallback? onPayablesTap;

  const ArApSummaryWidget({
    super.key,
    this.totalReceivables,
    this.totalPayables,
    this.onReceivablesTap,
    this.onPayablesTap,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Accounts Receivable',
            amount: totalReceivables ?? 0.0,
            color: AppTheme.successColor,
            icon: Icons.arrow_downward_rounded,
            onTap: onReceivablesTap,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: _buildSummaryCard(
            label: 'Accounts Payable',
            amount: totalPayables ?? 0.0,
            color: AppTheme.warningColor,
            icon: Icons.arrow_upward_rounded,
            onTap: onPayablesTap,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
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
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              '${_formatAmount(amount)} RWF',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
