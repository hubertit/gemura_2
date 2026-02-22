import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../../../../shared/models/wallet.dart';
import 'package:intl/intl.dart';

class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _payouts = [
    {
      'date': '2024-06-10',
      'amount': 50000,
      'currency': 'RWF',
      'status': 'Completed',
      'destination': 'Bank - 1234',
    },
    {
      'date': '2024-06-05',
      'amount': 20000,
      'currency': 'RWF',
      'status': 'Pending',
      'destination': 'Mobile Money - 0788****56',
    },
    {
      'date': '2024-05-28',
      'amount': 100000,
      'currency': 'RWF',
      'status': 'Completed',
      'destination': 'Bank - 5678',
    },
  ];

  void _initiatePayout() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      AppTheme.successSnackBar(message: 'Payout initiated!'),
    );
  }

  void _showPayoutDetails(BuildContext context, Map<String, dynamic> payout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PayoutDetailsSheet(payout: payout),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payouts'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Recent Payouts', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: AppTheme.spacing8),
            Expanded(
              child: _payouts.isEmpty
                  ? Center(child: Text('No payouts yet', style: AppTheme.bodySmall))
                  : ListView.separated(
                      itemCount: _payouts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing8),
                      itemBuilder: (context, i) {
                        final p = _payouts[i];
                        return InkWell(
                          onTap: () => _showPayoutDetails(context, p),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                              border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payments, color: AppTheme.primaryColor, size: 28),
                                const SizedBox(width: AppTheme.spacing12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${p['amount']} ${p['currency']}', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(p['destination'], style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(p['date'], style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: p['status'] == 'Completed'
                                            ? AppTheme.successColor.withOpacity(0.12)
                                            : AppTheme.warningColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p['status'],
                                        style: AppTheme.bodySmall.copyWith(
                                          color: p['status'] == 'Completed'
                                              ? AppTheme.successColor
                                              : AppTheme.warningColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            PrimaryButton(
              label: 'Initiate Payout',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => const _PayoutFormSheet(),
                );
                if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(message: 'Payout initiated!'),
        );
                }
              },
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }
}

class _PayoutFormSheet extends StatefulWidget {
  const _PayoutFormSheet();
  @override
  State<_PayoutFormSheet> createState() => _PayoutFormSheetState();
}

enum PayoutDestination { bank, momo }
enum MomoProvider { mtn, airtel }

class _PayoutFormSheetState extends State<_PayoutFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _momoAccountController = TextEditingController();
  bool _isLoading = false;
  PayoutDestination _destination = PayoutDestination.bank;
  String? _selectedBank;
  MomoProvider _momoProvider = MomoProvider.mtn;

  // Mock wallets - Joint ikofi temporarily hidden
  final List<Wallet> _wallets = [
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
    // Temporarily hidden - Joint Ikofi
    // Wallet(
    //   id: 'WALLET-2',
    //   name: 'Joint Ikofi',
    //   balance: 1200000,
    //   currency: 'RWF',
    //   type: 'joint',
    //   status: 'active',
    //   createdAt: DateTime.now().subtract(const Duration(days: 60)),
    //   owners: ['You', 'Alice', 'Eric'],
    //   isDefault: false,
    // ),
    Wallet(
      id: 'WALLET-3',
      name: 'Savings',
      balance: 50000,
      currency: 'RWF',
      type: 'individual',
      status: 'inactive',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      owners: ['You'],
      isDefault: false,
    ),
  ];
  Wallet? _selectedWallet;

  @override
  void initState() {
    super.initState();
    _selectedWallet = _wallets.firstWhere((w) => w.isDefault, orElse: () => _wallets.first);
  }

  final List<String> _banks = [
    'Bank of Kigali',
    'Equity Bank',
    'I&M Bank',
    'Cogebanque',
    'Access Bank',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _bankAccountController.dispose();
    _momoAccountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: AppTheme.spacing16, right: AppTheme.spacing16, bottom: bottom + AppTheme.spacing16, top: AppTheme.spacing16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Initiate Payout', style: AppTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacing16),
            Text('From Ikofi', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.spacing8),
            DropdownButtonFormField<Wallet>(
              value: _selectedWallet,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              items: _wallets.map((w) => DropdownMenuItem(
                value: w,
                child: Text('${w.name} (${w.balance.toStringAsFixed(0)} ${w.currency})'),
              )).toList(),
              onChanged: (w) => setState(() => _selectedWallet = w),
              validator: (w) => w == null ? 'Select an ikofi' : null,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text('Amount', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.spacing8),
            TextFormField(
              controller: _amountController,
              style: AppTheme.bodySmall,
              decoration: const InputDecoration(
                hintText: 'Enter amount',
                                        prefixIcon: Icon(Icons.monetization_on),
                        prefixText: 'RWF ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount required';
                final n = num.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text('Destination', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.spacing8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<PayoutDestination>(
                    value: _destination,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: PayoutDestination.bank,
                        child: Text('Bank'),
                      ),
                      DropdownMenuItem(
                        value: PayoutDestination.momo,
                        child: Text('Mobile Money'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _destination = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (_destination == PayoutDestination.bank) ...[
              Text('Bank Name', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spacing8),
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _selectedBank = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Select bank' : null,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text('Bank Account Number', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spacing8),
              TextFormField(
                controller: _bankAccountController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Enter bank account number',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Account number required' : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
            if (_destination == PayoutDestination.momo) ...[
              Text('Provider', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spacing8),
              DropdownButtonFormField<MomoProvider>(
                value: _momoProvider,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: MomoProvider.mtn,
                    child: Text('MTN'),
                  ),
                  DropdownMenuItem(
                    value: MomoProvider.airtel,
                    child: Text('AIRTEL'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _momoProvider = v);
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text('Account Number', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppTheme.spacing8),
              TextFormField(
                controller: _momoAccountController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Enter account number',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Account number required' : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
            PrimaryButton(
              label: 'Submit',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submit,
            ),
            const SizedBox(height: AppTheme.actionSheetBottomSpacing),
          ],
        ),
      ),
    );
  }
}

class _PayoutDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> payout;

  const _PayoutDetailsSheet({required this.payout});

  String formatAmount(int amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'failed':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailsActionSheet(
      headerWidget: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
            child: Icon(
              Icons.payments_rounded,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${formatAmount(payout['amount'])} ${payout['currency']}',
            style: AppTheme.headlineLarge.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(payout['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(payout['status']).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              payout['status'].toUpperCase(),
              style: AppTheme.badge.copyWith(
                color: _getStatusColor(payout['status']),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      details: [
        DetailRow(label: 'Destination', value: payout['destination']),
        DetailRow(label: 'Date', value: _formatDate(payout['date'])),
        DetailRow(label: 'Amount', value: '${formatAmount(payout['amount'])} ${payout['currency']}'),
        DetailRow(label: 'Status', value: payout['status']),
      ],
    );
  }
} 