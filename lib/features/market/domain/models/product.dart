class Product {
  final int id;
  final String code;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String? imageUrl;
  final bool isAvailable;
  final int stockQuantity;
  final int minOrderQuantity;
  final int maxOrderQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sellerId;
  final Seller seller;
  final List<String> categories;
  final List<int> categoryIds;

  Product({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    this.imageUrl,
    required this.isAvailable,
    required this.stockQuantity,
    required this.minOrderQuantity,
    required this.maxOrderQuantity,
    required this.createdAt,
    required this.updatedAt,
    required this.sellerId,
    required this.seller,
    required this.categories,
    required this.categoryIds,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final seller = Seller.fromJson(json['seller'] as Map<String, dynamic>);
    return Product(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      imageUrl: json['image_url'] as String?,
      isAvailable: json['is_available'] as bool,
      stockQuantity: json['stock_quantity'] as int,
      minOrderQuantity: json['min_order_quantity'] as int,
      maxOrderQuantity: json['max_order_quantity'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sellerId: json['seller_id'] as int? ?? seller.id, // Use seller.id if seller_id is missing
      seller: seller,
      categories: (json['categories'] as List<dynamic>).cast<String>(),
      categoryIds: (json['category_ids'] as List<dynamic>).cast<int>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'stock_quantity': stockQuantity,
      'min_order_quantity': minOrderQuantity,
      'max_order_quantity': maxOrderQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'seller_id': sellerId,
      'seller': seller.toJson(),
      'categories': categories,
      'category_ids': categoryIds,
    };
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, seller: ${seller.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Seller {
  final int id;
  final String code;
  final String name;
  final String? phone;
  final String? email;

  Seller({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'email': email,
    };
  }

  @override
  String toString() {
    return 'Seller(id: $id, name: $name)';
  }
}
