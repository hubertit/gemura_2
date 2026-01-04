import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/local_data_service.dart';
import '../../domain/models/payroll_run.dart';

class PayrollHistoryScreen extends StatefulWidget {
  const PayrollHistoryScreen({super.key});

  @override
  State<PayrollHistoryScreen> createState() => _PayrollHistoryScreenState();
}

class _PayrollHistoryScreenState extends State<PayrollHistoryScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'RWF ');

  @override
  Widget build(BuildContext context) {
    final runs = LocalDataService.getPayrollRuns();
    final totals = LocalDataService.getPayrollTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll History'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Totals Summary Card
          Container(
            margin: const EdgeInsets.all(AppTheme.spacing16),
            padding: const EdgeInsets.all(AppTheme.spacing16),
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
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTotalItem(
                      'Total Runs',
                      totals['total_runs'].toString(),
                      Icons.receipt_long,
                    ),
                    _buildTotalItem(
                      'Total Amount',
                      _currencyFormat.format(totals['total_amount']),
                      Icons.account_balance_wallet,
                    ),
                    _buildTotalItem(
                      'Suppliers',
                      totals['total_suppliers'].toString(),
                      Icons.people,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Payroll Runs List
          Expanded(
            child: runs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppTheme.textHintColor,
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        Text(
                          'No payroll runs yet',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.textHintColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Text(
                          'Create a new payroll run to get started',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textHintColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    itemCount: runs.length,
                    itemBuilder: (context, index) {
                      final run = runs[index];
                      return _buildPayrollRunCard(run);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          value,
          style: AppTheme.titleLarge.copyWith(
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
        ),
      ],
    );
  }

  Widget _buildPayrollRunCard(Map<String, dynamic> run) {
    final runDate = DateTime.parse(run['run_date']);
    final periodStart = run['period_start'] != null
        ? DateTime.parse(run['period_start'])
        : null;
    final periodEnd = run['period_end'] != null
        ? DateTime.parse(run['period_end'])
        : null;
    final totalAmount = (run['total_amount'] as num?)?.toDouble() ?? 0.0;
    final payslips = run['payslips'] as List<dynamic>? ?? [];
    final status = run['status'] as String? ?? 'draft';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: InkWell(
        onTap: () => _showPayrollDetails(run),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payroll Run',
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          _dateFormat.format(runDate),
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
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (periodStart != null && periodEnd != null) ...[
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      '${_dateFormat.format(periodStart)} - ${_dateFormat.format(periodEnd)}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTheme.spacing12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: AppTheme.spacing4),
                      Text(
                        '${payslips.length} Suppliers',
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
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processed':
      case 'completed':
        return AppTheme.successColor;
      case 'draft':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  void _showPayrollDetails(Map<String, dynamic> run) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PayrollDetailsSheet(run: run),
    );
  }
}

class _PayrollDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> run;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'RWF ');

  _PayrollDetailsSheet({required this.run});

  @override
  Widget build(BuildContext context) {
    final payslips = run['payslips'] as List<dynamic>? ?? [];
    final totalAmount = (run['total_amount'] as num?)?.toDouble() ?? 0.0;
    final totalGross = payslips.fold<double>(
      0.0,
      (sum, p) => sum + ((p['gross_amount'] as num?)?.toDouble() ?? 0.0),
    );
    final totalDeductions = payslips.fold<double>(
      0.0,
      (sum, p) => sum + ((p['total_deductions'] as num?)?.toDouble() ?? 0.0),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payroll Details',
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Summary
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Total Gross', _currencyFormat.format(totalGross)),
                const SizedBox(height: AppTheme.spacing8),
                _buildSummaryRow('Total Deductions', _currencyFormat.format(totalDeductions)),
                const Divider(height: AppTheme.spacing16),
                _buildSummaryRow(
                  'Total Net',
                  _currencyFormat.format(totalAmount),
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Payslips List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              itemCount: payslips.length,
              itemBuilder: (context, index) {
                final payslip = payslips[index];
                return _buildPayslipCard(payslip);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.primaryColor : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPayslipCard(Map<String, dynamic> payslip) {
    final grossAmount = (payslip['gross_amount'] as num?)?.toDouble() ?? 0.0;
    final netAmount = (payslip['net_amount'] as num?)?.toDouble() ?? 0.0;
    final deductions = (payslip['total_deductions'] as num?)?.toDouble() ?? 0.0;
    final milkSalesCount = payslip['milk_sales_count'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payslip['supplier_name'] ?? 'Unknown Supplier',
                        style: AppTheme.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (payslip['supplier_code'] != null)
                        Text(
                          payslip['supplier_code'],
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _currencyFormat.format(netAmount),
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPayslipItem('Gross', _currencyFormat.format(grossAmount)),
                _buildPayslipItem('Deductions', _currencyFormat.format(deductions)),
                _buildPayslipItem('Collections', milkSalesCount.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayslipItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

