class Order {
  final int id;
  final String orderNo;
  final int customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final int sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String? sellerEmail;
  final double totalAmount;
  final String currency;
  final String status;
  final String shippingAddress;
  final String? shippingNotes;
  final DateTime orderDate;
  final DateTime updatedAt;
  final String? cancellationReason;
  final int totalItems;
  final double calculatedTotal;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNo,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    this.sellerEmail,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.shippingAddress,
    this.shippingNotes,
    required this.orderDate,
    required this.updatedAt,
    this.cancellationReason,
    required this.totalItems,
    required this.calculatedTotal,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      orderNo: json['order_no'] as String,
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      customerEmail: json['customer_email'] as String?,
      sellerId: json['seller_id'] as int,
      sellerName: json['seller_name'] as String,
      sellerPhone: json['seller_phone'] as String?,
      sellerEmail: json['seller_email'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      shippingAddress: json['shipping_address'] as String,
      shippingNotes: json['shipping_notes'] as String?,
      orderDate: DateTime.parse(json['order_date'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cancellationReason: json['cancellation_reason'] as String?,
      totalItems: json['total_items'] as int,
      calculatedTotal: (json['calculated_total'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_no': orderNo,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_phone': sellerPhone,
      'seller_email': sellerEmail,
      'total_amount': totalAmount,
      'currency': currency,
      'status': status,
      'shipping_address': shippingAddress,
      'shipping_notes': shippingNotes,
      'order_date': orderDate.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'total_items': totalItems,
      'calculated_total': calculatedTotal,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Order(id: $id, orderNo: $orderNo, status: $status, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class OrderItem {
  final int id;
  final int productId;
  final String? productName;
  final String? productDescription;
  final String? productImage;
  final double? productPrice;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String currency;

  OrderItem({
    required this.id,
    required this.productId,
    this.productName,
    this.productDescription,
    this.productImage,
    this.productPrice,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.currency,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      productDescription: json['product_description'] as String?,
      productImage: json['product_image'] as String?,
      productPrice: json['product_price'] != null 
          ? (json['product_price'] as num).toDouble() 
          : null,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_description': productDescription,
      'product_image': productImage,
      'product_price': productPrice,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'currency': currency,
    };
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, productId: $productId, quantity: $quantity, totalPrice: $totalPrice)';
  }
}

class CreateOrderRequest {
  final int customerId;
  final int sellerId;
  final double totalAmount;
  final String currency;
  final String shippingAddress;
  final String? shippingNotes;
  final List<CreateOrderItem> items;

  CreateOrderRequest({
    required this.customerId,
    required this.sellerId,
    required this.totalAmount,
    required this.currency,
    required this.shippingAddress,
    this.shippingNotes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'seller_id': sellerId,
      'total_amount': totalAmount,
      'currency': currency,
      'shipping_address': shippingAddress,
      'shipping_notes': shippingNotes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CreateOrderItem {
  final int productId;
  final int quantity;
  final double unitPrice;

  CreateOrderItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}
