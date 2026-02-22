import 'package:json_annotation/json_annotation.dart';

part 'wallet.g.dart';

@JsonSerializable()
class Wallet {
  final String id;
  final String name;
  final double balance;
  final String currency;
  final String type;
  final String status;
  final DateTime createdAt;
  final List<String> owners;
  final bool isDefault;
  final String? description;
  final double? targetAmount;
  final DateTime? targetDate;

  // API-specific fields
  @JsonKey(name: 'wallet_code')
  final String? walletCode;
  @JsonKey(name: 'is_joint')
  final bool? isJoint;
  final Account? account;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.owners,
    required this.isDefault,
    this.description,
    this.targetAmount,
    this.targetDate,
    this.walletCode,
    this.isJoint,
    this.account,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  Map<String, dynamic> toJson() => _$WalletToJson(this);

  // Factory method to create from API response
  factory Wallet.fromApiResponse(Map<String, dynamic> json) {
    return Wallet(
      id: json['wallet_code'] ?? '',
      name: json['account']?['name'] ?? 'Unknown Wallet',
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'RWF',
      type: json['type'] ?? 'regular',
      status: json['status'] ?? 'active',
      createdAt: DateTime.now(), // API doesn't provide this, using current time
      owners: [json['account']?['name'] ?? 'Unknown'],
      isDefault: json['is_default'] ?? false,
      walletCode: json['wallet_code'],
      isJoint: json['is_joint'] ?? false,
      account: json['account'] != null ? Account.fromJson(json['account']) : null,
    );
  }

  // Copy with method for updating wallet data
  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    String? currency,
    String? type,
    String? status,
    DateTime? createdAt,
    List<String>? owners,
    bool? isDefault,
    String? description,
    double? targetAmount,
    DateTime? targetDate,
    String? walletCode,
    bool? isJoint,
    Account? account,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      owners: owners ?? this.owners,
      isDefault: isDefault ?? this.isDefault,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      walletCode: walletCode ?? this.walletCode,
      isJoint: isJoint ?? this.isJoint,
      account: account ?? this.account,
    );
  }
}

@JsonSerializable()
class Account {
  final String code;
  final String name;
  final String type;

  Account({
    required this.code,
    required this.name,
    required this.type,
  });

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

  Map<String, dynamic> toJson() => _$AccountToJson(this);
} 