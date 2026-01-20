import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/finance_provider.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../../domain/models/transaction.dart';

class AllTransactionsScreen extends ConsumerStatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const AllTransactionsScreen({
    super.key,
    this.initialFromDate,
    this.initialToDate,
  });

  @override
  ConsumerState<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  String? _selectedType;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  RangeValues _amountRange = const RangeValues(0, 10000000);
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initialFromDate;
    _dateTo = widget.initialToDate;
    if (_dateFrom != null || _dateTo != null) {
      _hasActiveFilters = true;
    }
  }

  void _updateFilterState() {
    setState(() {
      _hasActiveFilters = _selectedType != null ||
          _dateFrom != null ||
          _dateTo != null ||
          _amountRange != const RangeValues(0, 10000000);
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _dateFrom = widget.initialFromDate;
      _dateTo = widget.initialToDate;
      _amountRange = const RangeValues(0, 10000000);
      _hasActiveFilters = false;
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selectedType: _selectedType,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        amountRange: _amountRange,
        onApply: (type, dateFrom, dateTo, amountRange) {
          setState(() {
            _selectedType = type;
            _dateFrom = dateFrom;
            _dateTo = dateTo;
            _amountRange = amountRange;
          });
          _updateFilterState();
        },
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
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

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      transactionsProvider(
        TransactionsParams(
          type: _selectedType,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          limit: null, // No limit for all transactions
        ),
      ),
    );

    // Filter by amount range in memory
    final filteredTransactions = transactionsAsync.when(
      data: (transactions) {
        return transactions.where((t) {
          return t.amount >= _amountRange.start && t.amount <= _amountRange.end;
        }).toList();
      },
      loading: () => <Transaction>[],
      error: (_, __) => <Transaction>[],
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
        ),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear Filters',
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _hasActiveFilters ? AppTheme.primaryColor : null,
            ),
            tooltip: 'Filter Transactions',
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (filteredTransactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
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
                      'No transactions found',
                      style: AppTheme.titleSmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      _hasActiveFilters
                          ? 'Try adjusting your filters'
                          : 'Record your first transaction',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor.withOpacity(0.7),
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
              ref.invalidate(
                transactionsProvider(
                  TransactionsParams(
                    type: _selectedType,
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    limit: null,
                  ),
                ),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionCard(filteredTransactions[index]);
              },
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Center(
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
                  'Failed to load transactions',
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
                      transactionsProvider(
                        TransactionsParams(
                          type: _selectedType,
                          dateFrom: _dateFrom,
                          dateTo: _dateTo,
                          limit: null,
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
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? selectedType;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final RangeValues amountRange;
  final Function(String?, DateTime?, DateTime?, RangeValues) onApply;

  const _FilterSheet({
    required this.selectedType,
    required this.dateFrom,
    required this.dateTo,
    required this.amountRange,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _selectedType;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late RangeValues _amountRange;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _dateFrom = widget.dateFrom;
    _dateTo = widget.dateTo;
    _amountRange = widget.amountRange;
  }

  void _applyFilters() {
    widget.onApply(_selectedType, _dateFrom, _dateTo, _amountRange);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _dateFrom = null;
      _dateTo = null;
      _amountRange = const RangeValues(0, 10000000);
    });
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now,
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
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
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: AppTheme.primaryColor.withOpacity(0.25),
              rangeSelectionOverlayColor: WidgetStateProperty.all(
                AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        bottom: bottom + AppTheme.spacing16,
        top: AppTheme.spacing16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transactions',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Transaction Type Filter
          Text(
            'Transaction Type',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: [
              FilterChip(
                label: const Text('Revenue'),
                selected: _selectedType == 'revenue',
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? 'revenue' : null;
                  });
                },
                backgroundColor: AppTheme.surfaceColor,
                selectedColor: AppTheme.successColor.withOpacity(0.12),
                checkmarkColor: AppTheme.successColor,
                labelStyle: TextStyle(
                  color: _selectedType == 'revenue'
                      ? AppTheme.successColor
                      : AppTheme.textPrimaryColor,
                  fontWeight: _selectedType == 'revenue' ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: _selectedType == 'revenue'
                      ? AppTheme.successColor
                      : AppTheme.thinBorderColor,
                ),
              ),
              FilterChip(
                label: const Text('Expense'),
                selected: _selectedType == 'expense',
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? 'expense' : null;
                  });
                },
                backgroundColor: AppTheme.surfaceColor,
                selectedColor: AppTheme.warningColor.withOpacity(0.12),
                checkmarkColor: AppTheme.warningColor,
                labelStyle: TextStyle(
                  color: _selectedType == 'expense'
                      ? AppTheme.warningColor
                      : AppTheme.textPrimaryColor,
                  fontWeight: _selectedType == 'expense' ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: _selectedType == 'expense'
                      ? AppTheme.warningColor
                      : AppTheme.thinBorderColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Date Range Filter
          Text(
            'Date Range',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          InkWell(
            onTap: () => _selectDateRange(context),
            child: Container(
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
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Text(
                      _dateFrom != null && _dateTo != null
                          ? '${_formatDate(_dateFrom!)} - ${_formatDate(_dateTo!)}'
                          : 'Select date range',
                      style: AppTheme.bodySmall.copyWith(
                        color: _dateFrom != null && _dateTo != null
                            ? AppTheme.textPrimaryColor
                            : AppTheme.textHintColor,
                      ),
                    ),
                  ),
                  if (_dateFrom != null && _dateTo != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _dateFrom = null;
                          _dateTo = null;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Amount Range Filter
          Text(
            'Amount Range (RWF)',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Container(
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
              children: [
                RangeSlider(
                  values: RangeValues(
                    _amountRange.start.clamp(0.0, 10000000.0),
                    _amountRange.end.clamp(0.0, 10000000.0),
                  ),
                  min: 0,
                  max: 10000000,
                  divisions: 100,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: AppTheme.thinBorderColor,
                  onChanged: (values) {
                    setState(() {
                      _amountRange = RangeValues(
                        values.start.clamp(0.0, 10000000.0),
                        values.end.clamp(0.0, 10000000.0),
                      );
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatAmount(_amountRange.start)} RWF',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      '${_formatAmount(_amountRange.end)} RWF',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacing24),

          // Apply Button
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
            ),
            child: Text(
              'Apply Filters',
              style: AppTheme.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
