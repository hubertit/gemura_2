import 'package:json_annotation/json_annotation.dart';

part 'customer.g.dart';

@JsonSerializable()
class Customer {
  final String relationshipId;
  final double pricePerLiter;
  final double averageSupplyQuantity;
  final String relationshipStatus;
  final CustomerUser customer;

  Customer({
    required this.relationshipId,
    required this.pricePerLiter,
    required this.averageSupplyQuantity,
    required this.relationshipStatus,
    required this.customer,
  });

  factory Customer.fromApiResponse(Map<String, dynamic> json) {
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

    return Customer(
      relationshipId: _parseString(json['relationship_id']),
      pricePerLiter: _parseDouble(json['price_per_liter']),
      averageSupplyQuantity: _parseDouble(json['average_supply_quantity']),
      relationshipStatus: _parseString(json['relationship_status']),
      customer: CustomerUser.fromApiResponse(json),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  Customer copyWith({
    String? relationshipId,
    double? pricePerLiter,
    double? averageSupplyQuantity,
    String? relationshipStatus,
    CustomerUser? customer,
  }) {
    return Customer(
      relationshipId: relationshipId ?? this.relationshipId,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      averageSupplyQuantity: averageSupplyQuantity ?? this.averageSupplyQuantity,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      customer: customer ?? this.customer,
    );
  }

  // Convenience getters for backward compatibility
  String get id => relationshipId;
  String get name => customer.name;
  String get phone => customer.phone;
  String? get email => customer.email;
  String? get nid => customer.nid;
  String? get address => customer.address;
  String get userCode => customer.userCode;
  String get accountCode => customer.accountCode;
  String get accountName => customer.accountName;
  String? get accountId => customer.accountId;
  bool get isActive => relationshipStatus == 'active';
}

@JsonSerializable()
class CustomerUser {
  final String userCode;
  final String name;
  final String phone;
  final String? email;
  final String? nid;
  final String? address;
  final String accountCode;
  final String accountName;
  final String? accountId; // UUID for API calls

  CustomerUser({
    required this.userCode,
    required this.name,
    required this.phone,
    this.email,
    this.nid,
    this.address,
    required this.accountCode,
    required this.accountName,
    this.accountId,
  });

  factory CustomerUser.fromApiResponse(Map<String, dynamic> json) {
    // Helper function to safely convert to string
    String _parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    final account = json['account'] as Map<String, dynamic>?;
    return CustomerUser(
      userCode: _parseString(json['code']),
      name: _parseString(json['name']),
      phone: _parseString(json['phone']),
      email: json['email'] != null ? _parseString(json['email']) : null,
      nid: json['nid'] != null ? _parseString(json['nid']) : null,
      address: json['address'] != null ? _parseString(json['address']) : null,
      accountCode: account != null ? _parseString(account['code']) : '',
      accountName: account != null ? _parseString(account['name']) : '',
      accountId: account != null ? _parseString(account['id']) : null,
    );
  }

  factory CustomerUser.fromJson(Map<String, dynamic> json) => _$CustomerUserFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerUserToJson(this);

  CustomerUser copyWith({
    String? userCode,
    String? name,
    String? phone,
    String? email,
    String? nid,
    String? address,
    String? accountCode,
    String? accountName,
    String? accountId,
  }) {
    return CustomerUser(
      userCode: userCode ?? this.userCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nid: nid ?? this.nid,
      address: address ?? this.address,
      accountCode: accountCode ?? this.accountCode,
      accountName: accountName ?? this.accountName,
      accountId: accountId ?? this.accountId,
    );
  }
}
