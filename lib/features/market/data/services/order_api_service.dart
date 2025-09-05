import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../domain/models/order.dart';

class OrderApiService {
  static const String _baseUrl = '${AppConfig.apiBaseUrl}/market/orders';

  // Create a new order
  static Future<Order> createOrder(CreateOrderRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers/place-order.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Order.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to create order');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get customer orders
  static Future<Map<String, dynamic>> getCustomerOrders({
    required int customerId,
    String? status,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final queryParams = {
        'customer_id': customerId.toString(),
        'limit': limit.toString(),
        'page': page.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl/customers/my-orders.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<Order> orders = (data['data']['orders'] as List)
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();

          return {
            'orders': orders,
            'pagination': data['data']['pagination'],
          };
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch orders');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch customer orders: $e');
    }
  }

  // Get customer order details
  static Future<Order> getCustomerOrderDetails({
    required int orderId,
    required int customerId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/customers/my-order-details.php')
          .replace(queryParameters: {
        'id': orderId.toString(),
        'customer_id': customerId.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Order.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch order details');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch order details: $e');
    }
  }

  // Cancel customer order
  static Future<Order> cancelOrder({
    required int orderId,
    required int customerId,
    required String cancellationReason,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/customers/cancel-order.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
          'customer_id': customerId,
          'cancellation_reason': cancellationReason,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Order.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to cancel order');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Get seller orders
  static Future<Map<String, dynamic>> getSellerOrders({
    required int sellerId,
    String? status,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final queryParams = {
        'seller_id': sellerId.toString(),
        'limit': limit.toString(),
        'page': page.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl/sellers/seller-orders.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<Order> orders = (data['data']['orders'] as List)
              .map((orderJson) => Order.fromJson(orderJson))
              .toList();

          return {
            'orders': orders,
            'pagination': data['data']['pagination'],
          };
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch seller orders');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch seller orders: $e');
    }
  }

  // Update order status (seller)
  static Future<Order> updateOrderStatus({
    required int orderId,
    required int sellerId,
    required String status,
    String? changedBy,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/sellers/update-status.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
          'seller_id': sellerId,
          'status': status,
          'changed_by': changedBy,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Order.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to update order status');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
