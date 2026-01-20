import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../providers/payroll_provider.dart';
import '../../../../core/services/payroll_service.dart';

class PayrollListScreen extends ConsumerStatefulWidget {
  const PayrollListScreen({super.key});

  @override
  ConsumerState<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends ConsumerState<PayrollListScreen> {

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _formatAmount(num amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.successColor;
      case 'draft':
        return AppTheme.warningColor;
      case 'processing':
        return AppTheme.infoColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  bool _isMarkingPaid = false;
  bool _isExporting = false;

  Future<void> _markAsPaid(BuildContext context, String runId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: const Text('Are you sure you want to mark this payroll as paid? This will create an expense transaction in finance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Confirm', style: TextStyle(color: AppTheme.surfaceColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isMarkingPaid = true);

    try {
      final payrollService = ref.read(payrollServiceProvider);
      await payrollService.markPayrollAsPaid(runId: runId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payroll marked as paid successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        ref.refresh(payrollRunsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingPaid = false);
      }
    }
  }

  Future<void> _exportPayroll(BuildContext context, String runId, String format) async {
    setState(() => _isExporting = true);

    try {
      final payrollService = ref.read(payrollServiceProvider);
      final fileBytes = await payrollService.exportPayroll(runId: runId, format: format);
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final extension = format == 'pdf' ? 'pdf' : 'xlsx';
      final fileName = 'payroll_${runId.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File('${tempDir.path}/$fileName');
      
      await file.writeAsBytes(fileBytes);
      
      if (mounted) {
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Payroll export',
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payroll exported as $format'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportOptions(BuildContext context, String runId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppTheme.primaryColor),
              title: const Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportPayroll(context, runId, 'excel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppTheme.errorColor),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportPayroll(context, runId, 'pdf');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payrollRunsAsync = ref.watch(payrollRunsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Payroll History'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: payrollRunsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'Error loading payrolls',
                  style: AppTheme.titleSmall.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  error.toString(),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing16),
                ElevatedButton(
                  onPressed: () {
                    // ignore: unused_result
                    ref.refresh(payrollRunsProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing24,
                      vertical: AppTheme.spacing12,
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: AppTheme.surfaceColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (payrollRuns) {
          if (payrollRuns.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: AppTheme.textSecondaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'No payroll runs found',
                      style: AppTheme.titleSmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Generate your first payroll to get started',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(payrollRunsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              itemCount: payrollRuns.length,
              itemBuilder: (context, index) {
                final payroll = payrollRuns[index];
                return _buildPayrollCard(context, payroll);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPayrollCard(BuildContext context, Map<String, dynamic> payroll) {
    final status = payroll['status']?.toString() ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final runDate = payroll['run_date']?.toString() ?? '';
    final periodStart = payroll['period_start']?.toString() ?? '';
    final periodEnd = payroll['period_end']?.toString() ?? '';
    final totalAmount = payroll['total_amount'];
    final payslipsCount = payroll['payslips_count'] ?? payroll['payslips']?.length ?? 0;
    final payslips = payroll['payslips'] as List<dynamic>? ?? [];
    // Check if all payslips are already paid
    final allPaid = payslips.isNotEmpty && payslips.every((p) => p['status']?.toString().toLowerCase() == 'paid');
    final canMarkPaid = status.toLowerCase() == 'completed' && !allPaid && !_isMarkingPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showPayrollDetails(context, ref, payroll);
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
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
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing2),
                        if (runDate.isNotEmpty)
                          Text(
                            _formatDateTime(runDate),
                            style: AppTheme.labelSmall.copyWith(
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: AppTheme.labelXSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              if (periodStart.isNotEmpty && periodEnd.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Expanded(
                      child: Text(
                        '${_formatDate(DateTime.parse(periodStart))} - ${_formatDate(DateTime.parse(periodEnd))}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacing4),
                      Text(
                        '$payslipsCount supplier${payslipsCount != 1 ? 's' : ''}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (totalAmount != null)
                    Text(
                      '${_formatAmount(totalAmount as num)} Frw',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isExporting ? null : () => _showExportOptions(context, payroll['id']),
                      icon: _isExporting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download, size: 18),
                      label: const Text('Export'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canMarkPaid
                        ? () => _markAsPaid(context, payroll['id'])
                        : null,
                      icon: _isMarkingPaid
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.surfaceColor),
                          )
                        : const Icon(Icons.payment, size: 18),
                      label: const Text('Mark Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: AppTheme.surfaceColor,
                      ),
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

  void _showPayrollDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> payroll) {
    final payslips = payroll['payslips'] as List<dynamic>? ?? [];
    final status = payroll['status']?.toString() ?? 'unknown';
    // Check if all payslips are already paid
    final allPaid = payslips.isNotEmpty && payslips.every((p) => p['status']?.toString().toLowerCase() == 'paid');
    final canMarkPaid = status.toLowerCase() == 'completed' && !allPaid && !_isMarkingPaid;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius16)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: AppTheme.spacing16,
          left: AppTheme.spacing16,
          right: AppTheme.spacing16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Payroll Details',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildDetailRow('Status', payroll['status']?.toString() ?? 'Unknown'),
            if (payroll['run_date'] != null)
              _buildDetailRow('Run Date', _formatDateTime(payroll['run_date'].toString())),
            if (payroll['period_start'] != null && payroll['period_end'] != null)
              _buildDetailRow(
                'Period',
                '${_formatDate(DateTime.parse(payroll['period_start'].toString()))} - ${_formatDate(DateTime.parse(payroll['period_end'].toString()))}',
              ),
            if (payroll['total_amount'] != null)
              _buildDetailRow('Total Amount', '${_formatAmount(payroll['total_amount'] as num)} Frw'),
            if (payroll['payment_terms_days'] != null)
              _buildDetailRow('Payment Terms', '${payroll['payment_terms_days']} days'),
            const SizedBox(height: AppTheme.spacing16),
            const Divider(),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Payslips (${payslips.length})',
              style: AppTheme.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: payslips.length,
                itemBuilder: (context, index) {
                  final payslip = payslips[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payslip['supplier'] ?? payslip['supplier_code'] ?? 'Unknown',
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${payslip['milk_sales_count'] ?? 0} collections',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            Text(
                              '${_formatAmount((payslip['net_amount'] ?? 0) as num)} Frw',
                              style: AppTheme.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Action buttons in detail view
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : () {
                      Navigator.pop(context);
                      _showExportOptions(context, payroll['id']);
                    },
                    icon: _isExporting 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download, size: 18),
                    label: const Text('Export'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canMarkPaid
                      ? () {
                          Navigator.pop(context);
                          _markAsPaid(context, payroll['id']);
                        }
                      : null,
                    icon: _isMarkingPaid
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.surfaceColor),
                        )
                      : const Icon(Icons.payment, size: 18),
                    label: const Text('Mark Paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: AppTheme.surfaceColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
