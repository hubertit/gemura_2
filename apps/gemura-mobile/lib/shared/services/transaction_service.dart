import '../models/transaction.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  // In-memory storage for transactions (in a real app, this would be a database)
  final List<Transaction> _transactions = [
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
    Transaction(
      id: 'TXN-1005',
      amount: 80000,
      currency: 'RWF',
      type: 'payment',
      status: 'success',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      description: 'TXN #1236',
      paymentMethod: 'Mobile Money',
      customerName: 'Marie Claire',
      customerPhone: '0788456123',
      reference: 'PMT-20240601-003',
      walletId: 'WALLET-2',
    ),
    Transaction(
      id: 'TXN-1006',
      amount: 30000,
      currency: 'RWF',
      type: 'payment',
      status: 'pending',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      description: 'TXN #1237',
      paymentMethod: 'Card',
      customerName: 'Samuel Mugisha',
      customerPhone: '0722987654',
      reference: 'PMT-20240601-004',
      walletId: 'WALLET-1',
    ),
    Transaction(
      id: 'TXN-1007',
      amount: 45000,
      currency: 'RWF',
      type: 'refund',
      status: 'failed',
      date: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      description: 'Refund for TXN #1233',
      paymentMethod: 'Bank',
      customerName: 'Innocent Habimana',
      customerPhone: '0733123499',
      reference: 'REF-20240530-002',
      walletId: 'WALLET-3',
    ),
    Transaction(
      id: 'TXN-1008',
      amount: 75000,
      currency: 'RWF',
      type: 'payment',
      status: 'success',
      date: DateTime.now().subtract(const Duration(hours: 1)),
      description: 'Payment to supplier',
      paymentMethod: 'Mobile Money',
      customerName: 'Gasana Jean',
      customerPhone: '0788123457',
      reference: 'PMT-20240601-005',
      walletId: 'WALLET-1',
    ),
    Transaction(
      id: 'TXN-1009',
      amount: 200000,
      currency: 'RWF',
      type: 'income',
      status: 'success',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      description: 'Salary payment',
      paymentMethod: 'Bank Transfer',
      customerName: 'Company XYZ',
      customerPhone: 'N/A',
      reference: 'INC-20240601-001',
      walletId: 'WALLET-2',
    ),
    Transaction(
      id: 'TXN-1010',
      amount: 35000,
      currency: 'RWF',
      type: 'expense',
      status: 'success',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      description: 'Utility bill payment',
      paymentMethod: 'Card',
      customerName: 'EWSA',
      customerPhone: 'N/A',
      reference: 'EXP-20240601-001',
      walletId: 'WALLET-1',
    ),
  ];

  // Get all transactions
  List<Transaction> getAllTransactions() {
    return List.from(_transactions);
  }

  // Get transactions by wallet ID
  List<Transaction> getTransactionsByWallet(String walletId) {
    // If no transactions found for this specific wallet, return some generic transactions
    final walletTransactions = _transactions.where((t) => t.walletId == walletId).toList();
    if (walletTransactions.isEmpty) {
      // Return some generic transactions for any wallet
      return [
        Transaction(
          id: 'TXN-GEN-001',
          amount: 25000,
          currency: 'RWF',
          type: 'payment',
          status: 'success',
          date: DateTime.now().subtract(const Duration(hours: 2)),
          description: 'Recent payment',
          paymentMethod: 'Mobile Money',
          customerName: 'Alice Umutoni',
          customerPhone: '0788123456',
          reference: 'PMT-${DateTime.now().millisecondsSinceEpoch}',
          walletId: walletId,
        ),
        Transaction(
          id: 'TXN-GEN-002',
          amount: 120000,
          currency: 'RWF',
          type: 'payment',
          status: 'pending',
          date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          description: 'Pending transaction',
          paymentMethod: 'Card',
          customerName: 'Eric Niyonsaba',
          customerPhone: '0722123456',
          reference: 'PMT-${DateTime.now().millisecondsSinceEpoch + 1}',
          walletId: walletId,
        ),
        Transaction(
          id: 'TXN-GEN-003',
          amount: 50000,
          currency: 'RWF',
          type: 'refund',
          status: 'success',
          date: DateTime.now().subtract(const Duration(days: 2)),
          description: 'Refund processed',
          paymentMethod: 'Bank',
          customerName: 'Claudine Mukamana',
          customerPhone: '0733123456',
          reference: 'REF-${DateTime.now().millisecondsSinceEpoch + 2}',
          walletId: walletId,
        ),
      ];
    }
    return walletTransactions;
  }

  // Add a new transaction
  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction); // Add to the beginning of the list
  }

  // Generate a unique transaction ID
  String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN-$timestamp-$random';
  }

  // Generate a payment reference
  String generatePaymentReference() {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final random = (DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    return 'PMT-$date-$time-$random';
  }

  // Simulate a payment and create a transaction
  Future<Transaction> simulatePayment({
    required String phoneNumber,
    required double amount,
    required String walletId,
    String? customerName,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Generate transaction data
    final transactionId = generateTransactionId();
    final reference = generatePaymentReference();
    final now = DateTime.now();
    
    // Create the transaction
    final transaction = Transaction(
      id: transactionId,
      amount: amount,
      currency: 'RWF',
      type: 'payment',
      status: 'success', // Simulate successful payment
      date: now,
      description: 'Payment to $phoneNumber',
      paymentMethod: 'Mobile Money',
      customerName: customerName ?? 'Unknown',
      customerPhone: phoneNumber,
      reference: reference,
      walletId: walletId,
    );
    
    // Add to the list
    addTransaction(transaction);
    
    return transaction;
  }
}
