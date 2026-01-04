// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wallet _$WalletFromJson(Map<String, dynamic> json) => Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      owners:
          (json['owners'] as List<dynamic>).map((e) => e as String).toList(),
      isDefault: json['isDefault'] as bool,
      description: json['description'] as String?,
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.parse(json['targetDate'] as String),
      walletCode: json['wallet_code'] as String?,
      isJoint: json['is_joint'] as bool?,
      account: json['account'] == null
          ? null
          : Account.fromJson(json['account'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WalletToJson(Wallet instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'balance': instance.balance,
      'currency': instance.currency,
      'type': instance.type,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'owners': instance.owners,
      'isDefault': instance.isDefault,
      'description': instance.description,
      'targetAmount': instance.targetAmount,
      'targetDate': instance.targetDate?.toIso8601String(),
      'wallet_code': instance.walletCode,
      'is_joint': instance.isJoint,
      'account': instance.account,
    };

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
      code: json['code'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'type': instance.type,
    };
