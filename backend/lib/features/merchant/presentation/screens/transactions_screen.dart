import 'package:flutter/material.dart';
import '../../../../shared/models/transaction.dart';
import '../../../../shared/widgets/transaction_item.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../shared/services/transaction_service.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Transaction transaction;
  const TransactionDetailsScreen({super.key, required this.transaction});

  Color getAmountColor() {
    if (transaction.type == 'income') return AppTheme.successColor;
    if (transaction.type == 'expense' || transaction.type == 'refund') return AppTheme.errorColor;
    return AppTheme.textPrimaryColor;
  }

  IconData getMethodIcon() {
    switch (transaction.paymentMethod.toLowerCase()) {
      case 'mobile money':
        return Icons.phone_iphone_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'qr/ussd':
        return Icons.qr_code_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'failed':
        return AppTheme.errorColor;
      case 'refunded':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: AppTheme.surfaceColor,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing24, horizontal: AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
            border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: getAmountColor().withOpacity(0.12),
                child: Icon(getMethodIcon(), color: getAmountColor(), size: 32),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                transaction.description.isNotEmpty ? transaction.description : transaction.reference,
                style: AppTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing8),
              StatusBadge(status: transaction.status, color: _statusColor(transaction.status)),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                '${transaction.type == 'refund' || transaction.type == 'expense' ? '-' : '+'}${formatAmount(transaction.amount)} ${transaction.currency}',
                style: AppTheme.titleMedium.copyWith(
                  color: getAmountColor(),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Divider(color: AppTheme.thinBorderColor),
              const SizedBox(height: AppTheme.spacing16),
              _detailsRow(context, 'ID', transaction.id),
              _detailsRow(context, 'Reference', transaction.reference),
              _detailsRow(context, 'Payment Method', transaction.paymentMethod),
              _detailsRow(context, 'Customer', '${transaction.customerName} (${transaction.customerPhone})'),
              _detailsRow(context, 'Date', _formatDate(transaction.date)),
              _detailsRow(context, 'Description', transaction.description),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailsRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class TransactionsScreen extends StatefulWidget {
  final Wallet? wallet;
  const TransactionsScreen({super.key, this.wallet});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {

  // Mock wallets for filtering
  List<Wallet> get mockWallets => [
    Wallet(
      id: 'WALLET-1',
      name: 'Main Ikofi',
      balance: 250000,
      currency: 'RWF',
      type: 'individual',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      owners: ['You'],
      isDefault: true,
    ),
    Wallet(
      id: 'WALLET-2',
      name: 'Joint Ikofi',
      balance: 1200000,
      currency: 'RWF',
      type: 'joint',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      owners: ['You', 'Alice', 'Eric'],
      isDefault: false,
      description: 'Joint savings for family expenses',
      targetAmount: 2000000,
      targetDate: DateTime.now().add(const Duration(days: 180)),
    ),
    Wallet(
      id: 'WALLET-3',
      name: 'Vacation Fund',
      balance: 350000,
      currency: 'RWF',
      type: 'individual',
      status: 'inactive',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      owners: ['You'],
      isDefault: false,
      description: 'Vacation savings',
      targetAmount: 500000,
      targetDate: DateTime.now().add(const Duration(days: 90)),
    ),
  ];

  // Get transactions from service
  List<Transaction> get mockTransactions {
    if (widget.wallet != null) {
      return TransactionService().getTransactionsByWallet(widget.wallet!.id);
    }
    return TransactionService().getAllTransactions();
  }

  // Filter state
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedWalletId;
  RangeValues _amountRange = const RangeValues(0, 200000);
  DateTimeRange? _dateRange;
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    // Pre-filter by wallet if provided
    if (widget.wallet != null) {
      _selectedWalletId = widget.wallet!.id;
      _hasActiveFilters = true;
    }
  }

  List<Transaction> get filteredTransactions {
    List<Transaction> filtered = mockTransactions;

    // Filter by type
    if (_selectedType != null) {
      filtered = filtered.where((t) => t.type == _selectedType).toList();
    }

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((t) => t.status == _selectedStatus).toList();
    }

    // Filter by wallet
    if (_selectedWalletId != null) {
      filtered = filtered.where((t) => t.walletId == _selectedWalletId).toList();
    }

    // Filter by amount range
    filtered = filtered.where((t) => 
      t.amount >= _amountRange.start && t.amount <= _amountRange.end
    ).toList();

    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((t) => 
        t.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
        t.date.isBefore(_dateRange!.end.add(const Duration(days: 1)))
      ).toList();
    }

    return filtered;
  }

  void _updateFilterState() {
    setState(() {
      _hasActiveFilters = _selectedType != null || 
                         _selectedStatus != null || 
                         _selectedWalletId != null ||
                         _amountRange != const RangeValues(0, 200000) ||
                         _dateRange != null;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedStatus = null;
      _selectedWalletId = null;
      _amountRange = const RangeValues(0, 200000);
      _dateRange = null;
      _hasActiveFilters = false;
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        selectedType: _selectedType,
        selectedStatus: _selectedStatus,
        selectedWalletId: _selectedWalletId,
        wallets: mockWallets,
        amountRange: _amountRange,
        dateRange: _dateRange,
        onApply: (type, status, walletId, amountRange, dateRange) {
          setState(() {
            _selectedType = type;
            _selectedStatus = status;
            _selectedWalletId = walletId;
            _amountRange = amountRange;
            _dateRange = dateRange;
          });
          _updateFilterState();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = filteredTransactions;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wallet != null ? '${widget.wallet!.name} Transactions' : 'Transactions'),
        backgroundColor: AppTheme.surfaceColor,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
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
      backgroundColor: AppTheme.backgroundColor,
      body: transactions.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return TransactionItem(
                  transaction: transactions[index],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 64, color: AppTheme.textHintColor),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'No transactions found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Try adjusting your filters or check back later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textHintColor),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? selectedType;
  final String? selectedStatus;
  final String? selectedWalletId;
  final List<Wallet> wallets;
  final RangeValues amountRange;
  final DateTimeRange? dateRange;
  final Function(String?, String?, String?, RangeValues, DateTimeRange?) onApply;

  const _FilterSheet({
    required this.selectedType,
    required this.selectedStatus,
    required this.selectedWalletId,
    required this.wallets,
    required this.amountRange,
    required this.dateRange,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _selectedType;
  late String? _selectedStatus;
  late String? _selectedWalletId;
  late RangeValues _amountRange;
  late DateTimeRange? _dateRange;

  final List<String> _transactionTypes = ['payment', 'refund', 'income', 'expense'];
  final List<String> _transactionStatuses = ['success', 'pending', 'failed', 'refunded'];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedStatus = widget.selectedStatus;
    _selectedWalletId = widget.selectedWalletId;
    _amountRange = widget.amountRange;
    _dateRange = widget.dateRange;
  }

  void _applyFilters() {
    widget.onApply(_selectedType, _selectedStatus, _selectedWalletId, _amountRange, _dateRange);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedStatus = null;
      _selectedWalletId = null;
      _amountRange = const RangeValues(0, 200000);
      _dateRange = null;
    });
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  String _formatDateRange(DateTimeRange range) {
    final formatter = DateFormat('MMM dd, yyyy');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
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
                style: AppTheme.titleMedium,
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
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing8,
            children: _transactionTypes.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                label: Text(type.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                },
                backgroundColor: AppTheme.surfaceColor,
                selectedColor: AppTheme.primaryColor.withOpacity(0.12),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.thinBorderColor,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Transaction Status Filter
          Text(
            'Status',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing8,
            children: _transactionStatuses.map((status) {
              final isSelected = _selectedStatus == status;
              return FilterChip(
                label: Text(status.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : null;
                  });
                },
                backgroundColor: AppTheme.surfaceColor,
                selectedColor: AppTheme.primaryColor.withOpacity(0.12),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.thinBorderColor,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Wallet Filter
          Text(
            'Ikofi',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWalletId,
                hint: Text(
                  'All Ikofi',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Ikofi'),
                  ),
                  ...widget.wallets.map((wallet) {
                    return DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Text(
                        wallet.name,
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimaryColor),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedWalletId = value;
                  });
                },
                dropdownColor: AppTheme.surfaceColor,
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.textHintColor),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Amount Range Filter
          Text(
            'Amount Range (RWF)',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
            ),
            child: Column(
              children: [
                RangeSlider(
                  values: _amountRange,
                  min: 0,
                  max: 200000,
                  divisions: 20,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: AppTheme.thinBorderColor,
                  onChanged: (values) {
                    setState(() {
                      _amountRange = values;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatAmount(_amountRange.start)} RWF',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                    ),
                    Text(
                      '${_formatAmount(_amountRange.end)} RWF',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Date Range Filter
          Text(
            'Date Range',
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          InkWell(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppTheme.primaryColor,
                        onPrimary: Colors.white,
                        surface: AppTheme.surfaceColor,
                        onSurface: AppTheme.textPrimaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _dateRange = picked;
                });
              }
            },
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      _dateRange != null 
                          ? _formatDateRange(_dateRange!)
                          : 'Select date range',
                      style: AppTheme.bodySmall.copyWith(
                        color: _dateRange != null 
                            ? AppTheme.textPrimaryColor 
                            : AppTheme.textHintColor,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: AppTheme.textHintColor),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.actionSheetBottomSpacing),

          // Apply Button
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
} 