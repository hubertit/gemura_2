import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/savings_goal.dart';
import '../providers/savings_provider.dart';
import 'savings_topup_screen.dart';

class SavingsGoalDetailsScreen extends ConsumerWidget {
  final SavingsGoal goal;

  const SavingsGoalDetailsScreen({
    super.key,
    required this.goal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Money',
            onPressed: () => _navigateToTopup(context),
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal Header Card
            _buildGoalHeaderCard(),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Contributors Metrics Section
            _buildContributorsMetricsSection(),
            
            const SizedBox(height: AppTheme.spacing16),
            
            // Goal Details
            _buildGoalDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.savings,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (goal.description.isNotEmpty)
                      Text(
                        goal.description,
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${goal.progressPercentage.toStringAsFixed(1)}%',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorsMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        color: AppTheme.surfaceColor,
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contributors Metrics',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          ...goal.contributors.map((contributor) => _buildContributorCard(contributor)).toList(),
        ],
      ),
    );
  }

  Widget _buildContributorCard(String contributor) {
    // Mock data for contributor metrics - in real app, this would come from the provider
    final contributorTarget = goal.targetAmount / goal.contributors.length;
    final contributorCurrent = goal.currentAmount / goal.contributors.length;
    final contributorProgress = (contributorCurrent / contributorTarget) * 100;
    final contributorRemaining = contributorTarget - contributorCurrent;
    final contributorDailyRequired = contributorRemaining / goal.daysRemaining.clamp(1, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        color: AppTheme.backgroundColor,
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contributor Header
          Row(
            children: [
                             CircleAvatar(
                 radius: 16,
                 backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                 child: Text(
                   contributor[0].toUpperCase(),
                   style: AppTheme.bodySmall.copyWith(
                     color: AppTheme.primaryColor,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                         Text(
                       contributor,
                       style: AppTheme.bodySmall.copyWith(
                         fontWeight: FontWeight.w600,
                         color: AppTheme.textPrimaryColor,
                       ),
                     ),
                    Text(
                      'Target: ${NumberFormat('#,##0', 'en_US').format(contributorTarget.toInt())} RWF',
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                child: Text(
                  'Active',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing8),
          
          // Progress Bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: contributorProgress / 100,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                '${contributorProgress.toStringAsFixed(1)}%',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing8),
          
          // Contributor Metrics
          Row(
            children: [
              Expanded(
                child: _buildContributorMetric(
                  'Saved',
                  NumberFormat('#,##0', 'en_US').format(contributorCurrent.toInt()),
                  'RWF',
                  Icons.account_balance_wallet,
                  AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: _buildContributorMetric(
                  'Remaining',
                  NumberFormat('#,##0', 'en_US').format(contributorRemaining.toInt()),
                  'RWF',
                  Icons.schedule,
                  AppTheme.textSecondaryColor,
                ),
              ),
              Expanded(
                child: _buildContributorMetric(
                  'Daily',
                  NumberFormat('#,##0', 'en_US').format(contributorDailyRequired.toInt()),
                  'RWF',
                  Icons.trending_up,
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContributorMetric(String label, String value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          unit,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGoalDetails() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        color: AppTheme.surfaceColor,
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal Details',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildDetailRow('Created', DateFormat('MMM dd, yyyy').format(goal.createdAt)),
          _buildDetailRow('Target Date', DateFormat('MMM dd, yyyy').format(goal.targetDate)),
          _buildDetailRow('Status', goal.isActive ? 'Active' : 'Inactive'),
          _buildDetailRow('Currency', goal.currency),
          _buildDetailRow('Goal ID', goal.id),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadius16),
        ),
      ),
      builder: (context) => SavingsTopupSheet(goal: goal),
    );
  }

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Money to ${goal.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current: ${NumberFormat.currency(symbol: goal.currency).format(goal.currentAmount)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                                          prefixIcon: Icon(Icons.monetization_on),
                        prefixText: 'RWF ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);
                ref.read(savingsProvider.notifier).addContribution(goal.id, amount);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.successSnackBar(
                    message: 'Added ${NumberFormat.currency(symbol: goal.currency).format(amount)} to ${goal.name}',
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 