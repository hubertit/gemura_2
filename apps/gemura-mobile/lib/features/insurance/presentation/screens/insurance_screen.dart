import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/insurance_provider.dart';
import '../widgets/insurance_card.dart';
import '../widgets/insurance_stats_card.dart';
import 'purchase_insurance_screen.dart';

class InsuranceScreen extends ConsumerStatefulWidget {
  const InsuranceScreen({super.key});

  @override
  ConsumerState<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends ConsumerState<InsuranceScreen>
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
    final allPolicies = ref.watch(insuranceProvider);
    final activePolicies = ref.watch(activePoliciesProvider);
    final pendingPolicies = ref.watch(pendingPoliciesProvider);
    final expiredPolicies = ref.watch(expiredPoliciesProvider);
    final cancelledPolicies = ref.watch(cancelledPoliciesProvider);
    final insuranceStats = ref.watch(insuranceStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Insurance',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Purchase Insurance',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PurchaseInsuranceScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Expired'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Policies Tab
          _buildPoliciesListWithStats(allPolicies, insuranceStats, showStats: true),
          
          // Active Policies Tab
          _buildPoliciesListWithStats(activePolicies, insuranceStats, showStats: false),
          
          // Pending Policies Tab
          _buildPoliciesListWithStats(pendingPolicies, insuranceStats, showStats: false),
          
          // Expired Policies Tab
          _buildPoliciesListWithStats(expiredPolicies, insuranceStats, showStats: false),
          
          // Cancelled Policies Tab
          _buildPoliciesListWithStats(cancelledPolicies, insuranceStats, showStats: false),
        ],
      ),

    );
  }

  Widget _buildPoliciesListWithStats(
    List<dynamic> policies,
    Map<String, dynamic> stats, {
    bool showStats = false,
  }) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      children: [
        // Statistics Card - only show on "All" tab
        if (showStats) ...[
          InsuranceStatsCard(stats: stats),
          const SizedBox(height: AppTheme.spacing16),
        ],
        
        if (policies.isEmpty) ...[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.policy_outlined,
                  size: 64,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'No insurance policies found',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Add your first insurance policy to get started',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          ...policies.map((policy) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
            child: InsuranceCard(
              policy: policy,
              onTap: () {
                // TODO: Navigate to insurance policy details screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('View ${policy.name} - Coming Soon!'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
          )),
        ],
      ],
    );
  }
} 