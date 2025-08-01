import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../providers/tab_index_provider.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../merchant/presentation/screens/transactions_screen.dart';
import '../../../merchant/presentation/screens/wallets_screen.dart' show WalletCard, WalletsScreen;
import '../../../../shared/widgets/transaction_item.dart';
import '../../../../shared/models/transaction.dart';
import 'package:d_chart/d_chart.dart';
import '../../../../shared/models/wallet.dart';
import 'request_payment_screen.dart';
import 'pay_screen.dart';
import 'payouts_screen.dart';
import 'search_screen.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tabIndexProvider);
    final tabs = [
      const _DashboardTab(),
      const ChatListScreen(),
      const WalletsScreen(), // Restore the merchant WalletsScreen as the tab
      const TransactionsScreen(),
      const ProfileTab(),
    ];
    return Scaffold(
      body: tabs[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(tabIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Ikofi',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  // State to track balance visibility for each wallet
  final Map<String, bool> _walletBalanceVisibility = {};

  // Method to handle balance visibility changes
  void _onBalanceVisibilityChanged(String walletId, bool showBalance) {
    setState(() {
      _walletBalanceVisibility[walletId] = showBalance;
    });
  }

  // Mock wallets for PageView
  List<Wallet> get homeWallets => [
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

  // Mock metrics
  Map<String, dynamic> get metrics => {
    'Today\'s Revenue': 150000,
    'Total Transactions': 42,
    'Pending Settlements': 3,
  };

  // Mock recent transactions
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
    ),
  ];

  // Mock chart data
  Map<String, double> get paymentMethodBreakdown => {
    'Mobile Money': 60,
    'Card': 25,
    'Bank': 10,
    'QR/USSD': 5,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Gemura',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Default Wallet Card
            SizedBox(
              height: 180, // increased to fix overflow issue
              child: PageView.builder(
                itemCount: homeWallets.length,
                controller: PageController(viewportFraction: 0.92),
                itemBuilder: (context, index) {
                  final isFirst = index == 0;
                  final isLast = index == homeWallets.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: isFirst ? 0 : AppTheme.spacing8,
                      right: isLast ? 0 : AppTheme.spacing8,
                    ),
                    child: WalletCard(
                      wallet: homeWallets[index], 
                      showBalance: _walletBalanceVisibility[homeWallets[index].id] ?? true,
                      onShowBalanceChanged: (showBalance) => _onBalanceVisibilityChanged(homeWallets[index].id, showBalance),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacing4), // further reduced space between wallet card and quick actions
            // Quick actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
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
            const SizedBox(height: AppTheme.spacing8),
            // Chart title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Text(
                'Cash In & Out (This Week)',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            // Area chart section with legends
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                  border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                ),
                child: Container(
                  height: 162,
                  width: double.infinity,
                  child: DChartComboO(
                    groupList: [
                      OrdinalGroup(
                        id: 'Cash In',
                        data: [
                          OrdinalData(domain: 'Mon', measure: 120),
                          OrdinalData(domain: 'Tue', measure: 150),
                          OrdinalData(domain: 'Wed', measure: 100),
                          OrdinalData(domain: 'Thu', measure: 180),
                          OrdinalData(domain: 'Fri', measure: 90),
                          OrdinalData(domain: 'Sat', measure: 200),
                          OrdinalData(domain: 'Sun', measure: 170),
                        ],
                        color: AppTheme.primaryColor.withOpacity(0.85),
                        chartType: ChartType.bar,
                      ),
                      OrdinalGroup(
                        id: 'Cash Out',
                        data: [
                          OrdinalData(domain: 'Mon', measure: 80),
                          OrdinalData(domain: 'Tue', measure: 60),
                          OrdinalData(domain: 'Wed', measure: 120),
                          OrdinalData(domain: 'Thu', measure: 90),
                          OrdinalData(domain: 'Fri', measure: 110),
                          OrdinalData(domain: 'Sat', measure: 70),
                          OrdinalData(domain: 'Sun', measure: 130),
                        ],
                        color: Color(0xFFBDBDBD), // Gray
                        chartType: ChartType.bar,
                      ),
                    ],
                    animate: true,
                    domainAxis: DomainAxis(
                      showLine: true,
                      labelStyle: const LabelStyle(
                        color: AppTheme.textSecondaryColor, // Slightly lighter for reduced visibility
                        fontSize: 12, // Larger font size
                        fontWeight: FontWeight.w600, // Bold weight
                      ),
                    ),
                    measureAxis: MeasureAxis(
                      showLine: true,
                      labelStyle: const LabelStyle(
                        color: AppTheme.textSecondaryColor, // Slightly lighter for reduced visibility
                        fontSize: 12, // Larger font size
                        fontWeight: FontWeight.w600, // Bold weight
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            // Recent transactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Text(
                'Recent Transactions',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            ...mockTransactions.map((tx) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: TransactionItem(transaction: tx),
            )),
          ],
        ),
      ),
    );
  }

  Color _getChartColor(String method) {
    switch (method) {
      case 'Mobile Money':
        return const Color(0xFF43A047); // green
      case 'Card':
        return const Color(0xFF1976D2); // blue
      case 'Bank':
        return const Color(0xFFFBC02D); // yellow
      case 'QR/USSD':
        return const Color(0xFF8E24AA); // purple
      default:
        return AppTheme.primaryColor;
    }
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

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('This is a placeholder for $title.')),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Transactions'));
  }
}
class _WalletsTab extends StatelessWidget {
  const _WalletsTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Wallets'));
  }
}
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return authState.when(
      data: (user) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
            titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Profile',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Section
                Container(
                  color: AppTheme.surfaceColor,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: (user?.profileImg != null && user?.profileImg != ''
                          ? NetworkImage(user!.profileImg)
                          : (user?.profilePicture != null && user?.profilePicture != ''
                            ? NetworkImage(user!.profilePicture)
                            : null)) as ImageProvider<Object>?,
                        child: ((user?.profileImg == null || user?.profileImg == '') && (user?.profilePicture == null || user?.profilePicture == ''))
                            ? Text(
                                (user?.name != null && user?.name != '' ? user!.name[0].toUpperCase() : ''),
                                style: AppTheme.headlineLarge.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user?.name ?? '', style: AppTheme.titleMedium, textAlign: TextAlign.center),
                      if (user?.about != null && user?.about != '')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(user!.about, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor), textAlign: TextAlign.center),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Info Group
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(user?.email ?? ''),
                      ),
                      if (user?.phoneNumber != null && user?.phoneNumber != '')
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Phone'),
                          subtitle: Text(user!.phoneNumber),
                        ),
                      if (user?.address != null && user?.address != '')
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Address'),
                          subtitle: Text(user!.address),
                        ),
                      ListTile(
                        leading: const Icon(Icons.verified_user_outlined),
                        title: const Text('Status'),
                        subtitle: Text((user?.isActive ?? false) ? 'Active' : 'Inactive'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Role'),
                        subtitle: Text(user?.role ?? ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Actions Group
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edit Profile'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change Password'),
                        onTap: () {
                          // TODO: Implement change password
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () async {
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_forever, color: AppTheme.errorColor),
                        title: Text('Delete Account', style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor)),
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.surfaceColor,
                              title: Text('Delete Account', style: AppTheme.titleMedium.copyWith(color: AppTheme.errorColor)),
                              content: Text('Are you sure you want to delete your account? This action cannot be undone.', style: AppTheme.bodyMedium),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryColor)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ref.read(authProvider.notifier).deleteAccount();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(message: 'Error: $e'),
        );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Support/Settings Group
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Help & Support'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Notifications'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();
  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _selectedMethod = 'Mobile Money';
  final List<String> _methods = ['Mobile Money', 'Card', 'Bank'];

  // Mock wallets (same as homeWallets)
  final List<Wallet> _wallets = [
    Wallet(
      id: 'WALLET-1',
      name: 'Main Wallet',
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
      name: 'Joint Wallet',
      balance: 1200000,
      currency: 'RWF',
      type: 'joint',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      owners: ['You', 'Alice', 'Eric'],
      isDefault: false,
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
  Wallet? _selectedWallet;

  @override
  void initState() {
    super.initState();
    _selectedWallet = _wallets.firstWhere((w) => w.isDefault, orElse: () => _wallets.first);
  }

  @override
  void dispose() {
    _amountController.dispose();
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
            Text('Top Up Ikofi', style: AppTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacing16),
            Text('To Ikofi', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
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
                prefixIcon: Icon(Icons.attach_money),
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
            Text('Payment Method', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.spacing8),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(),
              ),
              items: _methods.map((m) => DropdownMenuItem(
                value: m,
                child: Text(m),
              )).toList(),
              onChanged: (m) => setState(() => _selectedMethod = m),
              validator: (m) => m == null ? 'Select a method' : null,
            ),
            const SizedBox(height: AppTheme.spacing16),
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