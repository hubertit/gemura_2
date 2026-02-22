import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemura/core/theme/app_theme.dart';
import 'package:gemura/features/customers/domain/models/customer.dart';
import 'package:gemura/features/customers/presentation/providers/customer_provider.dart';
import 'package:gemura/shared/widgets/confirmation_dialog.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(customer.name),
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
                  // TODO: Navigate to edit customer screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit customer coming soon!'),
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
            // Customer Header Card
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
            
            // Payment Information
            _buildSectionTitle('Payment Information'),
            const SizedBox(height: AppTheme.spacing8),
            _buildPaymentInfo(),
            const SizedBox(height: AppTheme.spacing16),
            
            // Notes
            if (customer.notes != null) ...[
              _buildSectionTitle('Notes'),
              const SizedBox(height: AppTheme.spacing8),
              _buildNotes(),
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
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
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
                  customer.name,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  customer.businessType,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: customer.isActive 
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  ),
                  child: Text(
                    customer.isActive ? 'Active' : 'Inactive',
                    style: AppTheme.bodySmall.copyWith(
                      color: customer.isActive 
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
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
          _buildInfoRow(Icons.phone, 'Phone', customer.phone),
          if (customer.email != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(Icons.email, 'Email', customer.email!),
          ],
          const SizedBox(height: AppTheme.spacing12),
          _buildInfoRow(Icons.location_on, 'Location', customer.location),
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
          _buildInfoRow(Icons.business, 'Business Type', customer.businessType),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfoRow(Icons.category, 'Customer Type', customer.customerType),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfoRow(Icons.attach_money, 'Buying Price', '${customer.buyingPricePerLiter.toStringAsFixed(0)} Frw/L'),
          if (customer.idNumber != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(Icons.badge, 'ID Number', customer.idNumber!),
          ],
        ],
      ),
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
          _buildInfoRow(Icons.payment, 'Payment Method', customer.paymentMethod),
          if (customer.bankAccount != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(Icons.account_balance, 'Bank Account', customer.bankAccount!),
          ],
          if (customer.mobileMoneyNumber != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(Icons.phone_android, 'Mobile Money', customer.mobileMoneyNumber!),
          ],
        ],
      ),
    );
  }

  Widget _buildNotes() {
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
              Icon(Icons.note, size: 16, color: AppTheme.textSecondaryColor),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Notes',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            customer.notes!,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.titleMedium.copyWith(
        color: AppTheme.textPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Delete Customer',
      message: 'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
    );
    
    if (confirmed) {
      ref.read(customerProvider.notifier).deleteCustomer(customer.id);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar(
          message: 'Customer deleted successfully!',
        ),
      );
    }
  }
} 