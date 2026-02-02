import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../providers/receivables_provider.dart';
import '../../../../shared/models/receivable.dart';
import 'record_payment_screen.dart';

class ReceivablesListScreen extends ConsumerStatefulWidget {
  final DateTime initialFromDate;
  final DateTime initialToDate;

  const ReceivablesListScreen({
    super.key,
    required this.initialFromDate,
    required this.initialToDate,
  });

  @override
  ConsumerState<ReceivablesListScreen> createState() => _ReceivablesListScreenState();
}

class _ReceivablesListScreenState extends ConsumerState<ReceivablesListScreen> {
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
    final receivablesAsync = ref.watch(
      receivablesProvider(
        ReceivablesParams(
          dateFrom: _fromDate.toIso8601String().split('T')[0],
          dateTo: _toDate.toIso8601String().split('T')[0],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Receivables'),
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
      body: receivablesAsync.when(
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
          receivablesProvider(
            ReceivablesParams(
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

            // By Customer Section
            if (summary.byCustomer.isNotEmpty) ...[
              Text(
                'By Customer',
                style: AppTheme.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              ...summary.byCustomer.map((customerRec) => _buildCustomerCard(customerRec, dateFormat)),
              const SizedBox(height: AppTheme.spacing16),
            ],

            // All Receivables
            Text(
              'All Receivables',
              style: AppTheme.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            if (summary.allReceivables.isEmpty)
              _buildEmptyState()
            else
              ...summary.allReceivables.map((rec) => _buildReceivableCard(rec, dateFormat)),
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
                'Total Receivables',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                '${_formatAmount(summary.totalReceivables)} RWF',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successColor,
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

  Widget _buildCustomerCard(customerRec, DateFormat dateFormat) {
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
                      customerRec.customer.name,
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      customerRec.customer.code,
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
                    '${_formatAmount(customerRec.totalOutstanding)} RWF',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '${customerRec.invoiceCount} invoice${customerRec.invoiceCount != 1 ? 's' : ''}',
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

  Widget _buildReceivableCard(Receivable rec, DateFormat dateFormat) {
    final agingColor = _getAgingColor(rec.agingBucket);

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
        onTap: () => _showReceivableDetails(context, rec),
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
                          rec.customer.name,
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          dateFormat.format(rec.saleDate),
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
                        '${_formatAmount(rec.outstanding)} RWF',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successColor,
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
                          rec.agingBucket == 'current' ? 'Current' : '${rec.daysOutstanding} days',
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
                    'Total: ${_formatAmount(rec.totalAmount)} RWF',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    'Paid: ${_formatAmount(rec.amountPaid)} RWF',
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              if (rec.outstanding > 0) ...[
                const SizedBox(height: AppTheme.spacing8),
                ElevatedButton.icon(
                  onPressed: () => _recordPayment(context, rec),
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
            'No receivables found',
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
              'Failed to load receivables',
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
                  receivablesProvider(
                    ReceivablesParams(
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

  void _showReceivableDetails(BuildContext context, Receivable rec) {
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
                  color: AppTheme.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: AppTheme.successColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                '${_formatAmount(rec.outstanding)} RWF',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successColor,
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
          DetailRow(label: 'Customer', value: rec.customer.name),
          DetailRow(label: 'Customer Code', value: rec.customer.code),
          DetailRow(label: 'Sale Date', value: dateFormat.format(rec.saleDate)),
          DetailRow(label: 'Quantity', value: '${rec.quantity}L'),
          DetailRow(label: 'Unit Price', value: '${_formatAmount(rec.unitPrice)} RWF/L'),
          DetailRow(label: 'Total Amount', value: '${_formatAmount(rec.totalAmount)} RWF'),
          DetailRow(label: 'Amount Paid', value: '${_formatAmount(rec.amountPaid)} RWF'),
          DetailRow(label: 'Outstanding', value: '${_formatAmount(rec.outstanding)} RWF', valueColor: AppTheme.successColor),
          DetailRow(label: 'Payment Status', value: rec.paymentStatus.toUpperCase()),
          DetailRow(label: 'Days Outstanding', value: '${rec.daysOutstanding} days'),
          DetailRow(label: 'Aging Bucket', value: rec.agingBucket),
          if (rec.notes != null) DetailRow(label: 'Notes', value: rec.notes!),
        ],
      ),
    );
  }

  void _recordPayment(BuildContext context, Receivable rec) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordPaymentScreen(
          type: 'receivable',
          saleId: rec.saleId,
          source: rec.source,
          customerName: rec.customer.name,
          outstanding: rec.outstanding,
          onSuccess: () {
            Navigator.pop(context);
            ref.invalidate(
              receivablesProvider(
                ReceivablesParams(
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
