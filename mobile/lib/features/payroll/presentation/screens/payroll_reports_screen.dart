import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/local_data_service.dart';

class PayrollReportsScreen extends StatelessWidget {
  const PayrollReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final runs = LocalDataService.getPayrollRuns();
    final totals = LocalDataService.getPayrollTotals();
    final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'RWF ');

    // Calculate additional stats
    double totalGross = 0.0;
    double totalDeductions = 0.0;
    int totalCollections = 0;
    Map<String, int> supplierFrequency = {};

    for (final run in runs) {
      final payslips = run['payslips'] as List<dynamic>? ?? [];
      for (final payslip in payslips) {
        totalGross += (payslip['gross_amount'] as num?)?.toDouble() ?? 0.0;
        totalDeductions += (payslip['total_deductions'] as num?)?.toDouble() ?? 0.0;
        totalCollections += payslip['milk_sales_count'] as int? ?? 0;
        
        final supplierId = payslip['supplier_account_id'] as String?;
        if (supplierId != null) {
          supplierFrequency[supplierId] = (supplierFrequency[supplierId] ?? 0) + 1;
        }
      }
    }

    final averagePerRun = runs.isNotEmpty ? totals['total_amount'] / runs.length : 0.0;
    final averagePerSupplier = totals['total_suppliers'] > 0
        ? totals['total_amount'] / totals['total_suppliers']
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll Reports'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overview Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                side: BorderSide(color: AppTheme.borderColor),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.9),
                      AppTheme.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                ),
                padding: const EdgeInsets.all(AppTheme.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payroll Overview',
                      style: AppTheme.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          'Total Runs',
                          totals['total_runs'].toString(),
                          Icons.receipt_long,
                        ),
                        _buildStatItem(
                          'Total Suppliers',
                          totals['total_suppliers'].toString(),
                          Icons.people,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    const Divider(color: Colors.white30),
                    const SizedBox(height: AppTheme.spacing16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Payroll',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing4),
                              Text(
                                _currencyFormat.format(totals['total_amount']),
                                style: AppTheme.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Financial Summary
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                side: BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Summary',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildSummaryRow('Total Gross Amount', _currencyFormat.format(totalGross)),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSummaryRow('Total Deductions', _currencyFormat.format(totalDeductions)),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSummaryRow('Total Net Amount', _currencyFormat.format(totals['total_amount']), isHighlight: true),
                    const Divider(height: AppTheme.spacing24),
                    _buildSummaryRow('Average per Run', _currencyFormat.format(averagePerRun)),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSummaryRow('Average per Supplier', _currencyFormat.format(averagePerSupplier)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Activity Summary
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                side: BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Activity Summary',
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildSummaryRow('Total Collections', totalCollections.toString()),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSummaryRow('Unique Suppliers', totals['total_suppliers'].toString()),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildSummaryRow('Payroll Runs', totals['total_runs'].toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Recent Activity
            if (runs.isNotEmpty) ...[
              Text(
                'Recent Payroll Runs',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              ...runs.take(5).map((run) => _buildRecentRunCard(run)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AppTheme.primaryColor : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRunCard(Map<String, dynamic> run) {
    final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
    final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'RWF ');
    final runDate = DateTime.parse(run['run_date']);
    final totalAmount = (run['total_amount'] as num?)?.toDouble() ?? 0.0;
    final payslips = run['payslips'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateFormat.format(runDate),
                  style: AppTheme.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '${payslips.length} suppliers',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            Text(
              _currencyFormat.format(totalAmount),
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

