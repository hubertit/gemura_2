import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/transaction.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../shared/widgets/transaction_item.dart';
import '../../../../shared/widgets/layout_widgets.dart' show AddItemCard, CustomRulesActionSheet, DetailsActionSheet, DetailRow;
import '../../../../shared/widgets/primary_button.dart';
import '../../../savings/presentation/screens/savings_screen.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../../../savings/domain/models/savings_goal.dart';
import '../../../loans/presentation/screens/loans_screen.dart';
import '../../../insurance/presentation/screens/insurance_screen.dart';
import 'transactions_screen.dart';
import '../../../home/presentation/screens/request_payment_screen.dart';
import '../../../home/presentation/screens/pay_screen.dart';
import '../../../home/presentation/screens/payouts_screen.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  // State to track balance visibility for each wallet
  final Map<String, bool> _walletBalanceVisibility = {};

  // Method to handle balance visibility changes
  void _onBalanceVisibilityChanged(String walletId, bool showBalance) {
    setState(() {
      _walletBalanceVisibility[walletId] = showBalance;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final wallets = List<Wallet>.from(mockWallets);
    wallets.sort((a, b) => a.isDefault
        ? -1
        : b.isDefault
            ? 1
            : 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ikofi'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Ikofi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateWalletScreen(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: wallets.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // Quick actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16, horizontal: AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.qr_code,
                            label: 'Request',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const RequestPaymentScreen()),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.send,
                            label: 'Pay',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const PayScreen()),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.account_balance_wallet,
                            label: 'Top Up',
                            onTap: () async {
                              final result = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => const _TopUpSheet(),
                              );
                              if (result == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  AppTheme.successSnackBar(message: 'Top up successful!'),
                                );
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.history,
                            label: 'Payouts',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const PayoutsScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    children: [
                      ...wallets.map((wallet) => WalletCard(
                        wallet: wallet,
                        showBalance: _walletBalanceVisibility[wallet.id] ?? true,
                        onShowBalanceChanged: (showBalance) => _onBalanceVisibilityChanged(wallet.id, showBalance),
                      )),
                      const SizedBox(height: AppTheme.spacing16),
                      // Add Wallet Card
                      AddItemCard(
                        title: 'Add New Ikofi',
                        subtitle: 'Create individual or joint ikofi',
                        icon: Icons.add_circle_outline,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CreateWalletScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_rounded,
              size: 64, color: AppTheme.textHintColor),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'No ikofi yet',
            style: AppTheme.titleMedium
                .copyWith(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Your ikofi will appear here.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
          ),
        ],
      ),
    );
  }
}

class WalletDetailsScreen extends ConsumerStatefulWidget {
  final Wallet wallet;
  const WalletDetailsScreen({super.key, required this.wallet});

