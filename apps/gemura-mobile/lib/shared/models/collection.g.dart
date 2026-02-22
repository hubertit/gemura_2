// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Collection _$CollectionFromJson(Map<String, dynamic> json) => Collection(
      id: json['id'] as String,
      supplierId: json['supplierId'] as String,
      supplierName: json['supplierName'] as String,
      supplierPhone: json['supplierPhone'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      pricePerLiter: (json['pricePerLiter'] as num).toDouble(),
      totalValue: (json['totalValue'] as num).toDouble(),
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      quality: json['quality'] as String?,
      notes: json['notes'] as String?,
      collectionDate: DateTime.parse(json['collectionDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CollectionToJson(Collection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'supplierId': instance.supplierId,
      'supplierName': instance.supplierName,
      'supplierPhone': instance.supplierPhone,
      'quantity': instance.quantity,
      'pricePerLiter': instance.pricePerLiter,
      'totalValue': instance.totalValue,
      'status': instance.status,
      'rejectionReason': instance.rejectionReason,
      'quality': instance.quality,
      'notes': instance.notes,
      'collectionDate': instance.collectionDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
