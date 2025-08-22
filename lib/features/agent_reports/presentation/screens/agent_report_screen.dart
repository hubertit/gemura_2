import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/agent_report_provider.dart';
import '../models/agent_report.dart';

class AgentReportScreen extends ConsumerStatefulWidget {
  const AgentReportScreen({super.key});

  @override
  ConsumerState<AgentReportScreen> createState() => _AgentReportScreenState();
}

class _AgentReportScreenState extends ConsumerState<AgentReportScreen> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'Last Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(agentReportProvider(_selectedPeriod));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Report'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(agentReportProvider(_selectedPeriod));
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Period:',
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
                    ),
                    items: _periods.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPeriod = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Report Content
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppTheme.textHintColor),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'Failed to load report',
                      style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      error.toString(),
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    PrimaryButton(
                      label: 'Retry',
                      onPressed: () {
                        ref.refresh(agentReportProvider(_selectedPeriod));
                      },
                    ),
                  ],
                ),
              ),
              data: (report) => SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(report),
                    const SizedBox(height: AppTheme.spacing24),
                    
                    // Performance Metrics
                    _buildPerformanceMetrics(report),
                    const SizedBox(height: AppTheme.spacing24),
                    
                    // Recent Activities
                    _buildRecentActivities(report),
                    const SizedBox(height: AppTheme.spacing24),
                    
                    // Commission Breakdown
                    _buildCommissionBreakdown(report),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AgentReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spacing16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.spacing12,
          mainAxisSpacing: AppTheme.spacing12,
          childAspectRatio: 1.2,
          children: [
            _buildSummaryCard(
              'Total Sales',
              '${NumberFormat('#,##0').format(report.totalSales)} RWF',
              Icons.trending_up,
              AppTheme.successColor,
            ),
            _buildSummaryCard(
              'Total Collections',
              '${NumberFormat('#,##0').format(report.totalCollections)} RWF',
              Icons.account_balance_wallet,
              AppTheme.primaryColor,
            ),
            _buildSummaryCard(
              'Customers Added',
              '${report.customersAdded}',
              Icons.person_add,
              AppTheme.warningColor,
            ),
            _buildSummaryCard(
              'Suppliers Added',
              '${report.suppliersAdded}',
              Icons.business,
              AppTheme.snackbarInfoColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(AgentReport report) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildMetricRow('Sales Target Achievement', '${report.salesTargetAchievement}%', AppTheme.successColor),
          _buildMetricRow('Collection Rate', '${report.collectionRate}%', AppTheme.primaryColor),
          _buildMetricRow('Customer Satisfaction', '${report.customerSatisfaction}%', AppTheme.warningColor),
          _buildMetricRow('Average Transaction Value', '${NumberFormat('#,##0').format(report.averageTransactionValue)} RWF', AppTheme.snackbarInfoColor),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(AgentReport report) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activities',
                style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to detailed activities
                },
                child: Text(
                  'View All',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          if (report.recentActivities.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: AppTheme.textHintColor),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'No recent activities',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textHintColor),
                  ),
                ],
              ),
            )
          else
            ...report.recentActivities.take(5).map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AgentActivity activity) {
    IconData getActivityIcon() {
      switch (activity.type) {
        case 'sale':
          return Icons.shopping_cart;
        case 'collection':
          return Icons.account_balance_wallet;
        case 'customer_added':
          return Icons.person_add;
        case 'supplier_added':
          return Icons.business;
        default:
          return Icons.info;
      }
    }

    Color getActivityColor() {
      switch (activity.type) {
        case 'sale':
          return AppTheme.successColor;
        case 'collection':
          return AppTheme.primaryColor;
        case 'customer_added':
          return AppTheme.warningColor;
        case 'supplier_added':
          return AppTheme.snackbarInfoColor;
        default:
          return AppTheme.textSecondaryColor;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: getActivityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: Icon(getActivityIcon(), color: getActivityColor(), size: 16),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(activity.timestamp),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                ),
              ],
            ),
          ),
          if (activity.amount != null)
            Text(
              '${NumberFormat('#,##0').format(activity.amount)} RWF',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: getActivityColor(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommissionBreakdown(AgentReport report) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commission Breakdown',
            style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildCommissionRow('Sales Commission', report.salesCommission, AppTheme.successColor),
          _buildCommissionRow('Collection Commission', report.collectionCommission, AppTheme.primaryColor),
          _buildCommissionRow('Customer Bonus', report.customerBonus, AppTheme.warningColor),
          _buildCommissionRow('Supplier Bonus', report.supplierBonus, AppTheme.snackbarInfoColor),
          const Divider(),
          _buildCommissionRow('Total Commission', report.totalCommission, AppTheme.primaryColor, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildCommissionRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '${NumberFormat('#,##0').format(amount)} RWF',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
