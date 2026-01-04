import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/layout_widgets.dart';
import '../providers/savings_provider.dart';
import '../../domain/models/savings_goal.dart';
import '../widgets/savings_goal_card.dart';
import '../widgets/savings_stats_card.dart';
import 'create_savings_goal_screen.dart';
import 'savings_goal_details_screen.dart';
import 'savings_topup_screen.dart';

class SavingsScreen extends ConsumerStatefulWidget {
  const SavingsScreen({super.key});

  @override
  ConsumerState<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends ConsumerState<SavingsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showCompactStats = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showCompact = _scrollController.offset > 30;
    if (showCompact != _showCompactStats) {
      setState(() {
        _showCompactStats = showCompact;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savingsGoals = ref.watch(activeSavingsGoalsProvider);
    final stats = ref.watch(savingsStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Goal',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateSavingsGoalScreen(),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Stats Card (Full by default, Compact on scroll)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                ),
              );
            },
            child: Padding(
              key: ValueKey(_showCompactStats),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: _showCompactStats 
                  ? _buildCompactStatsCard(stats)
                  : SavingsStatsCard(stats: stats),
            ),
          ),
          
          // Goals Section
          Expanded(
            child: savingsGoals.isEmpty
                ? _buildEmptyState(context)
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                          itemCount: savingsGoals.length,
                          itemBuilder: (context, index) {
                            final goal = savingsGoals[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                              child: SavingsGoalCard(
                                goal: goal,
                                onAddMoney: () => _navigateToTopup(context, goal),
                                onTap: () => _navigateToGoalDetails(context, goal),
                              ),
                            );
                          },
                        ),
                      ),
                      // Add Savings Goal Card
                      AddItemCard(
                        title: 'Add New Goal',
                        subtitle: 'Create a new savings goal',
                        icon: Icons.add_circle_outline,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CreateSavingsGoalScreen(),
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

  Widget _buildCompactStatsCard(Map<String, double> stats) {
    final totalSaved = stats['totalSaved'] ?? 0.0;
    final totalTarget = stats['totalTarget'] ?? 0.0;
    final overallProgress = stats['overallProgress'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Row(
            children: [
              Icon(
                Icons.savings,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Total Savings',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${overallProgress.toStringAsFixed(0)}%',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Compact Progress
          LinearProgressIndicator(
            value: overallProgress / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Compact Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactStatItem(
                'Saved',
                '${NumberFormat('#,##0', 'en_US').format(totalSaved.toInt())} RWF',
              ),
              _buildCompactStatItem(
                'Target',
                '${NumberFormat('#,##0', 'en_US').format(totalTarget.toInt())} RWF',
              ),
              _buildCompactStatItem(
                'Remaining',
                '${NumberFormat('#,##0', 'en_US').format((totalTarget - totalSaved).toInt())} RWF',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings,
            size: 64,
            color: AppTheme.textHintColor,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'No savings goals yet',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Create your first savings goal to start building your future.',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textHintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateSavingsGoalScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing24,
                vertical: AppTheme.spacing12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToGoalDetails(BuildContext context, SavingsGoal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SavingsGoalDetailsScreen(goal: goal),
      ),
    );
  }

  void _navigateToTopup(BuildContext context, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadius16),
        ),
      ),
      builder: (context) => SavingsTopupSheet(goal: goal),
    );
  }

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Money to ${goal.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current: ${NumberFormat.currency(symbol: goal.currency).format(goal.currentAmount)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);
                ref.read(savingsProvider.notifier).addContribution(goal.id, amount);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  AppTheme.successSnackBar(
                    message: 'Added ${NumberFormat.currency(symbol: goal.currency).format(amount)} to ${goal.name}',
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 