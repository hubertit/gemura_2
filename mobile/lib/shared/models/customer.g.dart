// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
      relationshipId: json['relationshipId'] as String,
      pricePerLiter: (json['pricePerLiter'] as num).toDouble(),
      averageSupplyQuantity: (json['averageSupplyQuantity'] as num).toDouble(),
      relationshipStatus: json['relationshipStatus'] as String,
      customer: CustomerUser.fromJson(json['customer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
      'relationshipId': instance.relationshipId,
      'pricePerLiter': instance.pricePerLiter,
      'averageSupplyQuantity': instance.averageSupplyQuantity,
      'relationshipStatus': instance.relationshipStatus,
      'customer': instance.customer,
    };

CustomerUser _$CustomerUserFromJson(Map<String, dynamic> json) => CustomerUser(
      userCode: json['userCode'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      nid: json['nid'] as String?,
      address: json['address'] as String?,
      accountCode: json['accountCode'] as String,
      accountName: json['accountName'] as String,
      accountId: json['accountId'] as String?,
    );

Map<String, dynamic> _$CustomerUserToJson(CustomerUser instance) =>
    <String, dynamic>{
      'userCode': instance.userCode,
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'nid': instance.nid,
      'address': instance.address,
      'accountCode': instance.accountCode,
      'accountName': instance.accountName,
      'accountId': instance.accountId,
    };
