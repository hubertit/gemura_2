// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sale _$SaleFromJson(Map<String, dynamic> json) => Sale(
      id: json['id'] as String,
      quantity: Sale._stringFromJson(json['quantity']),
      unitPrice: Sale._stringFromJson(json['unit_price']),
      totalAmount: Sale._stringFromJson(json['total_amount']),
      status: json['status'] as String,
      saleAt: json['sale_at'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      supplierAccount: json['supplier_account'] == null
          ? null
          : SaleAccount.fromJson(
              json['supplier_account'] as Map<String, dynamic>),
      customerAccount: json['customer_account'] == null
          ? null
          : SaleAccount.fromJson(
              json['customer_account'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SaleToJson(Sale instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'quantity': instance.quantity,
    'unit_price': instance.unitPrice,
    'total_amount': instance.totalAmount,
    'status': instance.status,
    'sale_at': instance.saleAt,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('notes', instance.notes);
  val['created_at'] = instance.createdAt;
  writeNotNull('supplier_account', instance.supplierAccount);
  writeNotNull('customer_account', instance.customerAccount);
  return val;
}

SaleAccount _$SaleAccountFromJson(Map<String, dynamic> json) => SaleAccount(
      id: json['id'] as String?,
      code: json['code'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      currency: json['currency'] as String?,
    );

Map<String, dynamic> _$SaleAccountToJson(SaleAccount instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('code', instance.code);
  writeNotNull('name', instance.name);
  writeNotNull('type', instance.type);
  writeNotNull('status', instance.status);
  writeNotNull('currency', instance.currency);
  return val;
}
