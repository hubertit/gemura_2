import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/localization_provider.dart';
import '../providers/finance_provider.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../../domain/models/transaction.dart';
import 'all_transactions_screen.dart';
import 'package:d_chart/d_chart.dart';
import '../providers/receivables_provider.dart';
import '../providers/payables_provider.dart';
import '../widgets/ar_ap_summary_widget.dart';
import 'receivables_list_screen.dart';
import 'payables_list_screen.dart';
import '../../../../shared/models/receivable.dart';
import '../../../../shared/models/payable.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  // Initialize dates, ensuring they're within valid range
  late DateTime _fromDate;
  late DateTime _toDate;
  
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = now.subtract(const Duration(days: 30));
    _toDate = now;
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);
    
    // Clamp dates to valid range to prevent RangeSlider assertion error
    final clampedFromDate = _fromDate.isBefore(firstDate) 
        ? firstDate 
        : (_fromDate.isAfter(now) ? now : _fromDate);
    final clampedToDate = _toDate.isBefore(firstDate) 
        ? firstDate 
        : (_toDate.isAfter(now) ? now : _toDate);
    
    // Ensure fromDate <= toDate
    final safeFromDate = clampedFromDate.isAfter(clampedToDate) 
        ? clampedToDate 
        : clampedFromDate;
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now,
      initialDateRange: DateTimeRange(start: safeFromDate, end: clampedToDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              primaryContainer: AppTheme.primaryColor.withOpacity(0.25), // Primary blue tint for range background
              onPrimary: Colors.white,
              onPrimaryContainer: AppTheme.primaryColor,
              surface: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: AppTheme.primaryColor.withOpacity(0.25), // Primary blue for range background
              rangeSelectionOverlayColor: WidgetStateProperty.all(
                AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != DateTimeRange(start: _fromDate, end: _toDate)) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = ref.watch(localizationServiceProvider);
    final incomeStatementAsync = ref.watch(
      incomeStatementProvider(
        IncomeStatementParams(fromDate: _fromDate, toDate: _toDate),
      ),
    );
    final transactionsAsync = ref.watch(
      transactionsProvider(
        TransactionsParams(
          dateFrom: _fromDate,
          dateTo: _toDate,
          limit: 50,
        ),
      ),
    );
    final receivablesAsync = ref.watch(
      receivablesProvider(
        ReceivablesParams(
          dateFrom: _fromDate.toIso8601String().split('T')[0],
          dateTo: _toDate.toIso8601String().split('T')[0],
        ),
      ),
    );
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
        title: const Text('Finance'),
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
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Record Transaction',
            onPressed: () => _showTransactionForm(context),
          ),
        ],
      ),
      // Date range + AR/AP always visible (fixes TestFlight: AR/AP hidden when income statement fails/loads).
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            incomeStatementProvider(
              IncomeStatementParams(fromDate: _fromDate, toDate: _toDate),
            ),
          );
          ref.invalidate(
            transactionsProvider(
              TransactionsParams(
                dateFrom: _fromDate,
                dateTo: _toDate,
                limit: 50,
              ),
            ),
          );
          ref.invalidate(
            receivablesProvider(
              ReceivablesParams(
                dateFrom: _fromDate.toIso8601String().split('T')[0],
                dateTo: _toDate.toIso8601String().split('T')[0],
              ),
            ),
          );
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
              _buildDateRangeCard(DateFormat('MMM dd, yyyy')),
              const SizedBox(height: AppTheme.spacing16),
              _buildArApSummary(receivablesAsync, payablesAsync),
              const SizedBox(height: AppTheme.spacing16),
              // Income statement section rendered independently (no longer gates AR/AP or transactions).
              incomeStatementAsync.when(
                data: (incomeStatement) => _buildIncomeSummarySection(
                  incomeStatement,
                ),
                loading: () => SkeletonLoaders.homeTabSkeleton(),
                error: (error, stack) => _buildErrorState(context, error, localizationService),
              ),
              const SizedBox(height: AppTheme.spacing16),
              // Transactions section depends only on transactionsAsync, not on income statement.
              _buildTransactionsSection(transactionsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeSummarySection(
    dynamic incomeStatement,
  ) {
    final revenue = incomeStatement.revenue;
    final expenses = incomeStatement.expenses;
    final netIncome = incomeStatement.netIncome;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                label: 'Revenue',
                amount: revenue,
                color: AppTheme.successColor,
                icon: Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _buildMetricCard(
                label: 'Expenses',
                amount: expenses,
                color: AppTheme.warningColor,
                icon: Icons.trending_down_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildMetricCard(
          label: 'Net Income',
          amount: netIncome,
          color: netIncome >= 0 ? AppTheme.primaryColor : AppTheme.errorColor,
          icon: netIncome >= 0 ? Icons.account_balance_rounded : Icons.warning_rounded,
          isFullWidth: true,
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildChartSection(revenue, expenses),
        const SizedBox(height: AppTheme.spacing12),
        _buildBreakdownSection(revenue, expenses, netIncome),
      ],
    );
  }

  Widget _buildDateRangeCard(DateFormat dateFormat) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date Range',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                '${dateFormat.format(_fromDate)} - ${dateFormat.format(_toDate)}',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
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
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            '${_formatAmount(amount)} RWF',
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(double revenue, double expenses) {
    // Prepare data for donut chart
    final total = revenue + expenses;
    final dataList = <OrdinalData>[];
    
    double revenuePercentage = 0.0;
    double expensePercentage = 0.0;
    
    if (revenue > 0) {
      revenuePercentage = total > 0 ? (revenue / total * 100) : 0.0;
      dataList.add(
        OrdinalData(
          domain: 'Revenue',
          measure: revenue,
          color: AppTheme.successColor,
        ),
      );
    }
    
    if (expenses > 0) {
      expensePercentage = total > 0 ? (expenses / total * 100) : 0.0;
      dataList.add(
        OrdinalData(
          domain: 'Expenses',
          measure: expenses,
          color: AppTheme.warningColor,
        ),
      );
    }

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
            'Revenue vs Expenses',
            style: AppTheme.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: dataList.isEmpty || total == 0
                ? Center(
                    child: Text(
                      'No data available',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  )
                : DChartPieO(
                    data: dataList,
                    animate: true,
                    customLabel: (ordinalData, index) {
                      final percentage = total > 0 
                          ? (ordinalData.measure / total * 100).toStringAsFixed(1)
                          : '0.0';
                      return '$percentage%';
                    },
                    configRenderPie: ConfigRenderPie(
                      arcWidth: 100, // Thinner donut (larger hole)
                      strokeWidthPx: 2,
                      arcLabelDecorator: ArcLabelDecorator(
                        labelPosition: ArcLabelPosition.inside,
                        insideLabelStyle: const LabelStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Chart Legend with percentages
          Column(
            children: [
              _buildLegendItemWithPercentage(
                'Revenue',
                AppTheme.successColor,
                revenuePercentage,
              ),
              const SizedBox(height: AppTheme.spacing8),
              _buildLegendItemWithPercentage(
                'Expenses',
                AppTheme.warningColor,
                expensePercentage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTheme.spacing4),
        Text(
          label,
          style: AppTheme.labelLarge.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItemWithPercentage(String label, Color color, double percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: AppTheme.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownSection(double revenue, double expenses, double netIncome) {
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
            'Financial Breakdown',
            style: AppTheme.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildBreakdownRow('Total Revenue', revenue, AppTheme.successColor),
          const SizedBox(height: AppTheme.spacing12),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacing12),
          _buildBreakdownRow('Total Expenses', expenses, AppTheme.warningColor),
          const SizedBox(height: AppTheme.spacing12),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacing12),
          _buildBreakdownRow(
            'Net Income',
            netIncome,
            netIncome >= 0 ? AppTheme.primaryColor : AppTheme.errorColor,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        Text(
          '${_formatAmount(amount)} RWF',
          style: AppTheme.bodySmall.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, localizationService) {
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
              'Failed to load financial data',
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
                  incomeStatementProvider(
                    IncomeStatementParams(fromDate: _fromDate, toDate: _toDate),
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

  Widget _buildTransactionsSection(AsyncValue<List<Transaction>> transactionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: AppTheme.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllTransactionsScreen(
                      initialFromDate: _fromDate,
                      initialToDate: _toDate,
                    ),
                  ),
                );
              },
              child: Text(
                'View All',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        transactionsAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return _buildEmptyTransactionsState();
            }
            return Column(
              children: transactions.take(10).map((transaction) => _buildTransactionCard(transaction)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    'Failed to load transactions',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isRevenue = transaction.type == 'revenue';
    final color = isRevenue ? AppTheme.successColor : AppTheme.warningColor;
    final icon = isRevenue ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final dateFormat = DateFormat('MMM dd, yyyy');

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
        onTap: () => _showTransactionDetails(context, transaction),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: Row(
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
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      dateFormat.format(transaction.transactionDate),
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    if (transaction.categoryAccount != null) ...[
                      const SizedBox(height: AppTheme.spacing2),
                      Text(
                        transaction.categoryAccount!,
                        style: AppTheme.labelXSmall.copyWith(
                          color: AppTheme.textSecondaryColor.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatAmount(transaction.amount)} RWF',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8,
                      vertical: AppTheme.spacing2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                    ),
                    child: Text(
                      isRevenue ? 'Revenue' : 'Expense',
                      style: AppTheme.labelXSmall.copyWith(
                        color: color,
                        fontSize: 10,
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

  Widget _buildEmptyTransactionsState() {
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
            'No transactions found',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Record your first revenue or expense transaction',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    final isRevenue = transaction.type == 'revenue';
    final color = isRevenue ? AppTheme.successColor : AppTheme.warningColor;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

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
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRevenue ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                '${_formatAmount(transaction.amount)} RWF',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                child: Text(
                  isRevenue ? 'Revenue' : 'Expense',
                  style: AppTheme.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        details: [
          DetailRow(
            label: 'Description',
            value: transaction.description,
          ),
          DetailRow(
            label: 'Date',
            value: dateFormat.format(transaction.transactionDate),
          ),
          DetailRow(
            label: 'Time',
            value: timeFormat.format(transaction.transactionDate),
          ),
          if (transaction.categoryAccount != null)
            DetailRow(
              label: 'Category',
              value: transaction.categoryAccount!,
            ),
          DetailRow(
            label: 'Amount',
            value: '${_formatAmount(transaction.amount)} RWF',
            valueColor: color,
          ),
        ],
      ),
    );
  }

  Future<void> _showTransactionForm(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransactionForm(
        onSuccess: () {
          Navigator.pop(context);
          // Refresh income statement and transactions
          ref.invalidate(
            incomeStatementProvider(
              IncomeStatementParams(fromDate: _fromDate, toDate: _toDate),
            ),
          );
          ref.invalidate(
            transactionsProvider(
              TransactionsParams(
                dateFrom: _fromDate,
                dateTo: _toDate,
                limit: 50,
              ),
            ),
          );
        },
      ),
    );
  }

  void _retryArAp() {
    ref.invalidate(
      receivablesProvider(
        ReceivablesParams(
          dateFrom: _fromDate.toIso8601String().split('T')[0],
          dateTo: _toDate.toIso8601String().split('T')[0],
        ),
      ),
    );
    ref.invalidate(
      payablesProvider(
        PayablesParams(
          dateFrom: _fromDate.toIso8601String().split('T')[0],
          dateTo: _toDate.toIso8601String().split('T')[0],
        ),
      ),
    );
  }

  Widget _buildArApSummary(AsyncValue<ReceivablesSummary> receivablesAsync, AsyncValue<PayablesSummary> payablesAsync) {
    return receivablesAsync.when(
      data: (receivables) => payablesAsync.when(
        data: (payables) => ArApSummaryWidget(
          totalReceivables: receivables.totalReceivables,
          totalPayables: payables.totalPayables,
          onReceivablesTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReceivablesListScreen(
                  initialFromDate: _fromDate,
                  initialToDate: _toDate,
                ),
              ),
            );
          },
          onPayablesTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PayablesListScreen(
                  initialFromDate: _fromDate,
                  initialToDate: _toDate,
                ),
              ),
            );
          },
        ),
        loading: () => _buildArApPlaceholder(isLoading: true),
        error: (_, __) => _buildArApPlaceholder(isLoading: false, onRetry: _retryArAp),
      ),
      loading: () => _buildArApPlaceholder(isLoading: true),
      error: (_, __) => _buildArApPlaceholder(isLoading: false, onRetry: _retryArAp),
    );
  }

  /// Shows AR/AP section when loading or on error so the section is always visible (fixes APK "missing" issue).
  Widget _buildArApPlaceholder({required bool isLoading, VoidCallback? onRetry}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.thinBorderColor,
              color: AppTheme.primaryColor,
            ),
          ),
        ArApSummaryWidget(
          totalReceivables: 0,
          totalPayables: 0,
          onReceivablesTap: isLoading ? null : (onRetry ?? () {}),
          onPayablesTap: isLoading ? null : (onRetry ?? () {}),
        ),
        if (!isLoading && onRetry != null)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing8),
            child: GestureDetector(
              onTap: onRetry,
              child: Text(
                'Couldn\'t load. Tap the cards above to retry.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.warningColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TransactionForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const _TransactionForm({required this.onSuccess});

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'revenue'; // 'revenue' or 'expense'
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);
    
    // Clamp selected date to valid range
    final clampedDate = _selectedDate.isBefore(firstDate) 
        ? firstDate 
        : (_selectedDate.isAfter(now) ? now : _selectedDate);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: clampedDate,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final service = ref.read(financeServiceProvider);
      await service.createTransaction(
        type: _selectedType,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        transactionDate: _selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedType == 'revenue' ? 'Revenue' : 'Expense'} recorded successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        widget.onSuccess();
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
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        top: AppTheme.spacing16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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
              'Record Transaction',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Transaction Type Selector
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton('revenue', 'Revenue', Icons.trending_up, AppTheme.successColor),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildTypeButton('expense', 'Expense', Icons.trending_down, AppTheme.warningColor),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (RWF)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                ),
              ),
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
            const SizedBox(height: AppTheme.spacing16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Date Field
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: AppTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedType == 'revenue' ? AppTheme.successColor : AppTheme.warningColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Record ${_selectedType == 'revenue' ? 'Revenue' : 'Expense'}',
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppTheme.surfaceColor,
          border: Border.all(
            color: isSelected ? color : AppTheme.thinBorderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppTheme.textSecondaryColor,
              size: 24,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              label,
              style: isSelected
                  ? AppTheme.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    )
                  : AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
