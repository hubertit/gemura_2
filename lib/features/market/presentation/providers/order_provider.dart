import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/order_api_service.dart';
import '../../domain/models/order.dart';

// Provider for creating orders
final createOrderProvider = FutureProvider.family<Order, CreateOrderRequest>(
  (ref, request) async {
    return await OrderApiService.createOrder(request);
  },
);

// Provider for customer orders
final customerOrdersProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, params) async {
    return await OrderApiService.getCustomerOrders(
      customerId: params['customerId'] as int,
      status: params['status'] as String?,
      limit: params['limit'] as int? ?? 10,
      page: params['page'] as int? ?? 1,
    );
  },
);

// Provider for customer order details
final customerOrderDetailsProvider = FutureProvider.family<Order, Map<String, int>>(
  (ref, params) async {
    return await OrderApiService.getCustomerOrderDetails(
      orderId: params['orderId'] as int,
      customerId: params['customerId'] as int,
    );
  },
);

// Provider for cancelling orders
final cancelOrderProvider = FutureProvider.family<Order, Map<String, dynamic>>(
  (ref, params) async {
    return await OrderApiService.cancelOrder(
      orderId: params['orderId'] as int,
      customerId: params['customerId'] as int,
      cancellationReason: params['cancellationReason'] as String,
    );
  },
);

// Provider for seller orders
final sellerOrdersProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
  (ref, params) async {
    return await OrderApiService.getSellerOrders(
      sellerId: params['sellerId'] as int,
      status: params['status'] as String?,
      limit: params['limit'] as int? ?? 10,
      page: params['page'] as int? ?? 1,
    );
  },
);

// Provider for updating order status
final updateOrderStatusProvider = FutureProvider.family<Order, Map<String, dynamic>>(
  (ref, params) async {
    return await OrderApiService.updateOrderStatus(
      orderId: params['orderId'] as int,
      sellerId: params['sellerId'] as int,
      status: params['status'] as String,
      changedBy: params['changedBy'] as String?,
      notes: params['notes'] as String?,
    );
  },
);

// Notifier provider for managing order state
class OrderNotifier extends StateNotifier<AsyncValue<Order?>> {
  OrderNotifier() : super(const AsyncValue.data(null));

  Future<void> createOrder(CreateOrderRequest request) async {
    state = const AsyncValue.loading();
    try {
      final order = await OrderApiService.createOrder(request);
      state = AsyncValue.data(order);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cancelOrder({
    required int orderId,
    required int customerId,
    required String cancellationReason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final order = await OrderApiService.cancelOrder(
        orderId: orderId,
        customerId: customerId,
        cancellationReason: cancellationReason,
      );
      state = AsyncValue.data(order);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final orderNotifierProvider = StateNotifierProvider<OrderNotifier, AsyncValue<Order?>>(
  (ref) => OrderNotifier(),
);
