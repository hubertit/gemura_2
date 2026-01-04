import 'package:json_annotation/json_annotation.dart';

part 'collection.g.dart';

@JsonSerializable()
class Collection {
  final String id;
  final String supplierId;
  final String supplierName;
  final String supplierPhone;
  final double quantity;
  final double pricePerLiter;
  final double totalValue;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? rejectionReason;
  final String? quality;
  final String? notes;
  final DateTime collectionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Collection({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.supplierPhone,
    required this.quantity,
    required this.pricePerLiter,
    required this.totalValue,
    required this.status,
    this.rejectionReason,
    this.quality,
    this.notes,
    required this.collectionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => _$CollectionFromJson(json);
  Map<String, dynamic> toJson() => _$CollectionToJson(this);

  factory Collection.fromApiResponse(Map<String, dynamic> json) {
    // Handle the new API response structure
    final supplierAccount = json['supplier_account'] as Map<String, dynamic>?;
    final customerAccount = json['customer_account'] as Map<String, dynamic>?;
    
    return Collection(
      id: json['id']?.toString() ?? '',
      supplierId: supplierAccount?['code']?.toString() ?? json['supplier_account_code']?.toString() ?? '',
      supplierName: supplierAccount?['name']?.toString() ?? json['supplier_name']?.toString() ?? '',
      supplierPhone: json['supplier_phone']?.toString() ?? '', // Not provided in new API
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      pricePerLiter: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      totalValue: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'completed',
      rejectionReason: json['rejection_reason']?.toString(),
      quality: json['quality']?.toString(),
      notes: json['notes']?.toString(),
      collectionDate: DateTime.tryParse(json['collection_at']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Collection copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    String? supplierPhone,
    double? quantity,
    double? pricePerLiter,
    double? totalValue,
    String? status,
    String? rejectionReason,
    String? quality,
    String? notes,
    DateTime? collectionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Collection(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      quantity: quantity ?? this.quantity,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalValue: totalValue ?? this.totalValue,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      collectionDate: collectionDate ?? this.collectionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Collection(id: $id, supplierName: $supplierName, quantity: $quantity, totalValue: $totalValue, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Collection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
