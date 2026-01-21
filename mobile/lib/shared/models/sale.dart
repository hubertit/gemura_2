import 'package:json_annotation/json_annotation.dart';

part 'sale.g.dart';

@JsonSerializable(includeIfNull: false)
class Sale {
  final String id;
  @JsonKey(name: 'quantity', fromJson: _stringFromJson)
  final String quantity;
  @JsonKey(name: 'unit_price', fromJson: _stringFromJson)
  final String unitPrice;
  @JsonKey(name: 'total_amount', fromJson: _stringFromJson)
  final String totalAmount;
  final String status;
  @JsonKey(name: 'sale_at')
  final String saleAt;
  final String? notes;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'supplier_account')
  final SaleAccount? supplierAccount;
  @JsonKey(name: 'customer_account')
  final SaleAccount? customerAccount;

  Sale({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.status,
    required this.saleAt,
    this.notes,
    required this.createdAt,
    this.supplierAccount,
    this.customerAccount,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
  Map<String, dynamic> toJson() => _$SaleToJson(this);

  // Helper function to convert int/double/num to String
  static String _stringFromJson(dynamic value) {
    if (value == null) return '0';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }

  // Convenience getters for backward compatibility
  double get quantityAsDouble => double.tryParse(quantity) ?? 0.0;
  double get unitPriceAsDouble => double.tryParse(unitPrice) ?? 0.0;
  double get totalAmountAsDouble => double.tryParse(totalAmount) ?? 0.0;
  DateTime get saleAtDateTime => DateTime.tryParse(saleAt) ?? DateTime.now();
  DateTime get createdAtDateTime => DateTime.tryParse(createdAt) ?? DateTime.now();
}

@JsonSerializable(includeIfNull: false)
class SaleAccount {
  final String? id; // UUID for account
  final String? code;
  final String? name;
  final String? type;
  final String? status;
  final String? currency;

  SaleAccount({
    this.id,
    this.code,
    this.name,
    this.type,
    this.status,
    this.currency,
  });

  factory SaleAccount.fromJson(Map<String, dynamic> json) => _$SaleAccountFromJson(json);
  Map<String, dynamic> toJson() => _$SaleAccountToJson(this);
}
