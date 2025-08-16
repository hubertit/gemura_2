import 'package:json_annotation/json_annotation.dart';

part 'overview.g.dart';

@JsonSerializable()
class Overview {
  final OverviewSummary summary;
  @JsonKey(name: 'breakdown_type')
  final String breakdownType;
  final List<OverviewBreakdown> breakdown;
  @JsonKey(name: 'date_range')
  final OverviewDateRange dateRange;

  Overview({
    required this.summary,
    required this.breakdownType,
    required this.breakdown,
    required this.dateRange,
  });

  factory Overview.fromJson(Map<String, dynamic> json) => _$OverviewFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewToJson(this);
}

@JsonSerializable()
class OverviewSummary {
  final OverviewCollection collection;
  final OverviewSales sales;
  final OverviewSuppliers suppliers;
  final OverviewCustomers customers;

  OverviewSummary({
    required this.collection,
    required this.sales,
    required this.suppliers,
    required this.customers,
  });

  factory OverviewSummary.fromJson(Map<String, dynamic> json) => _$OverviewSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewSummaryToJson(this);
}

@JsonSerializable()
class OverviewCollection {
  final double liters;
  final double value;
  final int transactions;

  OverviewCollection({
    required this.liters,
    required this.value,
    required this.transactions,
  });

  factory OverviewCollection.fromJson(Map<String, dynamic> json) => _$OverviewCollectionFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewCollectionToJson(this);
}

@JsonSerializable()
class OverviewSales {
  final double liters;
  final double value;
  final int transactions;

  OverviewSales({
    required this.liters,
    required this.value,
    required this.transactions,
  });

  factory OverviewSales.fromJson(Map<String, dynamic> json) => _$OverviewSalesFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewSalesToJson(this);
}

@JsonSerializable()
class OverviewSuppliers {
  final int active;
  final int inactive;

  OverviewSuppliers({
    required this.active,
    required this.inactive,
  });

  factory OverviewSuppliers.fromJson(Map<String, dynamic> json) => _$OverviewSuppliersFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewSuppliersToJson(this);
}

@JsonSerializable()
class OverviewCustomers {
  final int active;
  final int inactive;

  OverviewCustomers({
    required this.active,
    required this.inactive,
  });

  factory OverviewCustomers.fromJson(Map<String, dynamic> json) => _$OverviewCustomersFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewCustomersToJson(this);
}

@JsonSerializable()
class OverviewBreakdown {
  final String label;
  final String? month;
  final OverviewBreakdownData collection;
  final OverviewBreakdownData sales;

  OverviewBreakdown({
    required this.label,
    this.month,
    required this.collection,
    required this.sales,
  });

  factory OverviewBreakdown.fromJson(Map<String, dynamic> json) => _$OverviewBreakdownFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewBreakdownToJson(this);
}

@JsonSerializable()
class OverviewBreakdownData {
  final double liters;
  final double value;

  OverviewBreakdownData({
    required this.liters,
    required this.value,
  });

  factory OverviewBreakdownData.fromJson(Map<String, dynamic> json) => _$OverviewBreakdownDataFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewBreakdownDataToJson(this);
}

@JsonSerializable()
class OverviewDateRange {
  final String from;
  final String to;

  OverviewDateRange({
    required this.from,
    required this.to,
  });

  factory OverviewDateRange.fromJson(Map<String, dynamic> json) => _$OverviewDateRangeFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewDateRangeToJson(this);
}
