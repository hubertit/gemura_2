class IncomeStatement {
  final DateTime fromDate;
  final DateTime toDate;
  final double revenue;
  final double expenses;
  final double netIncome;

  IncomeStatement({
    required this.fromDate,
    required this.toDate,
    required this.revenue,
    required this.expenses,
    required this.netIncome,
  });

  factory IncomeStatement.fromJson(Map<String, dynamic> json) {
    return IncomeStatement(
      fromDate: DateTime.parse(json['from_date']),
      toDate: DateTime.parse(json['to_date']),
      revenue: (json['revenue'] as num).toDouble(),
      expenses: (json['expenses'] as num).toDouble(),
      netIncome: (json['net_income'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
      'revenue': revenue,
      'expenses': expenses,
      'net_income': netIncome,
    };
  }
}
