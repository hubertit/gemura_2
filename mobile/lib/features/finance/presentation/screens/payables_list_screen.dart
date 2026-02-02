import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../providers/payables_provider.dart';
import '../../../../shared/models/payable.dart';
import 'record_payment_screen.dart';

class PayablesListScreen extends ConsumerStatefulWidget {
  final DateTime initialFromDate;
  final DateTime initialToDate;

  const PayablesListScreen({
    super.key,
    required this.initialFromDate,
    required this.initialToDate,
  });

  @override
  ConsumerState<PayablesListScreen> createState() => _PayablesListScreenState();
}

class _PayablesListScreenState extends ConsumerState<PayablesListScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              primaryContainer: AppTheme.primaryColor.withOpacity(0.25),
              onPrimary: Colors.white,
              onPrimaryContainer: AppTheme.primaryColor,
              surface: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final payablesAsync = ref.watch(
      payablesProvider(
        PayablesParams(
          dateFrom: _fromDate.toIso8601String().split('T')[0],
          dateTo: _toDate.toIso8601String().split('T')[0],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Payables'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Select Date Range',
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: payablesAsync.when(
        data: (summary) => _buildContent(context, summary),
        loading: () => SkeletonLoaders.homeTabSkeleton(),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, summary) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          payablesProvider(
            PayablesParams(
              dateFrom: _fromDate.toIso8601String().split('T')[0],
              dateTo: _toDate.toIso8601String().split('T')[0],
            ),
          ),
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            _buildSummaryCard(summary),
            const SizedBox(height: AppTheme.spacing16),

            // Aging Summary
            if (summary.agingSummary.current > 0 ||
                summary.agingSummary.days31_60 > 0 ||
                summary.agingSummary.days61_90 > 0 ||
                summary.agingSummary.days90Plus > 0)
              _buildAgingSummary(summary.agingSummary),
            const SizedBox(height: AppTheme.spacing16),

            // By Supplier Section
            if (summary.bySupplier.isNotEmpty) ...[
              Text(
                'By Supplier',
                style: AppTheme.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              ...summary.bySupplier.map((supplierPay) => _buildSupplierCard(supplierPay, dateFormat)),
              const SizedBox(height: AppTheme.spacing16),
            ],

            // All Payables
            Text(
              'All Payables',
              style: AppTheme.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            if (summary.allPayables.isEmpty)
              _buildEmptyState()
            else
              ...summary.allPayables.map((pay) => _buildPayableCard(pay, dateFormat)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(summary) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payables',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                '${_formatAmount(summary.totalPayables)} RWF',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Invoices',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                '${summary.totalInvoices}',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgingSummary(agingSummary) {
    return Container(
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
          Text(
            'Aging Summary',
            style: AppTheme.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildAgingRow('Current (0-30 days)', agingSummary.current, AppTheme.successColor),
          const SizedBox(height: AppTheme.spacing8),
          _buildAgingRow('31-60 days', agingSummary.days31_60, AppTheme.warningColor),
          const SizedBox(height: AppTheme.spacing8),
          _buildAgingRow('61-90 days', agingSummary.days61_90, AppTheme.warningColor),
          const SizedBox(height: AppTheme.spacing8),
          _buildAgingRow('90+ days', agingSummary.days90Plus, AppTheme.errorColor),
        ],
      ),
    );
  }

  Widget _buildAgingRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          '${_formatAmount(amount)} RWF',
          style: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierCard(supplierPay, DateFormat dateFormat) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplierPay.supplier.name,
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      supplierPay.supplier.code,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatAmount(supplierPay.totalOutstanding)} RWF',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '${supplierPay.invoiceCount} invoice${supplierPay.invoiceCount != 1 ? 's' : ''}',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayableCard(Payable pay, DateFormat dateFormat) {
    final agingColor = _getAgingColor(pay.agingBucket);

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
        onTap: () => _showPayableDetails(context, pay),
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
                          pay.supplier.name,
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          dateFormat.format(pay.collectionDate),
                          style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatAmount(pay.outstanding)} RWF',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing8,
                          vertical: AppTheme.spacing2,
                        ),
                        decoration: BoxDecoration(
                          color: agingColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                        ),
                        child: Text(
                          pay.agingBucket == 'current' ? 'Current' : '${pay.daysOutstanding} days',
                          style: AppTheme.labelXSmall.copyWith(
                            color: agingColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${_formatAmount(pay.totalAmount)} RWF',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    'Paid: ${_formatAmount(pay.amountPaid)} RWF',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              if (pay.outstanding > 0) ...[
                const SizedBox(height: AppTheme.spacing8),
                ElevatedButton.icon(
                  onPressed: () => _recordPayment(context, pay),
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Record Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing8,
                    ),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getAgingColor(String bucket) {
    switch (bucket) {
      case 'current':
        return AppTheme.successColor;
      case '31-60':
        return AppTheme.warningColor;
      case '61-90':
        return AppTheme.warningColor;
      case '90+':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'No payables found',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Failed to load payables',
              style: AppTheme.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
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
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(
                  payablesProvider(
                    PayablesParams(
                      dateFrom: _fromDate.toIso8601String().split('T')[0],
                      dateTo: _toDate.toIso8601String().split('T')[0],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayableDetails(BuildContext context, Payable pay) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetailsActionSheet(
        headerWidget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: AppTheme.warningColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                '${_formatAmount(pay.outstanding)} RWF',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                'Outstanding',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        details: [
          DetailRow(label: 'Supplier', value: pay.supplier.name),
          DetailRow(label: 'Supplier Code', value: pay.supplier.code),
          DetailRow(label: 'Collection Date', value: dateFormat.format(pay.collectionDate)),
          DetailRow(label: 'Quantity', value: '${pay.quantity}L'),
          DetailRow(label: 'Unit Price', value: '${_formatAmount(pay.unitPrice)} RWF/L'),
          DetailRow(label: 'Total Amount', value: '${_formatAmount(pay.totalAmount)} RWF'),
          DetailRow(label: 'Amount Paid', value: '${_formatAmount(pay.amountPaid)} RWF'),
          DetailRow(label: 'Outstanding', value: '${_formatAmount(pay.outstanding)} RWF', valueColor: AppTheme.warningColor),
          DetailRow(label: 'Payment Status', value: pay.paymentStatus.toUpperCase()),
          DetailRow(label: 'Days Outstanding', value: '${pay.daysOutstanding} days'),
          DetailRow(label: 'Aging Bucket', value: pay.agingBucket),
          if (pay.notes != null) DetailRow(label: 'Notes', value: pay.notes!),
        ],
      ),
    );
  }

  void _recordPayment(BuildContext context, Payable pay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordPaymentScreen(
          type: 'payable',
          collectionId: pay.collectionId,
          supplierName: pay.supplier.name,
          outstanding: pay.outstanding,
          onSuccess: () {
            Navigator.pop(context);
            ref.invalidate(
              payablesProvider(
                PayablesParams(
                  dateFrom: _fromDate.toIso8601String().split('T')[0],
                  dateTo: _toDate.toIso8601String().split('T')[0],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
