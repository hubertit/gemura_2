class Receivable {
  final String saleId;
  /// Source of receivable: 'milk_sale' (milk collections) or 'inventory_sale' (inventory sold to suppliers on debt).
  /// Determines which API endpoint to use when recording payment.
  final String source;
  final CustomerInfo customer;
  final DateTime saleDate;
  final double quantity;
  final double unitPrice;
  final double totalAmount;
  final double amountPaid;
  final double outstanding;
  final String paymentStatus;
  final int daysOutstanding;
  final String agingBucket;
  final String? notes;

  Receivable({
    required this.saleId,
    this.source = 'milk_sale',
    required this.customer,
    required this.saleDate,
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

  factory Receivable.fromJson(Map<String, dynamic> json) {
    return Receivable(
      saleId: json['sale_id'] as String,
      source: json['source'] as String? ?? 'milk_sale',
      customer: CustomerInfo.fromJson(json['customer'] as Map<String, dynamic>),
      saleDate: DateTime.parse(json['sale_date'] as String),
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

class CustomerInfo {
  final String id;
  final String code;
  final String name;

  CustomerInfo({
    required this.id,
    required this.code,
    required this.name,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }
}

class ReceivablesSummary {
  final double totalReceivables;
  final int totalInvoices;
  final List<CustomerReceivables> byCustomer;
  final AgingSummary agingSummary;
  final List<Receivable> allReceivables;

  ReceivablesSummary({
    required this.totalReceivables,
    required this.totalInvoices,
    required this.byCustomer,
    required this.agingSummary,
    required this.allReceivables,
  });

  factory ReceivablesSummary.fromJson(Map<String, dynamic> json) {
    return ReceivablesSummary(
      totalReceivables: (json['total_receivables'] as num).toDouble(),
      totalInvoices: json['total_invoices'] as int,
      byCustomer: (json['by_customer'] as List<dynamic>)
          .map((e) => CustomerReceivables.fromJson(e as Map<String, dynamic>))
          .toList(),
      agingSummary: AgingSummary.fromJson(json['aging_summary'] as Map<String, dynamic>),
      allReceivables: (json['all_receivables'] as List<dynamic>)
          .map((e) => Receivable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CustomerReceivables {
  final CustomerInfo customer;
  final double totalOutstanding;
  final int invoiceCount;
  final List<Receivable> invoices;

  CustomerReceivables({
    required this.customer,
    required this.totalOutstanding,
    required this.invoiceCount,
    required this.invoices,
  });

  factory CustomerReceivables.fromJson(Map<String, dynamic> json) {
    return CustomerReceivables(
      customer: CustomerInfo.fromJson(json['customer'] as Map<String, dynamic>),
      totalOutstanding: (json['total_outstanding'] as num).toDouble(),
      invoiceCount: json['invoice_count'] as int,
      invoices: (json['invoices'] as List<dynamic>)
          .map((e) => Receivable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AgingSummary {
  final double current;
  final double days31_60;
  final double days61_90;
  final double days90Plus;

  AgingSummary({
    required this.current,
    required this.days31_60,
    required this.days61_90,
    required this.days90Plus,
  });

  factory AgingSummary.fromJson(Map<String, dynamic> json) {
    return AgingSummary(
      current: (json['current'] as num).toDouble(),
      days31_60: (json['days_31_60'] as num).toDouble(),
      days61_90: (json['days_61_90'] as num).toDouble(),
      days90Plus: (json['days_90_plus'] as num).toDouble(),
    );
  }
}
