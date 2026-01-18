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
    // Helper function to safely convert to double (handles both string and number)
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Helper function to safely convert to string
    String _parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    return Supplier(
      relationshipId: _parseString(json['relationship_id']),
      pricePerLiter: _parseDouble(json['price_per_liter']),
      averageSupplyQuantity: _parseDouble(json['average_supply_quantity']),
      relationshipStatus: _parseString(json['relationship_status']),
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
    // Helper function to safely convert to string
    String _parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    final account = json['account'] as Map<String, dynamic>?;
    return SupplierUser(
      userCode: _parseString(json['code']),
      name: _parseString(json['name']),
      phone: _parseString(json['phone']),
      email: json['email'] != null ? _parseString(json['email']) : null,
      nid: json['nid'] != null ? _parseString(json['nid']) : null,
      address: json['address'] != null ? _parseString(json['address']) : null,
      accountCode: account != null ? _parseString(account['code']) : '',
      accountName: account != null ? _parseString(account['name']) : '',
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
