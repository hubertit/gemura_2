import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../models/transaction.dart';
import 'status_badge.dart';
import 'layout_widgets.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  Color getAmountColor() {
    if (transaction.type == 'income') return AppTheme.successColor;
    if (transaction.type == 'expense' || transaction.type == 'refund') return AppTheme.errorColor;
    return AppTheme.textPrimaryColor;
  }

  IconData getTypeIcon() {
    switch (transaction.type) {
      case 'income':
        return Icons.arrow_downward_rounded;
      case 'expense':
        return Icons.arrow_upward_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  IconData getMethodIcon() {
    switch (transaction.paymentMethod.toLowerCase()) {
      case 'mobile money':
        return Icons.phone_iphone_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'qr/ussd':
        return Icons.qr_code_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          isScrollControlled: true,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _TransactionDetailsSheet(transaction: transaction),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8, horizontal: AppTheme.spacing12),
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: getAmountColor().withOpacity(0.12),
              radius: 16,
              child: Icon(getMethodIcon(), color: getAmountColor(), size: 16),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description.isNotEmpty ? transaction.description : transaction.reference,
                    style: AppTheme.bodySmall.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    transaction.paymentMethod,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor, fontSize: 12),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    _formatDate(transaction.date),
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.type == 'refund' || transaction.type == 'expense' ? '-' : '+'}${formatAmount(transaction.amount)} ${transaction.currency}',
                  style: AppTheme.bodySmall.copyWith(
                    color: getAmountColor(),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                StatusBadge(status: transaction.status, color: _statusColor(transaction.status)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple date formatting (e.g., 2024-06-01)
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'failed':
        return AppTheme.errorColor;
      case 'refunded':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }
}

// Transaction Details Sheet using the reusable component
class _TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;

  const _TransactionDetailsSheet({required this.transaction});

  Color getAmountColor() {
    if (transaction.type == 'income') return AppTheme.successColor;
    if (transaction.type == 'expense' || transaction.type == 'refund') return AppTheme.errorColor;
    return AppTheme.textPrimaryColor;
  }

  IconData getMethodIcon() {
    switch (transaction.paymentMethod.toLowerCase()) {
      case 'mobile money':
        return Icons.phone_iphone_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'failed':
        return AppTheme.errorColor;
      case 'refunded':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month ${date.day} ${date.year} at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return DetailsActionSheet(
      title: 'Transaction Details',
      headerWidget: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: getAmountColor().withOpacity(0.12),
            child: Icon(getMethodIcon(), color: getAmountColor(), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            '${transaction.type == 'refund' || transaction.type == 'expense' ? '-' : '+'}${formatAmount(transaction.amount)} ${transaction.currency}',
            style: AppTheme.headlineLarge.copyWith(
              color: getAmountColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(transaction.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _statusColor(transaction.status).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              transaction.status.toUpperCase(),
              style: AppTheme.badge.copyWith(
                color: _statusColor(transaction.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      details: [
        DetailRow(label: 'To', value: transaction.customerName),
        DetailRow(label: 'Account number', value: transaction.customerPhone),
        DetailRow(label: 'Payment method', value: transaction.paymentMethod),
        DetailRow(label: 'Description', value: transaction.description.isNotEmpty ? transaction.description : 'Mobile wallet transfer'),
        DetailRow(label: 'Date', value: _formatDateTime(transaction.date)),
        DetailRow(label: 'Reference', value: transaction.reference),
      ],
    );
  }
} 