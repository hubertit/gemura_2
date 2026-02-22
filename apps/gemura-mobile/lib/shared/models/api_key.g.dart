// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiKey _$ApiKeyFromJson(Map<String, dynamic> json) => ApiKey(
      id: (json['id'] as num).toInt(),
      keyName: json['key_name'] as String,
      keyType: json['key_type'] as String,
      keyValue: json['key_value'] as String,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$ApiKeyToJson(ApiKey instance) => <String, dynamic>{
      'id': instance.id,
      'key_name': instance.keyName,
      'key_type': instance.keyType,
      'key_value': instance.keyValue,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

ApiKeysResponse _$ApiKeysResponseFromJson(Map<String, dynamic> json) =>
    ApiKeysResponse(
      code: (json['code'] as num).toInt(),
      status: json['status'] as String,
      message: json['message'] as String,
      data: ApiKeysData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ApiKeysResponseToJson(ApiKeysResponse instance) =>
    <String, dynamic>{
      'code': instance.code,
      'status': instance.status,
      'message': instance.message,
      'data': instance.data,
    };

ApiKeysData _$ApiKeysDataFromJson(Map<String, dynamic> json) => ApiKeysData(
      apiKeys: (json['api_keys'] as List<dynamic>)
          .map((e) => ApiKey.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalKeys: (json['total_keys'] as num).toInt(),
    );

Map<String, dynamic> _$ApiKeysDataToJson(ApiKeysData instance) =>
    <String, dynamic>{
      'api_keys': instance.apiKeys,
      'total_keys': instance.totalKeys,
    };
