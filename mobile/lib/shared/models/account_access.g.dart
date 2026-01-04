// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_access.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountAccess _$AccountAccessFromJson(Map<String, dynamic> json) =>
    AccountAccess(
      id: json['id'] as String,
      accountOwnerId: json['accountOwnerId'] as String,
      grantedUserId: json['grantedUserId'] as String,
      role: json['role'] as String,
      permissions: json['permissions'] as Map<String, dynamic>,
      grantedAt: DateTime.parse(json['grantedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$AccountAccessToJson(AccountAccess instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountOwnerId': instance.accountOwnerId,
      'grantedUserId': instance.grantedUserId,
      'role': instance.role,
      'permissions': instance.permissions,
      'grantedAt': instance.grantedAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'isActive': instance.isActive,
    };

SharedAccount _$SharedAccountFromJson(Map<String, dynamic> json) =>
    SharedAccount(
      id: json['id'] as String,
      originalOwnerId: json['originalOwnerId'] as String,
      accountName: json['accountName'] as String,
      accountType: json['accountType'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      accessList: (json['accessList'] as List<dynamic>)
          .map((e) => AccountAccess.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SharedAccountToJson(SharedAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'originalOwnerId': instance.originalOwnerId,
      'accountName': instance.accountName,
      'accountType': instance.accountType,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'accessList': instance.accessList,
    };
