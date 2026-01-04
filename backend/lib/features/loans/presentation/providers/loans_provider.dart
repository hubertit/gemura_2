import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/loan.dart';
import '../../domain/models/loan_repayment.dart';

class LoansNotifier extends StateNotifier<List<Loan>> {
  LoansNotifier() : super([]) {
    _loadMockData();
    _initializeRepaymentHistory();
  }

  // Repayment history storage
  final Map<String, List<LoanRepayment>> _repaymentHistory = {};

  void _loadMockData() {
    state = [
      // Cash Loans
      Loan(
        id: 'LOAN-1',
        name: 'Business Expansion Loan',
        description: 'Loan for expanding small business operations in Kigali',
        type: LoanType.cash,
        amount: 500000,
        interestRate: 12.5,
        termInMonths: 24,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        dueDate: DateTime.now().add(const Duration(days: 690)),
        status: LoanStatus.active,
        walletId: 'WALLET-1',
        guarantors: ['Alice Johnson', 'Eric Niyonsenga'],
        purpose: 'Business expansion and equipment purchase',
        monthlyPayment: 25000,
        totalRepayment: 600000,
        remainingBalance: 450000,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      Loan(
        id: 'LOAN-2',
        name: 'Emergency Cash Loan',
        description: 'Quick cash loan for urgent medical expenses',
        type: LoanType.cash,
        amount: 200000,
        interestRate: 15.0,
        termInMonths: 12,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        dueDate: DateTime.now().add(const Duration(days: 330)),
        status: LoanStatus.approved,
        walletId: 'WALLET-1',
        guarantors: ['Marie Uwimana'],
        purpose: 'Medical emergency expenses',
        monthlyPayment: 20000,
        totalRepayment: 240000,
        remainingBalance: 200000,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),

      // Device/Equipment Loans
      Loan(
        id: 'LOAN-3',
        name: 'Laptop Purchase Loan',
        description: 'Loan for purchasing business laptop and software',
        type: LoanType.device,
        amount: 350000,
        interestRate: 10.0,
        termInMonths: 18,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        dueDate: DateTime.now().add(const Duration(days: 480)),
        status: LoanStatus.active,
        walletId: 'WALLET-1',
        guarantors: ['John Doe'],
        collateral: {
          'device': 'MacBook Pro 2023',
          'serialNumber': 'MBP2023-001',
          'value': 350000,
        },
        purpose: 'Business laptop and software purchase',
        monthlyPayment: 22000,
        totalRepayment: 396000,
        remainingBalance: 264000,
        createdAt: DateTime.now().subtract(const Duration(days: 75)),
      ),
      Loan(
        id: 'LOAN-4',
        name: 'Farming Equipment Loan',
        description: 'Loan for purchasing modern farming equipment',
        type: LoanType.device,
        amount: 800000,
        interestRate: 8.5,
        termInMonths: 36,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        dueDate: DateTime.now().add(const Duration(days: 990)),
        status: LoanStatus.active,
        walletId: 'WALLET-2',
        guarantors: ['Pierre Nkurunziza', 'Grace Uwase'],
        collateral: {
          'equipment': 'Tractor and irrigation system',
          'model': 'Kubota L2501',
          'value': 800000,
        },
        purpose: 'Modern farming equipment purchase',
        monthlyPayment: 28000,
        totalRepayment: 1008000,
        remainingBalance: 672000,
        createdAt: DateTime.now().subtract(const Duration(days: 105)),
      ),

      // Float Loans
      Loan(
        id: 'LOAN-5',
        name: 'Shop Float Loan',
        description: 'Working capital loan for retail shop operations',
        type: LoanType.float,
        amount: 300000,
        interestRate: 11.0,
        termInMonths: 12,
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        dueDate: DateTime.now().add(const Duration(days: 315)),
        status: LoanStatus.active,
        walletId: 'WALLET-1',
        guarantors: ['Sarah Mukamana'],
        purpose: 'Shop inventory and working capital',
        monthlyPayment: 28000,
        totalRepayment: 336000,
        remainingBalance: 224000,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Loan(
        id: 'LOAN-6',
        name: 'Market Stall Float',
        description: 'Daily float loan for market stall operations',
        type: LoanType.float,
        amount: 100000,
        interestRate: 18.0,
        termInMonths: 6,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 170)),
        status: LoanStatus.pending,
        walletId: 'WALLET-1',
        guarantors: ['Jean Claude'],
        purpose: 'Daily market stall operations',
        monthlyPayment: 20000,
        totalRepayment: 120000,
        remainingBalance: 100000,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),

      // Product Loans
      Loan(
        id: 'LOAN-7',
        name: 'Coffee Export Loan',
        description: 'Loan for coffee export business expansion',
        type: LoanType.product,
        amount: 1200000,
        interestRate: 9.0,
        termInMonths: 24,
        startDate: DateTime.now().subtract(const Duration(days: 120)),
        dueDate: DateTime.now().add(const Duration(days: 600)),
        status: LoanStatus.active,
        walletId: 'WALLET-2',
        guarantors: ['Francois Ndayisaba', 'Claudine Uwimana'],
        collateral: {
          'product': 'Coffee beans',
          'quantity': '5000 kg',
          'value': 1200000,
        },
        purpose: 'Coffee export business expansion',
        monthlyPayment: 55000,
        totalRepayment: 1320000,
        remainingBalance: 660000,
        createdAt: DateTime.now().subtract(const Duration(days: 135)),
      ),
      Loan(
        id: 'LOAN-8',
        name: 'Craft Product Loan',
        description: 'Loan for traditional craft product development',
        type: LoanType.product,
        amount: 250000,
        interestRate: 12.0,
        termInMonths: 18,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        dueDate: DateTime.now().add(const Duration(days: 510)),
        status: LoanStatus.completed,
        walletId: 'WALLET-1',
        guarantors: ['Beatrice Nyirahabimana'],
        collateral: {
          'product': 'Traditional crafts',
          'type': 'Baskets and pottery',
          'value': 250000,
        },
        purpose: 'Traditional craft product development',
        monthlyPayment: 16000,
        totalRepayment: 288000,
        remainingBalance: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 540)),
      ),
    ];
  }

  // CRUD Operations
  void addLoan(Loan loan) {
    state = [...state, loan];
  }

  void updateLoan(Loan loan) {
    state = state.map((l) => l.id == loan.id ? loan : l).toList();
  }

  void deleteLoan(String loanId) {
    state = state.where((loan) => loan.id != loanId).toList();
  }

  void updateLoanStatus(String loanId, LoanStatus status) {
    state = state.map((loan) {
      if (loan.id == loanId) {
        return loan.copyWith(status: status, updatedAt: DateTime.now());
      }
      return loan;
    }).toList();
  }

  void makePayment(String loanId, double amount, PaymentMethod paymentMethod) {
    state = state.map((loan) {
      if (loan.id == loanId) {
        final currentBalance = loan.remainingBalance ?? loan.amount;
        final newRemainingBalance = currentBalance - amount;
        
        // Add repayment record
        final repayment = LoanRepayment(
          id: 'REPAY-${DateTime.now().millisecondsSinceEpoch}',
          loanId: loanId,
          amount: amount,
          paymentMethod: paymentMethod,
          status: RepaymentStatus.completed,
          paymentDate: DateTime.now(),
          transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
        );
        
        _addRepaymentRecord(repayment);
        
        // If loan is fully paid, mark as completed
        if (newRemainingBalance <= 0) {
          return loan.copyWith(
            remainingBalance: 0,
            status: LoanStatus.completed,
            updatedAt: DateTime.now(),
          );
        }
        
        return loan.copyWith(
          remainingBalance: newRemainingBalance,
          updatedAt: DateTime.now(),
        );
      }
      return loan;
    }).toList();
  }

  void _initializeRepaymentHistory() {
    // Add some mock repayment history
    _repaymentHistory['LOAN-1'] = [
      LoanRepayment(
        id: 'REPAY-1',
        loanId: 'LOAN-1',
        amount: 25000,
        paymentMethod: PaymentMethod.mobileMoney,
        status: RepaymentStatus.completed,
        paymentDate: DateTime.now().subtract(const Duration(days: 15)),
        transactionId: 'TXN-001',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      LoanRepayment(
        id: 'REPAY-2',
        loanId: 'LOAN-1',
        amount: 25000,
        paymentMethod: PaymentMethod.bankTransfer,
        status: RepaymentStatus.completed,
        paymentDate: DateTime.now().subtract(const Duration(days: 8)),
        transactionId: 'TXN-002',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ];

    _repaymentHistory['LOAN-3'] = [
      LoanRepayment(
        id: 'REPAY-3',
        loanId: 'LOAN-3',
        amount: 22000,
        paymentMethod: PaymentMethod.cash,
        status: RepaymentStatus.completed,
        paymentDate: DateTime.now().subtract(const Duration(days: 20)),
        transactionId: 'TXN-003',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];

    _repaymentHistory['LOAN-4'] = [
      LoanRepayment(
        id: 'REPAY-4',
        loanId: 'LOAN-4',
        amount: 28000,
        paymentMethod: PaymentMethod.card,
        status: RepaymentStatus.completed,
        paymentDate: DateTime.now().subtract(const Duration(days: 25)),
        transactionId: 'TXN-004',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      LoanRepayment(
        id: 'REPAY-5',
        loanId: 'LOAN-4',
        amount: 28000,
        paymentMethod: PaymentMethod.mobileMoney,
        status: RepaymentStatus.completed,
        paymentDate: DateTime.now().subtract(const Duration(days: 10)),
        transactionId: 'TXN-005',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  void _addRepaymentRecord(LoanRepayment repayment) {
    if (!_repaymentHistory.containsKey(repayment.loanId)) {
      _repaymentHistory[repayment.loanId] = [];
    }
    _repaymentHistory[repayment.loanId]!.add(repayment);
  }

  List<LoanRepayment> getRepaymentHistory(String loanId) {
    return _repaymentHistory[loanId] ?? [];
  }

  double getTotalRepaid(String loanId) {
    final repayments = getRepaymentHistory(loanId);
    return repayments
        .where((r) => r.status == RepaymentStatus.completed)
        .fold(0.0, (sum, repayment) => sum + repayment.amount);
  }

  // Computed Lists
  List<Loan> get activeLoans => state.where((loan) => 
    loan.status == LoanStatus.active || loan.status == LoanStatus.approved
  ).toList();

  List<Loan> get pendingLoans => state.where((loan) => 
    loan.status == LoanStatus.pending
  ).toList();

  List<Loan> get completedLoans => state.where((loan) => 
    loan.status == LoanStatus.completed
  ).toList();

  List<Loan> get overdueLoans => state.where((loan) => 
    loan.isOverdue
  ).toList();

  List<Loan> getLoansByType(LoanType type) {
    return state.where((loan) => loan.type == type).toList();
  }

  // Statistics
  double get totalBorrowed {
    return state.fold(0, (sum, loan) => sum + loan.amount);
  }

  double get totalRepaid {
    return state.fold(0, (sum, loan) => sum + (loan.totalRepayment ?? 0));
  }

  double get totalOutstanding {
    return state.fold(0, (sum, loan) => sum + (loan.remainingBalance ?? loan.amount));
  }

  double get averageInterestRate {
    if (state.isEmpty) return 0;
    final totalRate = state.fold(0.0, (sum, loan) => sum + loan.interestRate);
    return totalRate / state.length;
  }
}

// Providers
final loansProvider = StateNotifierProvider<LoansNotifier, List<Loan>>((ref) {
  return LoansNotifier();
});

final activeLoansProvider = Provider<List<Loan>>((ref) {
  return ref.watch(loansProvider.notifier).activeLoans;
});

final pendingLoansProvider = Provider<List<Loan>>((ref) {
  return ref.watch(loansProvider.notifier).pendingLoans;
});

final completedLoansProvider = Provider<List<Loan>>((ref) {
  return ref.watch(loansProvider.notifier).completedLoans;
});

final overdueLoansProvider = Provider<List<Loan>>((ref) {
  return ref.watch(loansProvider.notifier).overdueLoans;
});

final loansStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.watch(loansProvider.notifier);
  return {
    'totalBorrowed': notifier.totalBorrowed,
    'totalRepaid': notifier.totalRepaid,
    'totalOutstanding': notifier.totalOutstanding,
    'averageInterestRate': notifier.averageInterestRate,
    'activeLoans': notifier.activeLoans.length,
    'pendingLoans': notifier.pendingLoans.length,
    'completedLoans': notifier.completedLoans.length,
    'overdueLoans': notifier.overdueLoans.length,
  };
});

final loanRepaymentHistoryProvider = Provider.family<List<LoanRepayment>, String>((ref, loanId) {
  final notifier = ref.watch(loansProvider.notifier);
  return notifier.getRepaymentHistory(loanId);
});

final loanTotalRepaidProvider = Provider.family<double, String>((ref, loanId) {
  final notifier = ref.watch(loansProvider.notifier);
  return notifier.getTotalRepaid(loanId);
}); 