class Transaction {
  final String id;
  final String type; // 'revenue' or 'expense'
  final double amount;
  final String description;
  final DateTime transactionDate;
  final String? categoryAccount;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.transactionDate,
    this.categoryAccount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      categoryAccount: json['category_account'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate.toIso8601String(),
      'category_account': categoryAccount,
    };
  }
}
