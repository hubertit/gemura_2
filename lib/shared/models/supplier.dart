import 'package:json_annotation/json_annotation.dart';

part 'supplier.g.dart';

@JsonSerializable()
class Supplier {
  final String relationshipId;
  final double pricePerLiter;
  final double averageSupplyQuantity;
  final String relationshipStatus;
  final SupplierUser supplier;

  Supplier({
    required this.relationshipId,
    required this.pricePerLiter,
    required this.averageSupplyQuantity,
    required this.relationshipStatus,
    required this.supplier,
  });

  factory Supplier.fromApiResponse(Map<String, dynamic> json) {
    return Supplier(
      relationshipId: json['relationship_id'] ?? '',
      pricePerLiter: double.tryParse(json['price_per_liter'] ?? '0') ?? 0.0,
      averageSupplyQuantity: double.tryParse(json['average_supply_quantity'] ?? '0') ?? 0.0,
      relationshipStatus: json['relationship_status'] ?? 'inactive',
      supplier: SupplierUser.fromApiResponse(json),
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);
  Map<String, dynamic> toJson() => _$SupplierToJson(this);

  Supplier copyWith({
    String? relationshipId,
    double? pricePerLiter,
    double? averageSupplyQuantity,
    String? relationshipStatus,
    SupplierUser? supplier,
  }) {
    return Supplier(
      relationshipId: relationshipId ?? this.relationshipId,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      averageSupplyQuantity: averageSupplyQuantity ?? this.averageSupplyQuantity,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      supplier: supplier ?? this.supplier,
    );
  }

  // Convenience getters for backward compatibility
  String get id => relationshipId;
  String get name => supplier.name;
  String get phone => supplier.phone;
  String? get email => supplier.email;
  String? get nid => supplier.nid;
  String? get address => supplier.address;
  String get userCode => supplier.userCode;
  String get accountCode => supplier.accountCode;
  String get accountName => supplier.accountName;
  bool get isActive => relationshipStatus == 'active';
}

@JsonSerializable()
class SupplierUser {
  final String userCode;
  final String name;
  final String phone;
  final String? email;
  final String? nid;
  final String? address;
  final String accountCode;
  final String accountName;

  SupplierUser({
    required this.userCode,
    required this.name,
    required this.phone,
    this.email,
    this.nid,
    this.address,
    required this.accountCode,
    required this.accountName,
  });

  factory SupplierUser.fromApiResponse(Map<String, dynamic> json) {
    return SupplierUser(
      userCode: json['code'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      nid: json['nid'],
      address: json['address'],
      accountCode: json['code'] ?? '', // Using code as account code for now
      accountName: json['name'] ?? '', // Using name as account name for now
    );
  }

  factory SupplierUser.fromJson(Map<String, dynamic> json) => _$SupplierUserFromJson(json);
  Map<String, dynamic> toJson() => _$SupplierUserToJson(this);

  SupplierUser copyWith({
    String? userCode,
    String? name,
    String? phone,
    String? email,
    String? nid,
    String? address,
    String? accountCode,
    String? accountName,
  }) {
    return SupplierUser(
      userCode: userCode ?? this.userCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nid: nid ?? this.nid,
      address: address ?? this.address,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
    );
  }
}
