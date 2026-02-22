import 'package:intl/intl.dart';

enum RepaymentStatus {
  pending,
  completed,
  failed,
}

enum PaymentMethod {
  mobileMoney,
  bankTransfer,
  cash,
  card,
}

class LoanRepayment {
  final String id;
  final String loanId;
  final double amount;
  final PaymentMethod paymentMethod;
  final RepaymentStatus status;
  final DateTime paymentDate;
  final String? transactionId;
  final String? notes;
  final DateTime createdAt;

  const LoanRepayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paymentDate,
    this.transactionId,
    this.notes,
    required this.createdAt,
  });

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case RepaymentStatus.pending:
        return 'Pending';
      case RepaymentStatus.completed:
        return 'Completed';
      case RepaymentStatus.failed:
        return 'Failed';
    }
  }

  String get formattedAmount => NumberFormat('#,##0', 'en_US').format(amount);
  String get formattedDate => DateFormat('MMM dd, yyyy').format(paymentDate);
  String get formattedTime => DateFormat('HH:mm').format(paymentDate);

  LoanRepayment copyWith({
    String? id,
    String? loanId,
    double? amount,
    PaymentMethod? paymentMethod,
    RepaymentStatus? status,
    DateTime? paymentDate,
    String? transactionId,
    String? notes,
    DateTime? createdAt,
  }) {
    return LoanRepayment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loanId': loanId,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'paymentDate': paymentDate.toIso8601String(),
      'transactionId': transactionId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LoanRepayment.fromJson(Map<String, dynamic> json) {
    return LoanRepayment(
      id: json['id'],
      loanId: json['loanId'],
      amount: json['amount'].toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
      ),
      status: RepaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      paymentDate: DateTime.parse(json['paymentDate']),
      transactionId: json['transactionId'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 