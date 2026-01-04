import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/theme/app_theme.dart';
import 'package:gemura/features/suppliers/domain/models/supplier.dart';
import 'package:gemura/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:intl/intl.dart';

class SupplierDetailsScreen extends ConsumerWidget {
  final Supplier supplier;

  const SupplierDetailsScreen({
    super.key,
    required this.supplier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(supplier.name),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // TODO: Navigate to edit supplier screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit supplier coming soon!'),
                      backgroundColor: AppTheme.snackbarInfoColor,
                    ),
                  );
                  break;
                case 'delete':
                  _showDeleteConfirmation(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supplier Header Card
            _buildHeaderCard(),
            const SizedBox(height: AppTheme.spacing16),
            
            // Contact Information
            _buildSectionTitle('Contact Information'),
            const SizedBox(height: AppTheme.spacing8),
            _buildContactInfo(),
            const SizedBox(height: AppTheme.spacing16),
            
            // Business Information
            _buildSectionTitle('Business Information'),
            const SizedBox(height: AppTheme.spacing8),
            _buildBusinessInfo(),
            const SizedBox(height: AppTheme.spacing16),
            
            // Production Metrics
            _buildSectionTitle('Production Metrics'),
            const SizedBox(height: AppTheme.spacing8),
            _buildMetricsCard(),
            const SizedBox(height: AppTheme.spacing16),
            
            // Business Insights
            _buildSectionTitle('Business Insights'),
            const SizedBox(height: AppTheme.spacing8),
            _buildBusinessInsightsCard(),
            const SizedBox(height: AppTheme.spacing16),
            
            // Financial Tracking
            _buildSectionTitle('Financial Tracking'),
            const SizedBox(height: AppTheme.spacing8),
            _buildFinancialTrackingCard(),
            const SizedBox(height: AppTheme.spacing16),
            
            // Payment Information
            _buildSectionTitle('Payment Information'),
            const SizedBox(height: AppTheme.spacing8),
            _buildPaymentInfo(),
            const SizedBox(height: AppTheme.spacing16),
            
            // Additional Information
            if (supplier.notes != null) ...[
              _buildSectionTitle('Notes'),
              const SizedBox(height: AppTheme.spacing8),
              _buildNotesCard(),
              const SizedBox(height: AppTheme.spacing16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : 'S',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.name,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  supplier.businessType,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: supplier.isActive 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    supplier.isActive ? 'Active' : 'Inactive',
                    style: AppTheme.bodySmall.copyWith(
                      color: supplier.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildContactInfo() {
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
        children: [
          _buildInfoRow(Icons.phone, 'Phone', supplier.phone),
          if (supplier.email != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(Icons.email, 'Email', supplier.email!),
          ],
          const SizedBox(height: AppTheme.spacing12),
          _buildInfoRow(Icons.location_on, 'Location', supplier.location),
        ],
      ),
    );
  }

  Widget _buildBusinessInfo() {
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
        children: [
          _buildInfoRow(Icons.business, 'Business Type', supplier.businessType),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfoRow(Icons.agriculture, 'Farm Type', supplier.farmType),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfoRow(Icons.schedule, 'Collection Schedule', supplier.collectionSchedule),
          if (supplier.idNumber != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(Icons.badge, 'ID Number', supplier.idNumber!),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    // Calculate additional metrics
    final dailyValue = supplier.dailyProduction * supplier.sellingPricePerLiter;
    final monthlyValue = dailyValue * 30;
    final qualityGrade = supplier.qualityGrades;
    
    // Number formatter for currency
    final currencyFormatter = NumberFormat('#,###', 'en_US');
    
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
        children: [
          // First row of metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Cattle Count',
                  '${supplier.cattleCount}',
                  Icons.pets,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.thinBorderColor,
              ),
              Expanded(
                child: _buildMetricItem(
                  'Daily Production',
                  '${supplier.dailyProduction}L',
                  Icons.local_shipping,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.thinBorderColor,
              ),
              Expanded(
                child: _buildMetricItem(
                  'Price per Liter',
                  '${supplier.sellingPricePerLiter.toStringAsFixed(0)} Frw',
                  Icons.attach_money,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            width: double.infinity,
            height: 1,
            color: AppTheme.thinBorderColor,
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Second row of metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Daily Value',
                  '${currencyFormatter.format(dailyValue)} Frw',
                  Icons.trending_up,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.thinBorderColor,
              ),
              Expanded(
                child: _buildMetricItem(
                  'Monthly Value',
                  '${currencyFormatter.format(monthlyValue)} Frw',
                  Icons.calendar_today,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.thinBorderColor,
              ),
              Expanded(
                child: _buildMetricItem(
                  'Quality Grade',
                  qualityGrade,
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 32,
        ),
                          const SizedBox(height: AppTheme.spacing8),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing2),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBusinessInsightsCard() {
    // Calculate business insights
    final dailyValue = supplier.dailyProduction * supplier.sellingPricePerLiter;
    final weeklyValue = dailyValue * 7;
    final monthlyValue = dailyValue * 30;
    final yearlyValue = dailyValue * 365;
    final productionPerCattle = supplier.cattleCount > 0 
        ? supplier.dailyProduction / supplier.cattleCount 
        : 0.0;
    
    // Number formatter for currency
    final currencyFormatter = NumberFormat('#,###', 'en_US');
    
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
        children: [
          _buildInsightRow(
            'Weekly Revenue',
            '${currencyFormatter.format(weeklyValue)} Frw',
            Icons.trending_up,
            AppTheme.successColor,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildInsightRow(
            'Monthly Revenue',
            '${currencyFormatter.format(monthlyValue)} Frw',
            Icons.calendar_month,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildInsightRow(
            'Yearly Revenue',
            '${currencyFormatter.format(yearlyValue)} Frw',
            Icons.calendar_today,
            AppTheme.warningColor,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildInsightRow(
            'Production per Cattle',
            '${productionPerCattle.toStringAsFixed(1)}L/day',
            Icons.analytics,
            AppTheme.snackbarInfoColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTrackingCard() {
    // Mock data for financial tracking (in real app, this would come from database)
    final totalSupplied = supplier.dailyProduction * 30; // Last 30 days
    final totalValue = totalSupplied * supplier.sellingPricePerLiter;
    final amountPaid = totalValue * 0.7; // 70% paid
    final amountPending = totalValue - amountPaid;
    final lastPaymentDate = DateTime.now().subtract(const Duration(days: 5));
    final nextPaymentDate = DateTime.now().add(const Duration(days: 2));
    
    // Number formatter for currency
    final currencyFormatter = NumberFormat('#,###', 'en_US');
    final dateFormatter = DateFormat('MMM dd, yyyy');
    
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
        children: [
          _buildFinancialRow(
            'Total Supplied (30 days)',
            '${totalSupplied.toStringAsFixed(0)}L',
            Icons.local_shipping,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildFinancialRow(
            'Total Value',
            '${currencyFormatter.format(totalValue)} Frw',
            Icons.attach_money,
            AppTheme.successColor,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildFinancialRow(
            'Amount Paid',
            '${currencyFormatter.format(amountPaid)} Frw',
            Icons.check_circle,
            AppTheme.successColor,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildFinancialRow(
            'Amount Pending',
            '${currencyFormatter.format(amountPending)} Frw',
            Icons.pending,
            AppTheme.warningColor,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildFinancialRow(
            'Last Payment',
            dateFormatter.format(lastPaymentDate),
            Icons.history,
            AppTheme.snackbarInfoColor,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildFinancialRow(
            'Next Payment',
            dateFormatter.format(nextPaymentDate),
            Icons.schedule,
            AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
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
        children: [
          _buildInfoRow(Icons.payment, 'Payment Method', supplier.paymentMethod),
          if (supplier.bankAccount != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(Icons.account_balance, 'Bank Account', supplier.bankAccount!),
          ],
          if (supplier.mobileMoneyNumber != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(Icons.phone_android, 'Mobile Money', supplier.mobileMoneyNumber!),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
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
              child: Text(
          supplier.notes!,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textPrimaryColor,
          ),
        ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                value,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete "${supplier.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(supplierProvider.notifier).deleteSupplier(supplier.id);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Supplier "${supplier.name}" deleted'),
                  backgroundColor: AppTheme.snackbarSuccessColor,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 