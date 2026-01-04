class PayrollRun {
  final String id;
  final String? periodId;
  final String? periodName;
  final DateTime runDate;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int? paymentTermsDays;
  final double totalAmount;
  final String status; // draft, processed, completed
  final List<PayrollPayslip> payslips;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PayrollRun({
    required this.id,
    this.periodId,
    this.periodName,
    required this.runDate,
    this.periodStart,
    this.periodEnd,
    this.paymentTermsDays,
    required this.totalAmount,
    required this.status,
    required this.payslips,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_id': periodId,
      'period_name': periodName,
      'run_date': runDate.toIso8601String(),
      'period_start': periodStart?.toIso8601String(),
      'period_end': periodEnd?.toIso8601String(),
      'payment_terms_days': paymentTermsDays,
      'total_amount': totalAmount,
      'status': status,
      'payslips': payslips.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    return PayrollRun(
      id: json['id'] as String,
      periodId: json['period_id'] as String?,
      periodName: json['period_name'] as String?,
      runDate: DateTime.parse(json['run_date'] as String),
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'] as String)
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.parse(json['period_end'] as String)
          : null,
      paymentTermsDays: json['payment_terms_days'] as int?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      payslips: (json['payslips'] as List<dynamic>?)
              ?.map((p) => PayrollPayslip.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  int get payslipsCount => payslips.length;
  double get totalGrossAmount =>
      payslips.fold(0.0, (sum, p) => sum + p.grossAmount);
  double get totalNetAmount =>
      payslips.fold(0.0, (sum, p) => sum + p.netAmount);
  double get totalDeductions =>
      payslips.fold(0.0, (sum, p) => sum + p.totalDeductions);
}

class PayrollPayslip {
  final String id;
  final String supplierAccountId;
  final String supplierName;
  final String? supplierCode;
  final double grossAmount;
  final double netAmount;
  final double totalDeductions;
  final int milkSalesCount;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final List<PayrollDeduction> deductions;
  final DateTime createdAt;

  PayrollPayslip({
    required this.id,
    required this.supplierAccountId,
    required this.supplierName,
    this.supplierCode,
    required this.grossAmount,
    required this.netAmount,
    required this.totalDeductions,
    required this.milkSalesCount,
    this.periodStart,
    this.periodEnd,
    required this.deductions,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_account_id': supplierAccountId,
      'supplier_name': supplierName,
      'supplier_code': supplierCode,
      'gross_amount': grossAmount,
      'net_amount': netAmount,
      'total_deductions': totalDeductions,
      'milk_sales_count': milkSalesCount,
      'period_start': periodStart?.toIso8601String(),
      'period_end': periodEnd?.toIso8601String(),
      'deductions': deductions.map((d) => d.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PayrollPayslip.fromJson(Map<String, dynamic> json) {
    return PayrollPayslip(
      id: json['id'] as String,
      supplierAccountId: json['supplier_account_id'] as String,
      supplierName: json['supplier_name'] as String,
      supplierCode: json['supplier_code'] as String?,
      grossAmount: (json['gross_amount'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      totalDeductions: (json['total_deductions'] as num).toDouble(),
      milkSalesCount: json['milk_sales_count'] as int,
      periodStart: json['period_start'] != null
          ? DateTime.parse(json['period_start'] as String)
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.parse(json['period_end'] as String)
          : null,
      deductions: (json['deductions'] as List<dynamic>?)
              ?.map((d) => PayrollDeduction.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PayrollDeduction {
  final String id;
  final String name;
  final String type; // fee, tax, other
  final double amount;
  final String? description;

  PayrollDeduction({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'description': description,
    };
  }

  factory PayrollDeduction.fromJson(Map<String, dynamic> json) {
    return PayrollDeduction(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }
}

