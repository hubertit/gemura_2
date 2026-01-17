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
    return Customer(
      relationshipId: json['relationship_id'] ?? '',
      pricePerLiter: double.tryParse(json['price_per_liter'] ?? '0') ?? 0.0,
      averageSupplyQuantity: double.tryParse(json['average_supply_quantity'] ?? '0') ?? 0.0,
      relationshipStatus: json['relationship_status'] ?? 'inactive',
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

  CustomerUser({
    required this.userCode,
    required this.name,
    required this.phone,
    this.email,
    this.nid,
    this.address,
    required this.accountCode,
    required this.accountName,
  });

  factory CustomerUser.fromApiResponse(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>?;
    return CustomerUser(
      userCode: json['code'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      nid: json['nid'],
      address: json['address'],
      accountCode: account?['code'] ?? '', // Extract from nested account object
      accountName: account?['name'] ?? '', // Extract from nested account object
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
    );
  }
}
