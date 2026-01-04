import 'package:flutter/material.dart';

enum LoanType {
  cash,
  device,
  float,
  product,
}

enum LoanStatus {
  pending,
  approved,
  active,
  completed,
  rejected,
  overdue,
}

class Loan {
  final String id;
  final String name;
  final String description;
  final LoanType type;
  final double amount;
  final double interestRate;
  final int termInMonths;
  final DateTime startDate;
  final DateTime dueDate;
  final LoanStatus status;
  final String walletId;
  final List<String> guarantors;
  final Map<String, dynamic>? collateral;
  final String? purpose;
  final double? monthlyPayment;
  final double? totalRepayment;
  final double? remainingBalance;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Loan({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.amount,
    required this.interestRate,
    required this.termInMonths,
    required this.startDate,
    required this.dueDate,
    required this.status,
    required this.walletId,
    required this.guarantors,
    this.collateral,
    this.purpose,
    this.monthlyPayment,
    this.totalRepayment,
    this.remainingBalance,
    required this.createdAt,
    this.updatedAt,
  });

  // Getters
  double get progressPercentage {
    if (status == LoanStatus.completed) return 100.0;
    if (status == LoanStatus.pending || status == LoanStatus.rejected) return 0.0;
    
    final totalDays = dueDate.difference(startDate).inDays;
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    
    if (elapsedDays <= 0) return 0.0;
    if (elapsedDays >= totalDays) return 100.0;
    
    return (elapsedDays / totalDays) * 100;
  }

  int get daysRemaining {
    final remaining = dueDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  bool get isOverdue => status == LoanStatus.overdue || 
      (status == LoanStatus.active && DateTime.now().isAfter(dueDate));

  String get typeDisplayName {
    switch (type) {
      case LoanType.cash:
        return 'Cash Loan';
      case LoanType.device:
        return 'Device/Equipment Loan';
      case LoanType.float:
        return 'Float Loan';
      case LoanType.product:
        return 'Product Loan';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case LoanStatus.pending:
        return 'Pending';
      case LoanStatus.approved:
        return 'Approved';
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.completed:
        return 'Completed';
      case LoanStatus.rejected:
        return 'Rejected';
      case LoanStatus.overdue:
        return 'Overdue';
    }
  }

  Color get statusColor {
    switch (status) {
      case LoanStatus.pending:
        return const Color(0xFFFFA000); // Warning/Orange
      case LoanStatus.approved:
        return const Color(0xFF2196F3); // Blue
      case LoanStatus.active:
        return const Color(0xFF4CAF50); // Green
      case LoanStatus.completed:
        return const Color(0xFF4CAF50); // Green
      case LoanStatus.rejected:
        return const Color(0xFFE53935); // Red
      case LoanStatus.overdue:
        return const Color(0xFFE53935); // Red
    }
  }

  // Methods
  Loan copyWith({
    String? id,
    String? name,
    String? description,
    LoanType? type,
    double? amount,
    double? interestRate,
    int? termInMonths,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus? status,
    String? walletId,
    List<String>? guarantors,
    Map<String, dynamic>? collateral,
    String? purpose,
    double? monthlyPayment,
    double? totalRepayment,
    double? remainingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      interestRate: interestRate ?? this.interestRate,
      termInMonths: termInMonths ?? this.termInMonths,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      walletId: walletId ?? this.walletId,
      guarantors: guarantors ?? this.guarantors,
      collateral: collateral ?? this.collateral,
      purpose: purpose ?? this.purpose,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      totalRepayment: totalRepayment ?? this.totalRepayment,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'amount': amount,
      'interestRate': interestRate,
      'termInMonths': termInMonths,
      'startDate': startDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'walletId': walletId,
      'guarantors': guarantors,
      'collateral': collateral,
      'purpose': purpose,
      'monthlyPayment': monthlyPayment,
      'totalRepayment': totalRepayment,
      'remainingBalance': remainingBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: LoanType.values.firstWhere((e) => e.name == json['type']),
      amount: (json['amount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      termInMonths: json['termInMonths'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: LoanStatus.values.firstWhere((e) => e.name == json['status']),
      walletId: json['walletId'] as String,
      guarantors: List<String>.from(json['guarantors']),
      collateral: json['collateral'] as Map<String, dynamic>?,
      purpose: json['purpose'] as String?,
      monthlyPayment: json['monthlyPayment'] != null ? (json['monthlyPayment'] as num).toDouble() : null,
      totalRepayment: json['totalRepayment'] != null ? (json['totalRepayment'] as num).toDouble() : null,
      remainingBalance: json['remainingBalance'] != null ? (json['remainingBalance'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
} 