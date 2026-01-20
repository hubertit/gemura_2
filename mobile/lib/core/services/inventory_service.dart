import 'package:dio/dio.dart';
import 'authenticated_dio_service.dart';

class InventoryService {
  final Dio _dio = AuthenticatedDioService.instance;

  /// Get inventory items
  Future<List<Map<String, dynamic>>> getInventory({
    String? status,
    bool? lowStock,
  }) async {
    print('🔌 [API] GET /inventory - status: $status, lowStock: $lowStock');
    
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (lowStock == true) queryParams['low_stock'] = 'true';

      print('🔌 [API] GET /inventory - Query params: $queryParams');
      
      final response = await _dio.get(
        '/inventory',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      print('🔌 [API] GET /inventory - Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔌 [API] GET /inventory - Response data type: ${data.runtimeType}');
        
        // Handle both standard response format and direct array
        if (data is List) {
          print('🔌 [API] GET /inventory - Data is List, returning ${data.length} items');
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          print('🔌 [API] GET /inventory - Data is Map, code: ${data['code']}, status: ${data['status']}');
          if (data['code'] == 200 && data['status'] == 'success') {
            final items = data['data'];
            print('🔌 [API] GET /inventory - Items type: ${items.runtimeType}');
            if (items is List) {
              print('🔌 [API] GET /inventory - Returning ${items.length} items');
              final result = List<Map<String, dynamic>>.from(items);
              print('🔌 [API] GET /inventory - Item IDs: ${result.map((e) => e['id']).toList()}');
              return result;
            } else {
              print('🔌 [API] GET /inventory - Items is not a List, returning empty');
              return [];
            }
          } else {
            print('🔌 [API] GET /inventory - Error response: ${data['message']}');
            throw Exception(data['message'] ?? 'Failed to get inventory');
          }
        } else {
          print('🔌 [API] GET /inventory - Unknown data type, returning empty');
          return [];
        }
      } else {
        print('🔌 [API] GET /inventory - Non-200 status: ${response.statusCode}');
        throw Exception('Failed to get inventory: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get inventory. ';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final response = await _dio.get('/inventory/stats');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'Failed to get inventory stats');
        }
      } else {
        throw Exception(
            'Failed to get inventory stats: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get inventory stats. ';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get inventory item by ID
  Future<Map<String, dynamic>> getInventoryItem(String id) async {
    try {
      final response = await _dio.get('/inventory/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'Failed to get inventory item');
        }
      } else {
        throw Exception('Failed to get inventory item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get inventory item. ';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Inventory item not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create inventory item
  Future<Map<String, dynamic>> createInventoryItem({
    required String name,
    String? description,
    required double price,
    int stockQuantity = 0,
    int? minStockLevel,
    List<String>? categoryIds,
    bool isListedInMarketplace = false,
  }) async {
    try {
      final response = await _dio.post(
        '/inventory',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          'price': price,
          'stock_quantity': stockQuantity,
          if (minStockLevel != null) 'min_stock_level': minStockLevel,
          if (categoryIds != null && categoryIds.isNotEmpty)
            'category_ids': categoryIds,
          'is_listed_in_marketplace': isListedInMarketplace,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'Failed to create inventory item');
        }
      } else {
        throw Exception(
            'Failed to create inventory item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to create inventory item. ';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 400) {
        final backendMsg = e.response?.data?['message'];
        errorMessage =
            backendMsg ?? 'Invalid inventory data. Please check your input.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update inventory item
  Future<Map<String, dynamic>> updateInventoryItem({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    int? minStockLevel,
    List<String>? categoryIds,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (stockQuantity != null) data['stock_quantity'] = stockQuantity;
      if (minStockLevel != null) data['min_stock_level'] = minStockLevel;
      if (categoryIds != null) data['category_ids'] = categoryIds;
      if (status != null) data['status'] = status;

      final response = await _dio.put(
        '/inventory/$id',
        data: data,
      );

      if (response.statusCode == 200) {
        final result = response.data;
        if (result['code'] == 200 && result['status'] == 'success') {
          return Map<String, dynamic>.from(result['data'] ?? {});
        } else {
          throw Exception(
              result['message'] ?? 'Failed to update inventory item');
        }
      } else {
        throw Exception(
            'Failed to update inventory item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update inventory item. ';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 400) {
        final backendMsg = e.response?.data?['message'];
        errorMessage =
            backendMsg ?? 'Invalid inventory data. Please check your input.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Inventory item not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update stock quantity
  Future<Map<String, dynamic>> updateStock({
    required String id,
    required int stockQuantity,
  }) async {
    try {
      final response = await _dio.put(
        '/inventory/$id/stock',
        data: {
          'stock_quantity': stockQuantity,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(data['message'] ?? 'Failed to update stock');
        }
      } else {
        throw Exception('Failed to update stock: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update stock. ';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 400) {
        final backendMsg = e.response?.data?['message'];
        errorMessage = backendMsg ?? 'Invalid stock quantity.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Inventory item not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Toggle marketplace listing
  Future<Map<String, dynamic>> toggleMarketplaceListing({
    required String id,
    required bool isListedInMarketplace,
  }) async {
    try {
      final response = await _dio.post(
        '/inventory/$id/toggle-listing',
        data: {
          'is_listed_in_marketplace': isListedInMarketplace,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return Map<String, dynamic>.from(data['data'] ?? {});
        } else {
          throw Exception(
              data['message'] ?? 'Failed to toggle marketplace listing');
        }
      } else {
        throw Exception(
            'Failed to toggle marketplace listing: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to toggle marketplace listing. ';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 400) {
        final backendMsg = e.response?.data?['message'];
        errorMessage = backendMsg ?? 'Cannot toggle marketplace listing.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Inventory item not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete inventory item
  Future<void> deleteInventoryItem(String id) async {
    print('🔌 [API] DELETE /inventory/$id - Starting request');
    
    try {
      final response = await _dio.delete('/inventory/$id');
      
      print('🔌 [API] DELETE /inventory/$id - Response status: ${response.statusCode}');
      print('🔌 [API] DELETE /inventory/$id - Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          print('🔌 [API] DELETE /inventory/$id - Success confirmed');
          return;
        } else {
          print('🔌 [API] DELETE /inventory/$id - Error in response: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to delete inventory item');
        }
      } else {
        print('🔌 [API] DELETE /inventory/$id - Non-200 status: ${response.statusCode}');
        throw Exception(
            'Failed to delete inventory item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to delete inventory item. ';

      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Inventory item not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
