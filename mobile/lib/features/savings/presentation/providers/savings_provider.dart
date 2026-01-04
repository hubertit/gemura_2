import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/savings_goal.dart';

class SavingsNotifier extends StateNotifier<List<SavingsGoal>> {
  SavingsNotifier() : super([]) {
    _loadMockData();
  }

  void _loadMockData() {
    state = [
      SavingsGoal(
        id: 'SAVINGS-1',
        name: 'Coffee Farm Equipment',
        description: 'Purchase coffee processing equipment for rural farm',
        currentAmount: 2500000,
        targetAmount: 5000000,
        currency: 'RWF',
        targetDate: DateTime.now().add(const Duration(days: 240)),
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        contributors: ['You', 'Farm Workers'],
        walletId: 'WALLET-2',
      ),
      SavingsGoal(
        id: 'SAVINGS-2',
        name: 'Maize Storage Facility',
        description: 'Build storage facility for maize harvest',
        currentAmount: 800000,
        targetAmount: 1500000,
        currency: 'RWF',
        targetDate: DateTime.now().add(const Duration(days: 120)),
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        contributors: ['You'],
        walletId: 'WALLET-3',
      ),
      SavingsGoal(
        id: 'SAVINGS-3',
        name: 'Dairy Cow Purchase',
        description: 'Buy dairy cows for milk production business',
        currentAmount: 1200000,
        targetAmount: 3000000,
        currency: 'RWF',
        targetDate: DateTime.now().add(const Duration(days: 180)),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        contributors: ['You', 'Family'],
      ),
      SavingsGoal(
        id: 'SAVINGS-4',
        name: 'Solar Irrigation System',
        description: 'Install solar-powered irrigation for vegetable farming',
        currentAmount: 1800000,
        targetAmount: 4000000,
        currency: 'RWF',
        targetDate: DateTime.now().add(const Duration(days: 300)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        contributors: ['You', 'Cooperative Members'],
      ),
      SavingsGoal(
        id: 'SAVINGS-5',
        name: 'Poultry House Construction',
        description: 'Build modern poultry house for egg production',
        currentAmount: 600000,
        targetAmount: 1200000,
        currency: 'RWF',
        targetDate: DateTime.now().add(const Duration(days: 90)),
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        contributors: ['You'],
      ),
    ];
  }

  void addSavingsGoal(SavingsGoal goal) {
    state = [...state, goal];
  }

  void updateSavingsGoal(SavingsGoal updatedGoal) {
    state = state.map((goal) => goal.id == updatedGoal.id ? updatedGoal : goal).toList();
  }

  void deleteSavingsGoal(String goalId) {
    state = state.where((goal) => goal.id != goalId).toList();
  }

  void addContribution(String goalId, double amount) {
    state = state.map((goal) {
      if (goal.id == goalId) {
        return goal.copyWith(currentAmount: goal.currentAmount + amount);
      }
      return goal;
    }).toList();
  }

  List<SavingsGoal> get activeGoals => state.where((goal) => goal.isActive).toList();
  List<SavingsGoal> get completedGoals => state.where((goal) => goal.progressPercentage >= 100).toList();
  List<SavingsGoal> get upcomingGoals => state.where((goal) => goal.daysRemaining <= 30 && goal.progressPercentage < 100).toList();

  double get totalSaved => state.fold(0, (sum, goal) => sum + goal.currentAmount);
  double get totalTarget => state.fold(0, (sum, goal) => sum + goal.targetAmount);
  double get overallProgress => totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0;
}

final savingsProvider = StateNotifierProvider<SavingsNotifier, List<SavingsGoal>>((ref) {
  return SavingsNotifier();
});

final activeSavingsGoalsProvider = Provider<List<SavingsGoal>>((ref) {
  final savings = ref.watch(savingsProvider);
  return savings.where((goal) => goal.isActive).toList();
});

final completedSavingsGoalsProvider = Provider<List<SavingsGoal>>((ref) {
  final savings = ref.watch(savingsProvider);
  return savings.where((goal) => goal.progressPercentage >= 100).toList();
});

final upcomingSavingsGoalsProvider = Provider<List<SavingsGoal>>((ref) {
  final savings = ref.watch(savingsProvider);
  return savings.where((goal) => goal.daysRemaining <= 30 && goal.progressPercentage < 100).toList();
});

  final savingsStatsProvider = Provider<Map<String, double>>((ref) {
    final savings = ref.watch(savingsProvider);
    final totalSaved = savings.fold(0.0, (sum, goal) => sum + goal.currentAmount);
    final totalTarget = savings.fold(0.0, (sum, goal) => sum + goal.targetAmount);
    final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0.0;
    
    return <String, double>{
      'totalSaved': totalSaved,
      'totalTarget': totalTarget,
      'overallProgress': overallProgress,
    };
  }); 