  @override
  ConsumerState<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends ConsumerState<WalletDetailsScreen> {
  late Wallet wallet;
  bool _showBalance = true;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _targetDateController = TextEditingController();
  DateTime? _selectedTargetDate;
  bool _isSavingWallet = false;
  
  final List<Map<String, dynamic>> _mockMembers = [
    {
      'name': 'You',
      'contribution': 500000,
      'role': 'Admin',
      'contact': '0788123456'
    },
    {
      'name': 'Alice',
      'contribution': 400000,
      'role': 'Member',
      'contact': '0722123456'
    },
    {
      'name': 'Eric',
      'contribution': 300000,
      'role': 'Member',
      'contact': '0733123456'
    },
  ];

  @override
  void initState() {
    super.initState();
    wallet = widget.wallet;
    _nameController.text = wallet.name;
    _descriptionController.text = wallet.description ?? '';
    _isSavingWallet = wallet.targetAmount != null;
    if (wallet.targetAmount != null) {
      _targetAmountController.text = wallet.targetAmount.toString();
    }
    if (wallet.targetDate != null) {
      _selectedTargetDate = wallet.targetDate;
      _targetDateController.text = '${wallet.targetDate!.day}/${wallet.targetDate!.month}/${wallet.targetDate!.year}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _targetDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalContribution = _mockMembers.fold<int>(
        0, (sum, m) => (sum as int) + ((m['contribution'] ?? 0) as int));
    return Scaffold(
      appBar: AppBar(
        title: Text(wallet.name),
        backgroundColor: AppTheme.surfaceColor,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle:
            AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: AppTheme.primaryColor),
            onPressed: () {
              if (_isEditing) {
                // Save changes
                setState(() {
                  wallet = wallet.copyWith(
                    name: _nameController.text,
                    description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                    targetAmount: _isSavingWallet && _targetAmountController.text.isNotEmpty 
                        ? double.tryParse(_targetAmountController.text) 
                        : null,
                    targetDate: _selectedTargetDate,
                  );
                  _isEditing = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.successSnackBar(message: 'Ikofi updated successfully!'),
                );
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacing8),
            child: Switch(
              value: wallet.status == 'active',
              onChanged: (val) => setState(() {
                wallet = wallet.copyWith(status: val ? 'active' : 'inactive');
              }),
              activeColor: AppTheme.successColor,
              inactiveThumbColor: AppTheme.errorColor,
              inactiveTrackColor: AppTheme.errorColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacing16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: WalletCard(
                wallet: wallet,
                isInDetailsScreen: true,
                showBalance: _showBalance,
                onShowBalanceChanged: (show) {
                  setState(() {
                    _showBalance = show;
                  });
                },
                onMakeDefaultChanged: (isDefault) {
                  if (isDefault) {
                    setState(() {
                      wallet = wallet.copyWith(isDefault: true);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppTheme.successSnackBar(message: 'Ikofi set as default!'),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16, horizontal: AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.savings,
                        label: 'Savings',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SavingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.account_balance,
                                                    label: 'Loans',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const LoansScreen(),
                                ),
                              );
                            },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.verified_user,
                        label: 'Insurance',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const InsuranceScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Saving Goals Section
            const SizedBox(height: AppTheme.spacing16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.savings, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: AppTheme.spacing8),
                        Text(
                          'Saving Goals',
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SavingsScreen(),
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
                    Consumer(
                      builder: (context, ref, child) {
                        final activeGoals = ref.watch(activeSavingsGoalsProvider);
                        final completedGoals = ref.watch(completedSavingsGoalsProvider);
                        
                        if (activeGoals.isEmpty && completedGoals.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(AppTheme.spacing16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.savings_outlined,
                                  color: AppTheme.primaryColor.withOpacity(0.6),
                                  size: 32,
                                ),
                                const SizedBox(height: AppTheme.spacing8),
                                Text(
                                  'No saving goals yet',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacing4),
                                Text(
                                  'Create your first saving goal to start building wealth',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppTheme.spacing12),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const SavingsScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacing16,
                                      vertical: AppTheme.spacing8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                                    ),
                                  ),
                                  child: Text(
                                    'Create Goal',
                                    style: AppTheme.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return Column(
                          children: [
                            // Show up to 2 active goals
                            ...activeGoals.take(2).map((goal) => _buildSavingGoalItem(context, goal, ref)),
                            if (activeGoals.length > 2) ...[
                              const SizedBox(height: AppTheme.spacing8),
                              Center(
                                child: Text(
                                  'And ${activeGoals.length - 2} more active goals',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                            // Show up to 1 completed goal
                            if (completedGoals.isNotEmpty) ...[
                              const SizedBox(height: AppTheme.spacing8),
                              ...completedGoals.take(1).map((goal) => _buildSavingGoalItem(context, goal, ref)),
                              if (completedGoals.length > 1) ...[
                                const SizedBox(height: AppTheme.spacing8),
                                Center(
                                  child: Text(
                                    'And ${completedGoals.length - 1} more completed goals',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Description Section (when editing)
            if (_isEditing) ...[
              const SizedBox(height: AppTheme.spacing16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                    border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      TextFormField(
                        controller: _descriptionController,
                        style: AppTheme.bodySmall,
                        decoration: const InputDecoration(
                          hintText: 'Add a description for this wallet',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            if (wallet.type == 'joint') ...[
              const SizedBox(height: AppTheme.spacing8),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members & Contributions',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final result =
                            await showModalBottomSheet<Map<String, dynamic>>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => const _AddMemberSheet(),
                        );
                        if (result != null && context.mounted) {
                          setState(() {
                            _mockMembers.add(result);
                          });
                        }
                      },
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add Member'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        textStyle: AppTheme.bodySmall
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadius16),
                    border: Border.all(
                        color: AppTheme.thinBorderColor,
                        width: AppTheme.thinBorderWidth),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._mockMembers.asMap().entries.map((entry) {
                        final i = entry.key;
                        final member = entry.value;
                        final percent = totalContribution > 0
                            ? (member['contribution'] ?? 0) /
                                totalContribution *
                                100
                            : 0.0;
                        return InkWell(
                          onTap: () => _showMemberDetails(context, member, i),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacing4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      AppTheme.primaryColor.withOpacity(0.12),
                                  child: Text(member['name'][0],
                                      style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(member['name'],
                                          style: AppTheme.bodySmall.copyWith(
                                              fontWeight: FontWeight.w600)),
                                      if (member['contact'] != null &&
                                          (member['contact'] as String)
                                              .isNotEmpty)
                                        Text(member['contact'],
                                            style: AppTheme.bodySmall.copyWith(
                                                color: AppTheme.textHintColor,
                                                fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${formatAmount(member['contribution'])} RWF',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${percent.toStringAsFixed(1)}%',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textHintColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: member['role'] == 'Admin'
                                        ? AppTheme.successColor.withOpacity(0.12)
                                        : AppTheme.primaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: member['name'] == 'You'
                                      ? Text(
                                          member['role'],
                                          style: AppTheme.badge.copyWith(
                                              color: member['role'] == 'Admin'
                                                  ? AppTheme.successColor
                                                  : AppTheme.primaryColor),
                                        )
                                      : GestureDetector(
                                          onTap: () async {
                                            final newRole =
                                                await showModalBottomSheet<
                                                    String>(
                                              context: context,
                                              isScrollControlled: true,
                                              shape: const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(20)),
                                              ),
                                              builder: (context) =>
                                                  _EditRoleSheet(
                                                      currentRole:
                                                          member['role']),
                                            );
                                            if (newRole != null &&
                                                newRole != member['role'] &&
                                                context.mounted) {
                                              setState(() {
                                                _mockMembers[i]['role'] = newRole;
                                              });
                                            }
                                          },
                                          child: Text(
                                            member['role'],
                                            style: AppTheme.badge.copyWith(
                                                color: member['role'] == 'Admin'
                                                    ? AppTheme.successColor
                                                    : AppTheme.primaryColor),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacing8),
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.spacing16),
              child: Text(
                'Recent Transactions',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            ...mockTransactions.take(3).map((tx) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16),
                  child: TransactionItem(transaction: tx),
                )),
            if (mockTransactions.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing8),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                    },
                    child: const Text('View More'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Transaction> get mockTransactions => [
        Transaction(
          id: 'TXN-1001',
          amount: 25000,
          currency: 'RWF',
          type: 'payment',
          status: 'success',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          description: 'TXN #1234',
          paymentMethod: 'Mobile Money',
          customerName: 'Alice Umutoni',
          customerPhone: '0788123456',
          reference: 'PMT-20240601-001',
          walletId: 'WALLET-1',
        ),
        Transaction(
          id: 'TXN-1002',
          amount: 120000,
          currency: 'RWF',
          type: 'payment',
          status: 'pending',
          date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          description: 'TXN #1235',
          paymentMethod: 'Card',
          customerName: 'Eric Niyonsaba',
          customerPhone: '0722123456',
          reference: 'PMT-20240601-002',
          walletId: 'WALLET-2',
        ),
        Transaction(
          id: 'TXN-1003',
          amount: 50000,
          currency: 'RWF',
          type: 'refund',
          status: 'success',
          date: DateTime.now().subtract(const Duration(days: 2)),
          description: 'Refund for TXN #1232',
          paymentMethod: 'Bank',
          customerName: 'Claudine Mukamana',
          customerPhone: '0733123456',
          reference: 'REF-20240530-001',
          walletId: 'WALLET-1',
        ),
        Transaction(
          id: 'TXN-1004',
          amount: 15000,
          currency: 'RWF',
          type: 'payment',
          status: 'failed',
          date: DateTime.now().subtract(const Duration(days: 3)),
          description: 'TXN #1231',
          paymentMethod: 'QR/USSD',
          customerName: 'Jean Bosco',
          customerPhone: '0799123456',
          reference: 'PMT-20240529-001',
          walletId: 'WALLET-3',
        ),
      ];

  Color getCardColor() {
    if (wallet.status == 'inactive') return const Color(0xFFE6E6E6); // 15% darker gray
    if (wallet.type == 'joint') return AppTheme.primaryColor.withOpacity(0.95);
    return AppTheme.primaryColor.withOpacity(0.85);
  }

  Color getTextColor() {
    // Use white text for active wallets (colored background), black for inactive (gray background)
    if (wallet.status == 'inactive') return AppTheme.textPrimaryColor;
    return Colors.white;
  }

  Color getBalanceColor() {
    // Use white text for active wallets, primary color for inactive
    if (wallet.status == 'inactive') return AppTheme.primaryColor;
    return Colors.white;
  }

  String formatAmount(dynamic amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  Widget _detailsRow(BuildContext context, String label, String value) {
    IconData? icon;
    switch (label) {
      case 'Type':
        icon = Icons.account_tree_rounded;
        break;
      case 'Status':
        icon = Icons.verified_rounded;
        break;
      case 'Owners':
        icon = Icons.group_rounded;
        break;
      case 'Description':
        icon = Icons.description_rounded;
        break;
      case 'Created':
        icon = Icons.calendar_today_rounded;
        break;
      case 'ID':
        icon = Icons.fingerprint_rounded;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: getTextColor().withOpacity(0.7)),
            const SizedBox(width: 6),
          ],
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                  color: getTextColor().withOpacity(0.85),
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(color: getTextColor()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingGoalItem(BuildContext context, SavingsGoal goal, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: goal.isActive 
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  goal.isActive ? 'Active' : 'Completed',
                  style: AppTheme.bodySmall.copyWith(
                    color: goal.isActive 
                        ? AppTheme.primaryColor
                        : AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${NumberFormat('#,##0', 'en_US').format(goal.currentAmount.toInt())} / ${NumberFormat('#,##0', 'en_US').format(goal.targetAmount.toInt())} RWF',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${goal.progressPercentage.toStringAsFixed(1)}%',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              goal.isActive ? AppTheme.primaryColor : AppTheme.successColor,
            ),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetDetailsRow(BuildContext context, String label, String value) {
    IconData? icon;
    switch (label) {
      case 'Target Amount':
        icon = Icons.flag;
        break;
      case 'Target Date':
        icon = Icons.calendar_today;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showMemberDetails(BuildContext context, Map<String, dynamic> member, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MemberDetailsSheet(
        member: member, 
        memberIndex: index,
        onDelete: () {
          setState(() {
            _mockMembers.removeAt(index);
          });
          Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.neutralSnackBar(
            message: '${member['name']} removed from wallet.',
            actionLabel: 'Undo',
            onAction: () {
              setState(() {
                _mockMembers.insert(index, member);
              });
            },
          ),
        );
        },
        onUpdateMember: (updatedMember) {
          setState(() {
            _mockMembers[index] = updatedMember;
          });
        },
      ),
    );
  }
}

class WalletCard extends StatefulWidget {
  final Wallet wallet;
  final VoidCallback? onTap;
  final bool isInDetailsScreen;
  final Function(bool)? onShowBalanceChanged;
  final Function(bool)? onMakeDefaultChanged;
  final bool showBalance;
  
  const WalletCard({
    super.key, 
    required this.wallet, 
    this.onTap,
    this.isInDetailsScreen = false,
    this.onShowBalanceChanged,
    this.onMakeDefaultChanged,
    this.showBalance = true,
  });

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {

  Color getCardColor() {
    // Use different colors for different wallet types or statuses
    if (widget.wallet.status == 'inactive') {
      return const Color(0xFFE6E6E6); // 15% darker gray
    }
    if (widget.wallet.type == 'joint') return AppTheme.primaryColor.withOpacity(0.95);
    return AppTheme.primaryColor.withOpacity(0.85);
  }

  Color getTextColor() {
    // Use white text for active wallets (colored background), black for inactive (gray background)
    if (widget.wallet.status == 'inactive') return AppTheme.textPrimaryColor;
    return Colors.white;
  }

  Color getBalanceColor() {
    // Use white text for active wallets, primary color for inactive
    if (widget.wallet.status == 'inactive') return AppTheme.primaryColor;
    return Colors.white;
  }

  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap ??
          () {
            if (widget.isInDetailsScreen) {
              // Show bottom sheet with wallet details
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => _WalletDetailsSheet(wallet: widget.wallet),
              );
            } else {
              // Navigate to details screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WalletDetailsScreen(wallet: widget.wallet),
                ),
              );
            }
          },
      borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
        padding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: AppTheme.spacing16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          gradient: widget.wallet.status == 'inactive'
              ? null
              : LinearGradient(
                  colors: [
                    getCardColor(),
                    AppTheme.primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: widget.wallet.status == 'inactive' ? getCardColor() : null,
          border: Border.all(
              color: widget.wallet.status == 'inactive'
                  ? AppTheme.thinBorderColor
                  : Colors.transparent,
              width: AppTheme.thinBorderWidth),
          boxShadow: [
            if (widget.wallet.status != 'inactive')
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: widget.isInDetailsScreen 
          ? _buildSimplifiedCard()
          : _buildFullCard(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildFullCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    color: getTextColor(), size: 28),
                const SizedBox(width: AppTheme.spacing8),
                Text(widget.wallet.name,
                    style: AppTheme.titleMedium
                        .copyWith(color: getTextColor())),
              ],
            ),
            Row(
              children: [
                if (widget.wallet.isDefault)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text('Default',
                            style: AppTheme.badge.copyWith(
                                color: getTextColor(),
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                if (widget.wallet.targetAmount != null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.savings, color: getTextColor(), size: 16),
                  ),
              ],
            ),
           if (!widget.wallet.isDefault && widget.onMakeDefaultChanged != null)
             Row(
               children: [
                 Text('Default', style: AppTheme.bodySmall.copyWith(color: getTextColor())),
                 Switch(
                   value: widget.wallet.isDefault,
                   onChanged: (val) {
                     if (val) widget.onMakeDefaultChanged!(val);
                   },
                   activeColor: Colors.amber,
                   inactiveThumbColor: Colors.amber.withOpacity(0.6),
                   inactiveTrackColor: Colors.amber.withOpacity(0.2),
                 ),
               ],
             ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text('Balance',
            style: AppTheme.bodySmall
                .copyWith(color: getTextColor().withOpacity(0.85))),
        Row(
          children: [
            Text(
              widget.showBalance
                  ? '${formatAmount(widget.wallet.balance)} ${widget.wallet.currency}'
                  : '••••••',
              style: AppTheme.titleMedium.copyWith(
                  color: getBalanceColor(),
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                  widget.showBalance
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: getBalanceColor(),
                  size: 20),
              onPressed: () {
                if (widget.onShowBalanceChanged != null) {
                  widget.onShowBalanceChanged!(!widget.showBalance);
                }
              },
              tooltip: widget.showBalance ? 'Hide Balance' : 'Show Balance',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                widget.wallet.type == 'joint'
                    ? 'Joint Wallet'
                    : 'Individual Wallet',
                style: AppTheme.bodySmall
                    .copyWith(color: getTextColor().withOpacity(0.85))),
            if (widget.wallet.type == 'joint')
              Flexible(
                child: Text(
                  'Owners: ${widget.wallet.owners.join(", ")}',
                  style: AppTheme.bodySmall
                      .copyWith(color: getTextColor().withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimplifiedCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    color: getTextColor(), size: 28),
                const SizedBox(width: AppTheme.spacing8),
                Text(widget.wallet.name,
                    style: AppTheme.titleMedium
                        .copyWith(color: getTextColor())),
              ],
            ),
            Row(
              children: [
                if (widget.wallet.isDefault)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text('Default',
                            style: AppTheme.badge.copyWith(
                                color: getTextColor(),
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                if (widget.wallet.targetAmount != null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.savings, color: getTextColor(), size: 16),
                  ),
              ],
            ),
           if (!widget.wallet.isDefault && widget.onMakeDefaultChanged != null)
             Row(
               children: [
                 Text('Default', style: AppTheme.bodySmall.copyWith(color: getTextColor())),
                 Switch(
                   value: widget.wallet.isDefault,
                   onChanged: (val) {
                     if (val) widget.onMakeDefaultChanged!(val);
                   },
                   activeColor: Colors.amber,
                   inactiveThumbColor: Colors.amber.withOpacity(0.6),
                   inactiveTrackColor: Colors.amber.withOpacity(0.2),
                 ),
               ],
             ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text('Balance',
            style: AppTheme.bodySmall
                .copyWith(color: getTextColor().withOpacity(0.85))),
        Row(
          children: [
            Text(
              widget.showBalance
                  ? '${formatAmount(widget.wallet.balance)} ${widget.wallet.currency}'
                  : '••••••',
              style: AppTheme.titleMedium.copyWith(
                  color: getBalanceColor(),
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                  widget.showBalance
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: getBalanceColor(),
                  size: 20),
              onPressed: () {
                if (widget.onShowBalanceChanged != null) {
                  widget.onShowBalanceChanged!(!widget.showBalance);
                }
              },
              tooltip: widget.showBalance ? 'Hide Balance' : 'Show Balance',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
        

        
        const SizedBox(height: AppTheme.spacing8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.info_outline,
              color: getTextColor().withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Tap for details',
              style: AppTheme.bodySmall.copyWith(
                color: getTextColor().withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: AppTheme.spacing8),
            Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet();
  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _contributionController = TextEditingController();
  String _role = 'Member';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'contribution': int.tryParse(_contributionController.text.trim()) ?? 0,
      'role': _role,
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
          left: AppTheme.spacing16,
          right: AppTheme.spacing16,
          bottom: bottom + AppTheme.spacing16,
          top: AppTheme.spacing16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Member',
                style: AppTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _nameController,
              style: AppTheme.bodySmall,
              decoration: const InputDecoration(
                hintText: 'Full name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _contactController,
              style: AppTheme.bodySmall,
              decoration: const InputDecoration(
                hintText: 'Contact (optional)',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _contributionController,
              style: AppTheme.bodySmall,
              decoration: const InputDecoration(
                hintText: 'Contribution amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Contribution required';
                }
                final n = num.tryParse(v);
                if (n == null || n <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppTheme.spacing16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.verified_user),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                DropdownMenuItem(value: 'Member', child: Text('Member')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'Member'),
            ),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                textStyle:
                    AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadius8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Add Member'),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }
}

class _EditRoleSheet extends StatefulWidget {
  final String currentRole;
  const _EditRoleSheet({required this.currentRole});
  @override
  State<_EditRoleSheet> createState() => _EditRoleSheetState();
}

class _EditRoleSheetState extends State<_EditRoleSheet> {
  late String _role;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _role = widget.currentRole;
  }

  void _submit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop(_role);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
          left: AppTheme.spacing16,
          right: AppTheme.spacing16,
          bottom: bottom + AppTheme.spacing16,
          top: AppTheme.spacing16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit Role',
              style: AppTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spacing16),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.verified_user),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Admin', child: Text('Admin')),
              DropdownMenuItem(value: 'Member', child: Text('Member')),
            ],
            onChanged: (v) => setState(() => _role = v ?? 'Member'),
          ),
          const SizedBox(height: AppTheme.spacing16),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              textStyle:
                  AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
          const SizedBox(height: AppTheme.actionSheetBottomSpacing),
        ],
      ),
    );
  }
}

class _MemberDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> member;
  final int memberIndex;
  final VoidCallback onDelete;
  final Function(Map<String, dynamic>) onUpdateMember;

  const _MemberDetailsSheet({required this.member, required this.memberIndex, required this.onDelete, required this.onUpdateMember});

  String formatAmount(dynamic amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.successColor;
      case 'member':
        return AppTheme.primaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600),
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

  @override
  State<_MemberDetailsSheet> createState() => _MemberDetailsSheetState();
}

class _MemberDetailsSheetState extends State<_MemberDetailsSheet> {
  late Map<String, dynamic> _member;

  @override
  void initState() {
    super.initState();
    _member = Map<String, dynamic>.from(widget.member);
  }

  String formatAmount(dynamic amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.successColor;
      case 'member':
        return AppTheme.primaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage from the parent widget's member list
    final totalContribution = 500000; // Mock total - in real app this would come from parent
    final percent = totalContribution > 0
        ? (_member['contribution'] as int) / totalContribution * 100
        : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with drag handle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHintColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.textHintColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Header widget
          const SizedBox(height: 12),
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                child: Text(
                  _member['name'][0].toUpperCase(),
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _member['name'],
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRoleColor(_member['role']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getRoleColor(_member['role']).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _member['role'].toUpperCase(),
                  style: AppTheme.badge.copyWith(
                    color: _getRoleColor(_member['role']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (_member['contact'] != null && (_member['contact'] as String).isNotEmpty)
                  _buildDetailRow('Contact', _member['contact']),
                if (_member['contribution'] != null)
                  _buildDetailRow('Contribution', '${formatAmount(_member['contribution'])} RWF'),
                _buildDetailRow('Contribution', '${percent.toStringAsFixed(1)}%'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          if (_member['name'] != 'You') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final newRole = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => _EditRoleSheet(currentRole: _member['role']),
                        );
                        if (newRole != null && newRole != _member['role'] && context.mounted) {
                          setState(() {
                            _member['role'] = newRole;
                          });
                          widget.onUpdateMember(_member);
                        }
                      },
                      icon: const Icon(Icons.verified_user, size: 20),
                      label: const Text('Edit Role'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Member'),
                            content: Text('Are you sure you want to remove ${_member['name']} from this wallet?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          widget.onDelete();
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Remove Member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600),
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
}

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _targetDateController = TextEditingController();
  
  String _walletType = 'individual'; // 'individual' or 'joint'
  bool _isSavingWallet = false;
  bool _isLoading = false;
  DateTime? _selectedTargetDate;
  
  final List<Map<String, dynamic>> _members = [];
  final _memberNameController = TextEditingController();
  
  // Custom rules data
  final Map<String, dynamic> _customRules = {
    'minContribution': 1000,
    'maxWithdrawal': 50, // percentage
    'requireApproval': true,
    'monthlyContribution': true,
    'penalties': false,
    'cycleDuration': 9, // months
    'interestRate': 10, // percentage
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalNameController.dispose();
    _targetAmountController.dispose();
    _targetDateController.dispose();
    _memberNameController.dispose();
    super.dispose();
  }

  void _addMember() {
    if (_memberNameController.text.trim().isNotEmpty) {
      setState(() {
        _members.add({
          'name': _memberNameController.text.trim(),
          'role': 'Member',
        });
        _memberNameController.clear();
      });
    }
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
    });
  }

  Widget _buildRuleItem(String number, String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              rule,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomRulesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CustomRulesActionSheet(
        initialRules: _customRules,
        onRulesChanged: (newRules) {
          setState(() {
            _customRules.addAll(newRules);
          });
        },
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_walletType == 'joint' && _members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.warningSnackBar(message: 'Please add at least one member for joint wallet'),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(message: 'Wallet created successfully!'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'Error creating wallet: $e'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Wallet'),
        backgroundColor: AppTheme.surfaceColor,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wallet Type Selection
              Text(
                'Wallet Type',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: AppTheme.spacing8),
                          Text('Individual Wallet', style: AppTheme.bodySmall),
                        ],
                      ),
                      value: 'individual',
                      groupValue: _walletType,
                      onChanged: (value) => setState(() => _walletType = value!),
                      activeColor: AppTheme.primaryColor,
                    ),
                    Divider(color: AppTheme.thinBorderColor, height: 1),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.group, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: AppTheme.spacing8),
                          Text('Joint Wallet', style: AppTheme.bodySmall),
                        ],
                      ),
                      value: 'joint',
                      groupValue: _walletType,
                      onChanged: (value) => setState(() => _walletType = value!),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacing16),
              
              if (_walletType == 'joint') ...[
                // Joint Wallet Rules Section
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      width: AppTheme.thinBorderWidth,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.rule,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Text(
                            'Joint Wallet Rules',
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing12),
                      _buildRuleItem('1', 'All members have equal access to the wallet'),
                      _buildRuleItem('2', 'Minimum contribution is 1,000 RWF per member'),
                      _buildRuleItem('3', 'Members can withdraw up to 50% of their contribution'),
                      _buildRuleItem('4', 'All transactions require majority approval'),
                      _buildRuleItem('5', 'Monthly contribution is required'),
                      _buildRuleItem('6', 'No penalties for late contributions'),
                      const SizedBox(height: AppTheme.spacing8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              width: AppTheme.thinBorderWidth,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _showCustomRulesDialog(context);
                              },
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing12,
                                  vertical: AppTheme.spacing8,
                                ),
                                child: Text(
                                  'Customize rules',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacing16),
              ],
              
              // Basic Information
              Text(
                'Basic Information',
                style: AppTheme.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              
              TextFormField(
                controller: _nameController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Wallet name',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Wallet name required' : null,
              ),
              
              const SizedBox(height: AppTheme.spacing12),
              
              TextFormField(
                controller: _descriptionController,
                style: AppTheme.bodySmall,
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: AppTheme.spacing16),
              
              // Saving Wallet Toggle
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: Row(
                  children: [
                    Icon(Icons.savings, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saving Wallet', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                          Text('Set a target amount to save', style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isSavingWallet,
                      onChanged: (value) => setState(() => _isSavingWallet = value),
                      activeColor: AppTheme.primaryColor,
                      inactiveThumbColor: AppTheme.thinBorderColor,
                      inactiveTrackColor: AppTheme.thinBorderColor.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              
              if (_isSavingWallet) ...[
                const SizedBox(height: AppTheme.spacing12),
                TextFormField(
                  controller: _goalNameController,
                  style: AppTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: 'Goal name',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  validator: (v) {
                    if (_isSavingWallet && (v == null || v.trim().isEmpty)) {
                      return 'Goal name required for saving wallet';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing12),
                TextFormField(
                  controller: _targetAmountController,
                  style: AppTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: 'Target amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (_isSavingWallet && (v == null || v.trim().isEmpty)) {
                      return 'Target amount required for saving wallet';
                    }
                    if (v != null && v.trim().isNotEmpty) {
                      final n = num.tryParse(v);
                      if (n == null || n <= 0) return 'Enter a valid amount';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppTheme.spacing12),
                TextFormField(
                  controller: _targetDateController,
                  style: AppTheme.bodySmall,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Target date',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.keyboard_arrow_down),
                  ),
                  onTap: _showDatePicker,
                  validator: (v) {
                    if (_isSavingWallet && (v == null || v.trim().isEmpty)) {
                      return 'Target date required for saving wallet';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: AppTheme.spacing16),
              
              if (_walletType == 'joint') ...[
                // Members Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${_members.length} member${_members.length != 1 ? 's' : ''}',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing8),
                
                // Add Member Form - WhatsApp Style
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _memberNameController,
                              style: AppTheme.bodySmall,
                              decoration: const InputDecoration(
                                hintText: 'Search contacts or enter name',
                                prefixIcon: Icon(Icons.search),
                                suffixIcon: Icon(Icons.contacts),
                              ),
                              onFieldSubmitted: (value) => _addMember(),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                              border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                            ),
                            child: IconButton(
                              onPressed: _addMember,
                              icon: Icon(Icons.add, color: AppTheme.primaryColor, size: 20),
                              tooltip: 'Add Member',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'Tap the + button to add members to your joint wallet',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textHintColor,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                if (_members.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacing8),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                    ),
                    child: Column(
                      children: _members.asMap().entries.map((entry) {
                        final index = entry.key;
                        final member = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < _members.length - 1 ? AppTheme.spacing8 : 0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                                child: Text(
                                  member['name'][0].toUpperCase(),
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing12),
                              Expanded(
                                child: Text(
                                  member['name'],
                                  style: AppTheme.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  member['role'],
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 22, color: AppTheme.errorColor),
                                onPressed: () => _removeMember(index),
                                tooltip: 'Remove',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
              
              const SizedBox(height: AppTheme.actionSheetBottomSpacing),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  textStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePicker() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    
    showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2020),
      lastDate: tomorrow,
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedTargetDate = date;
        });
      }
    });
  }
}

class _WalletDetailsSheet extends StatelessWidget {
  final Wallet wallet;

  const _WalletDetailsSheet({required this.wallet});

  Color getCardColor() {
    if (wallet.status == 'inactive') return const Color(0xFFE6E6E6);
    if (wallet.type == 'joint') return AppTheme.primaryColor.withOpacity(0.95);
    return AppTheme.primaryColor.withOpacity(0.85);
  }

  String formatAmount(double amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successColor;
      case 'inactive':
        return AppTheme.textSecondaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailsActionSheet(
      // Move wallet name out of headerWidget
      headerWidget: Card(
        elevation: 0,
        color: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            children: [
              // Wallet name at the top, centered
              Text(
                wallet.name,
                style: AppTheme.headlineLarge.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Wallet balance
              Text(
                '${formatAmount(wallet.balance)} ${wallet.currency}',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Status and default badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(wallet.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(wallet.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: _getStatusColor(wallet.status)),
                        const SizedBox(width: 6),
                        Text(
                          wallet.status.toUpperCase(),
                          style: AppTheme.badge.copyWith(
                            color: _getStatusColor(wallet.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (wallet.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'DEFAULT',
                            style: AppTheme.badge.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      details: [
        // Group 1: Type & Owners
        DetailRow(
          label: 'Type',
          value: wallet.type == 'joint' ? 'Joint Wallet' : 'Individual Wallet',
          customValue: Row(
            children: [
              Icon(wallet.type == 'joint' ? Icons.groups : Icons.person, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  wallet.type == 'joint' ? 'Joint Wallet' : 'Individual Wallet',
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (wallet.type == 'joint')
          DetailRow(
            label: 'Owners',
            value: wallet.owners.join(', '),
            customValue: Row(
              children: [
                Icon(Icons.people, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    wallet.owners.join(', '),
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        // Group 2: Description
        if (wallet.description != null && wallet.description!.isNotEmpty)
          DetailRow(
            label: 'Description',
            value: wallet.description!,
            customValue: Row(
              children: [
                Icon(Icons.description_outlined, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    wallet.description!,
                    style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        // Group 3: Meta info
        DetailRow(
          label: 'Created',
          value: _formatDate(wallet.createdAt),
          customValue: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                _formatDate(wallet.createdAt),
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        DetailRow(
          label: 'Wallet ID',
          value: wallet.id,
          customValue: Row(
            children: [
              Icon(Icons.qr_code_2, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  wallet.id,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Group 4: Target info
        if (wallet.targetAmount != null)
          DetailRow(
            label: 'Target Amount',
            value: '${formatAmount(wallet.targetAmount!)} ${wallet.currency}',
            customValue: Row(
              children: [
                Icon(Icons.flag, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  '${formatAmount(wallet.targetAmount!)} ${wallet.currency}',
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        if (wallet.targetAmount != null && wallet.targetDate != null)
          DetailRow(
            label: 'Target Date',
            value: _formatDate(wallet.targetDate!),
            customValue: Row(
              children: [
                Icon(Icons.event, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  _formatDate(wallet.targetDate!),
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedWallet = 'Main Ikofi';
  final List<String> _wallets = ['Main Ikofi', 'Joint Ikofi'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
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
                'Top Up Ikofi',
                style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          DropdownButtonFormField<String>(
            value: _selectedWallet,
            decoration: const InputDecoration(
              labelText: 'Select Ikofi',
              border: OutlineInputBorder(),
            ),
            items: _wallets.map((wallet) {
              return DropdownMenuItem(
                value: wallet,
                child: Text(wallet),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedWallet = value!;
              });
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (RWF)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          PrimaryButton(
            label: 'Top Up',
            onPressed: () {
              if (_amountController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          const SizedBox(height: AppTheme.spacing16),
        ],
      ),
    );
  }
}


