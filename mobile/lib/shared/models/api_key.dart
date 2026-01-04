import 'package:json_annotation/json_annotation.dart';

part 'api_key.g.dart';

@JsonSerializable()
class ApiKey {
  @JsonKey(name: 'id')
  final int id;
  
  @JsonKey(name: 'key_name')
  final String keyName;
  
  @JsonKey(name: 'key_type')
  final String keyType;
  
  @JsonKey(name: 'key_value')
  final String keyValue;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'created_at')
  final String createdAt;
  
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  ApiKey({
    required this.id,
    required this.keyName,
    required this.keyType,
    required this.keyValue,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiKey.fromJson(Map<String, dynamic> json) => _$ApiKeyFromJson(json);
  Map<String, dynamic> toJson() => _$ApiKeyToJson(this);
}

@JsonSerializable()
class ApiKeysResponse {
  final int code;
  final String status;
  final String message;
  final ApiKeysData data;

  ApiKeysResponse({
    required this.code,
    required this.status,
    required this.message,
    required this.data,
  });

  factory ApiKeysResponse.fromJson(Map<String, dynamic> json) => _$ApiKeysResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ApiKeysResponseToJson(this);
}

@JsonSerializable()
class ApiKeysData {
  @JsonKey(name: 'api_keys')
  final List<ApiKey> apiKeys;
  
  @JsonKey(name: 'total_keys')
  final int totalKeys;

  ApiKeysData({
    required this.apiKeys,
    required this.totalKeys,
  });

  factory ApiKeysData.fromJson(Map<String, dynamic> json) => _$ApiKeysDataFromJson(json);
  Map<String, dynamic> toJson() => _$ApiKeysDataToJson(this);
}
