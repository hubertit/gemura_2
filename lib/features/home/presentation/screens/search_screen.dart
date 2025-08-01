import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/transaction.dart';
import '../../../../shared/widgets/transaction_item.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Mock transactions for search (in real app, this would come from a provider)
  List<Transaction> get mockTransactions => [
    Transaction(
      id: 'TXN-1001',
      amount: 25000,
      currency: 'RWF',
      type: 'payment',
      status: 'success',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      description: 'Payment for groceries',
      paymentMethod: 'Mobile Money',
      customerName: 'Alice Umutoni',
      customerPhone: '0788123456',
      reference: 'PMT-20240601-001',
    ),
    Transaction(
      id: 'TXN-1002',
      amount: 120000,
      currency: 'RWF',
      type: 'payment',
      status: 'pending',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      description: 'Restaurant payment',
      paymentMethod: 'Card',
      customerName: 'Eric Niyonsaba',
      customerPhone: '0722123456',
      reference: 'PMT-20240601-002',
    ),
    Transaction(
      id: 'TXN-1003',
      amount: 50000,
      currency: 'RWF',
      type: 'refund',
      status: 'success',
      date: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Refund for cancelled order',
      paymentMethod: 'Bank',
      customerName: 'Claudine Mukamana',
      customerPhone: '0733123456',
      reference: 'REF-20240530-001',
    ),
    Transaction(
      id: 'TXN-1004',
      amount: 15000,
      currency: 'RWF',
      type: 'payment',
      status: 'failed',
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Transport fare',
      paymentMethod: 'QR/USSD',
      customerName: 'Jean Bosco',
      customerPhone: '0799123456',
      reference: 'PMT-20240529-001',
    ),
    Transaction(
      id: 'TXN-1005',
      amount: 80000,
      currency: 'RWF',
      type: 'payment',
      status: 'success',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      description: 'Online shopping',
      paymentMethod: 'Mobile Money',
      customerName: 'Marie Claire',
      customerPhone: '0788456123',
      reference: 'PMT-20240601-003',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    ref.read(searchProvider.notifier).setSearchQuery(query);
    
    if (query.isNotEmpty) {
      final results = ref.read(searchProvider.notifier).searchTransactions(mockTransactions, query);
      ref.read(searchProvider.notifier).setSearchResults(results);
    } else {
      ref.read(searchProvider.notifier).setSearchResults([]);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final hasQuery = searchState.query.isNotEmpty;
    final hasResults = searchState.results.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: AppTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search transactions...',
            hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textHintColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppTheme.textHintColor.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: hasQuery
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          if (hasQuery && !hasResults) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: AppTheme.textHintColor,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'No results found',
                      style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Try searching with different keywords',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (hasQuery && hasResults) ...[
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                children: [
                  Text(
                    '${searchState.results.length} result${searchState.results.length == 1 ? '' : 's'} found',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                itemCount: searchState.results.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing12),
                itemBuilder: (context, index) {
                  return TransactionItem(
                    transaction: searchState.results[index],
                    onTap: () {
                      // Show transaction details using DetailsActionSheet
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => _TransactionDetailsSheet(transaction: searchState.results[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: AppTheme.textHintColor,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'Search transactions',
                      style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'Search by amount, customer name, reference, or description',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;
  
  const _TransactionDetailsSheet({required this.transaction});

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

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DetailsActionSheet(
      headerWidget: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: getAmountColor().withOpacity(0.12),
            child: Icon(getMethodIcon(), color: getAmountColor(), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            '${transaction.type == 'refund' || transaction.type == 'expense' ? '-' : '+'}${formatAmount(transaction.amount)} ${transaction.currency}',
            style: AppTheme.headlineLarge.copyWith(
              color: getAmountColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(transaction.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _statusColor(transaction.status).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              transaction.status.toUpperCase(),
              style: AppTheme.badge.copyWith(
                color: _statusColor(transaction.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      details: [
        DetailRow(label: 'To', value: transaction.customerName),
        DetailRow(label: 'Account number', value: transaction.customerPhone),
        DetailRow(label: 'Payment method', value: transaction.paymentMethod),
        DetailRow(label: 'Description', value: transaction.description.isNotEmpty ? transaction.description : 'Mobile wallet transfer'),
        DetailRow(label: 'Date', value: _formatDateTime(transaction.date)),
        DetailRow(label: 'Reference', value: transaction.reference),
      ],
    );
  }
} 