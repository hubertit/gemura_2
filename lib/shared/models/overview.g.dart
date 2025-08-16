// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Overview _$OverviewFromJson(Map<String, dynamic> json) => Overview(
      summary:
          OverviewSummary.fromJson(json['summary'] as Map<String, dynamic>),
      breakdownType: json['breakdown_type'] as String,
      breakdown: (json['breakdown'] as List<dynamic>)
          .map((e) => OverviewBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      dateRange: OverviewDateRange.fromJson(
          json['date_range'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OverviewToJson(Overview instance) => <String, dynamic>{
      'summary': instance.summary,
      'breakdown_type': instance.breakdownType,
      'breakdown': instance.breakdown,
      'date_range': instance.dateRange,
    };

OverviewSummary _$OverviewSummaryFromJson(Map<String, dynamic> json) =>
    OverviewSummary(
      collection: OverviewCollection.fromJson(
          json['collection'] as Map<String, dynamic>),
      sales: OverviewSales.fromJson(json['sales'] as Map<String, dynamic>),
      suppliers:
          OverviewSuppliers.fromJson(json['suppliers'] as Map<String, dynamic>),
      customers:
          OverviewCustomers.fromJson(json['customers'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OverviewSummaryToJson(OverviewSummary instance) =>
    <String, dynamic>{
      'collection': instance.collection,
      'sales': instance.sales,
      'suppliers': instance.suppliers,
      'customers': instance.customers,
    };

OverviewCollection _$OverviewCollectionFromJson(Map<String, dynamic> json) =>
    OverviewCollection(
      liters: (json['liters'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      transactions: (json['transactions'] as num).toInt(),
    );

Map<String, dynamic> _$OverviewCollectionToJson(OverviewCollection instance) =>
    <String, dynamic>{
      'liters': instance.liters,
      'value': instance.value,
      'transactions': instance.transactions,
    };

OverviewSales _$OverviewSalesFromJson(Map<String, dynamic> json) =>
    OverviewSales(
      liters: (json['liters'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      transactions: (json['transactions'] as num).toInt(),
    );

Map<String, dynamic> _$OverviewSalesToJson(OverviewSales instance) =>
    <String, dynamic>{
      'liters': instance.liters,
      'value': instance.value,
      'transactions': instance.transactions,
    };

OverviewSuppliers _$OverviewSuppliersFromJson(Map<String, dynamic> json) =>
    OverviewSuppliers(
      active: (json['active'] as num).toInt(),
      inactive: (json['inactive'] as num).toInt(),
    );

Map<String, dynamic> _$OverviewSuppliersToJson(OverviewSuppliers instance) =>
    <String, dynamic>{
      'active': instance.active,
      'inactive': instance.inactive,
    };

OverviewCustomers _$OverviewCustomersFromJson(Map<String, dynamic> json) =>
    OverviewCustomers(
      active: (json['active'] as num).toInt(),
      inactive: (json['inactive'] as num).toInt(),
    );

Map<String, dynamic> _$OverviewCustomersToJson(OverviewCustomers instance) =>
    <String, dynamic>{
      'active': instance.active,
      'inactive': instance.inactive,
    };

OverviewBreakdown _$OverviewBreakdownFromJson(Map<String, dynamic> json) =>
    OverviewBreakdown(
      label: json['label'] as String,
      month: json['month'] as String?,
      collection: OverviewBreakdownData.fromJson(
          json['collection'] as Map<String, dynamic>),
      sales:
          OverviewBreakdownData.fromJson(json['sales'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OverviewBreakdownToJson(OverviewBreakdown instance) =>
    <String, dynamic>{
      'label': instance.label,
      'month': instance.month,
      'collection': instance.collection,
      'sales': instance.sales,
    };

OverviewBreakdownData _$OverviewBreakdownDataFromJson(
        Map<String, dynamic> json) =>
    OverviewBreakdownData(
      liters: (json['liters'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
    );

Map<String, dynamic> _$OverviewBreakdownDataToJson(
        OverviewBreakdownData instance) =>
    <String, dynamic>{
      'liters': instance.liters,
      'value': instance.value,
    };

OverviewDateRange _$OverviewDateRangeFromJson(Map<String, dynamic> json) =>
    OverviewDateRange(
      from: json['from'] as String,
      to: json['to'] as String,
    );

Map<String, dynamic> _$OverviewDateRangeToJson(OverviewDateRange instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
    };
