import 'receivable.dart';

class Payable {
  final String collectionId;
  final SupplierInfo supplier;
  final DateTime collectionDate;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final double amountPaid;
  final double outstanding;
  final String paymentStatus;
  final int daysOutstanding;
  final String agingBucket;
  final String? notes;

  Payable({
    required this.collectionId,
    required this.supplier,
    required this.collectionDate,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.amountPaid,
    required this.outstanding,
    required this.paymentStatus,
    required this.daysOutstanding,
    required this.agingBucket,
    this.notes,
  });

  factory Payable.fromJson(Map<String, dynamic> json) {
    return Payable(
      collectionId: json['collection_id'] as String,
      supplier: SupplierInfo.fromJson(json['supplier'] as Map<String, dynamic>),
      collectionDate: DateTime.parse(json['collection_date'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      outstanding: (json['outstanding'] as num).toDouble(),
      paymentStatus: json['payment_status'] as String,
      daysOutstanding: json['days_outstanding'] as int,
      agingBucket: json['aging_bucket'] as String,
      notes: json['notes'] as String?,
    );
  }
}

class SupplierInfo {
  final String id;
  final String code;
  final String name;

  SupplierInfo({
    required this.id,
    required this.code,
    required this.name,
  });

  factory SupplierInfo.fromJson(Map<String, dynamic> json) {
    return SupplierInfo(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

class PayablesSummary {
  final double totalPayables;
  final int totalInvoices;
  final List<SupplierPayables> bySupplier;
  final AgingSummary agingSummary;
  final List<Payable> allPayables;

  PayablesSummary({
    required this.totalPayables,
    required this.totalInvoices,
    required this.bySupplier,
    required this.agingSummary,
    required this.allPayables,
  });

  factory PayablesSummary.fromJson(Map<String, dynamic> json) {
    return PayablesSummary(
      totalPayables: (json['total_payables'] as num).toDouble(),
      totalInvoices: json['total_invoices'] as int,
      bySupplier: (json['by_supplier'] as List<dynamic>)
          .map((e) => SupplierPayables.fromJson(e as Map<String, dynamic>))
          .toList(),
      agingSummary: AgingSummary.fromJson(json['aging_summary'] as Map<String, dynamic>),
      allPayables: (json['all_payables'] as List<dynamic>)
          .map((e) => Payable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SupplierPayables {
  final SupplierInfo supplier;
  final double totalOutstanding;
  final int invoiceCount;
  final List<Payable> invoices;

  SupplierPayables({
    required this.supplier,
    required this.totalOutstanding,
    required this.invoiceCount,
    required this.invoices,
  });

  factory SupplierPayables.fromJson(Map<String, dynamic> json) {
    return SupplierPayables(
      supplier: SupplierInfo.fromJson(json['supplier'] as Map<String, dynamic>),
      totalOutstanding: (json['total_outstanding'] as num).toDouble(),
      invoiceCount: json['invoice_count'] as int,
      invoices: (json['invoices'] as List<dynamic>)
          .map((e) => Payable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
