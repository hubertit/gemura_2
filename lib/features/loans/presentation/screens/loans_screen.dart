import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/loan.dart';
import '../providers/loans_provider.dart';
import '../widgets/loan_card.dart';
import '../widgets/loans_stats_card.dart';
import 'create_loan_screen.dart';
import 'loan_details_screen.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loansStats = ref.watch(loansStatsProvider);
    final activeLoans = ref.watch(activeLoansProvider);
    final pendingLoans = ref.watch(pendingLoansProvider);
    final completedLoans = ref.watch(completedLoansProvider);
    final overdueLoans = ref.watch(overdueLoansProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Loans'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Apply for Loan',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateLoanScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          labelStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
                    children: [
              // All Loans Tab
              _buildLoansListWithStats(ref.watch(loansProvider), loansStats, showStats: true),
              
              // Active Loans Tab
              _buildLoansListWithStats(activeLoans, loansStats, showStats: false),
              
              // Pending Loans Tab
              _buildLoansListWithStats(pendingLoans, loansStats, showStats: false),
              
              // Completed Loans Tab
              _buildLoansListWithStats(completedLoans, loansStats, showStats: false),
              
              // Overdue Loans Tab
              _buildLoansListWithStats(overdueLoans, loansStats, showStats: false),
            ],
      ),
    );
  }

  Widget _buildLoansListWithStats(List<Loan> loans, Map<String, dynamic> stats, {bool showStats = false}) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        // Statistics Card - only show on "All" tab
        if (showStats) ...[
          LoansStatsCard(stats: stats),
          const SizedBox(height: AppTheme.spacing16),
        ],
        
        if (loans.isEmpty) ...[
          // Empty State
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'No loans found',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Apply for a loan to get started',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textHintColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateLoanScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.surfaceColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing24,
                      vertical: AppTheme.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    ),
                  ),
                  child: const Text('Apply for Loan'),
                ),
              ],
            ),
          ),
        ] else ...[
          // Loans List
          ...loans.map((loan) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
            child: LoanCard(
              loan: loan,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LoanDetailsScreen(loan: loan),
                  ),
                );
              },
            ),
          )).toList(),
        ],
      ],
    );
  }
} 