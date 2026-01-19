import 'package:dio/dio.dart';
import '../../shared/models/collection.dart';
import 'authenticated_dio_service.dart';

class CollectionsService {
  static final CollectionsService _instance = CollectionsService._internal();
  factory CollectionsService() => _instance;
  CollectionsService._internal();

  final Dio _dio = AuthenticatedDioService.instance;

  /// Get all collections for the authenticated user
  /// Note: Collections are stored as sales records in the backend
  /// Using sales endpoint with filters to get collections
  Future<List<Collection>> getCollections() async {
    try {
      // Collections are milk sales from supplier perspective
      // Use sales endpoint to get collections
      final response = await _dio.post(
        '/sales/sales',
        data: {
          'filters': {}, // Get all sales (collections)
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['code'] == 200 || data['status'] == 'success') {
          // Handle both old nested structure and new direct array structure
          List<dynamic> collectionsData;
          if (data['data'] is List) {
            // New structure: data is directly an array
            collectionsData = data['data'] ?? [];
          } else if (data['data'] is Map && data['data']['collections'] != null) {
            // Old structure: data contains a collections array
            collectionsData = data['data']['collections'] ?? [];
          } else {
            // Fallback: try to get collections from data
            collectionsData = data['data'] ?? [];
          }
          
          // Convert API data to collections
          final apiCollections = collectionsData.map((json) => Collection.fromApiResponse(json)).toList();
          
          // Add static pending collections for testing
          final staticPendingCollections = _getStaticPendingCollections();
          
          // Combine API collections with static pending collections
          return [...apiCollections, ...staticPendingCollections];
        } else {
          throw Exception(data['message'] ?? 'Failed to get collections');
        }
      } else {
        throw Exception('Failed to get collections: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get collections. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Collections service not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Get static pending collections for testing
  List<Collection> _getStaticPendingCollections() {
    final now = DateTime.now();
    return [
      Collection(
        id: 'pending_001',
        supplierId: 'SUP001',
        supplierName: 'Jean Baptiste',
        supplierPhone: '+250 788 123 456',
        quantity: 25.5,
        pricePerLiter: 400.0,
        totalValue: 10200.0,
        status: 'pending',
        rejectionReason: null,
        quality: null,
        notes: null,
        collectionDate: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  /// Get filtered collections for the authenticated user
  Future<List<Collection>> getFilteredCollections({
    String? supplierAccountCode,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? quantityMin,
    double? quantityMax,
    double? priceMin,
    double? priceMax,
    int? limit,
    int? offset,
  }) async {
    try {
      // Collections are milk sales from supplier perspective
      // Use sales endpoint with filters
      final Map<String, dynamic> filters = {};

      if (supplierAccountCode != null && supplierAccountCode.isNotEmpty) {
        filters['supplier_account_code'] = supplierAccountCode;
      }
      if (status != null && status.isNotEmpty && status != 'All') {
        filters['status'] = status;
      }
      if (dateFrom != null) {
        filters['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        filters['date_to'] = dateTo.toIso8601String().split('T')[0];
      }
      if (quantityMin != null) {
        filters['quantity_min'] = quantityMin;
      }
      if (quantityMax != null) {
        filters['quantity_max'] = quantityMax;
      }
      if (priceMin != null) {
        filters['price_min'] = priceMin;
      }
      if (priceMax != null) {
        filters['price_max'] = priceMax;
      }
      if (limit != null) {
        filters['limit'] = limit;
      }
      if (offset != null) {
        filters['offset'] = offset;
      }

      final response = await _dio.post(
        '/sales/sales',
        data: {
          'filters': filters,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['code'] == 200 || data['status'] == 'success') {
          // Handle both old nested structure and new direct array structure
          List<dynamic> collectionsData;
          if (data['data'] is List) {
            // New structure: data is directly an array
            collectionsData = data['data'] ?? [];
          } else if (data['data'] is Map && data['data']['collections'] != null) {
            // Old structure: data contains a collections array
            collectionsData = data['data']['collections'] ?? [];
          } else {
            // Fallback: try to get collections from data
            collectionsData = data['data'] ?? [];
          }
          return collectionsData.map((json) => Collection.fromApiResponse(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get filtered collections');
        }
      } else {
        throw Exception('Failed to get filtered collections: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get filtered collections. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Collections service not found.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid filter parameters. Please check your input.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Create a new collection record
  Future<void> createCollection({
    required String supplierAccountCode,
    required double quantity,
    required String status,
    String? notes,
    required DateTime collectionAt,
  }) async {
    try {
      final response = await _dio.post(
        '/collections/create',
        data: {
          'supplier_account_code': supplierAccountCode,
          'quantity': quantity,
          'status': status,
          'collection_at': collectionAt.toIso8601String().replaceAll('T', ' ').substring(0, 19),
          'notes': notes,
        },
      );

      // Accept both 200 (OK) and 201 (Created) as success status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['code'] == 200 || data['code'] == 201 || data['status'] == 'success') {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to create collection');
        }
      } else {
        throw Exception('Failed to create collection: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to create collection. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid collection data. Please check your input.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Update a collection record
  Future<void> updateCollection({
    required String collectionId,
    double? quantity,
    double? pricePerLiter,
    String? status,
    DateTime? collectionAt,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'collection_id': collectionId, // Backend uses snake_case
      };

      if (quantity != null) updateData['quantity'] = quantity;
      if (pricePerLiter != null) updateData['unit_price'] = pricePerLiter;
      if (status != null) updateData['status'] = status;
      if (collectionAt != null) {
        updateData['collection_at'] = collectionAt.toIso8601String().replaceAll('T', ' ').substring(0, 19);
      }
      if (notes != null) updateData['notes'] = notes;

      final response = await _dio.put(
        '/collections/update',
        data: updateData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to update collection');
        }
      } else {
        throw Exception('Failed to update collection: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update collection. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Collection not found.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid update data. Please check your input.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Cancel a collection record
  Future<void> cancelCollection({
    required String collectionId,
  }) async {
    try {
      final response = await _dio.post(
        '/collections/cancel',
        data: {
          'collection_id': collectionId, // Backend uses snake_case
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to cancel collection');
        }
      } else {
        throw Exception('Failed to cancel collection: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to cancel collection. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Collection not found.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid request. Please check your input.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Delete a collection record
  Future<void> deleteCollection({
    required String collectionId,
  }) async {
    try {
      // Note: NestJS may not have delete endpoint - check controller
      // For now using cancel or may need DELETE /collections/:id
      final response = await _dio.post(
        '/collections/cancel', // Or DELETE /collections/:id if available
        data: {
          'collectionId': collectionId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to delete collection');
        }
      } else {
        throw Exception('Failed to delete collection: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to delete collection. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Collection not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Approve a pending collection
  Future<void> approveCollection({
    required String collectionId,
    String? notes,
  }) async {
    try {
      // Note: Approve endpoint doesn't exist in NestJS - using update with status='accepted'
      final response = await _dio.put(
        '/collections/update',
        data: {
          'collection_id': collectionId, // Backend uses snake_case
          'status': 'accepted',
          'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to approve collection');
        }
      } else {
        throw Exception('Failed to approve collection: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to approve collection. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Collection not found.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid request. Collection may not be in pending status.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Reject a pending collection
  Future<void> rejectCollection({
    required String collectionId,
    required String rejectionReason,
    String? notes,
  }) async {
    try {
      // Note: Reject endpoint doesn't exist in NestJS - using update with status='rejected'
      final response = await _dio.put(
        '/collections/update',
        data: {
          'collection_id': collectionId, // Backend uses snake_case
          'status': 'rejected',
          'notes': notes != null ? '$rejectionReason. $notes' : rejectionReason,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to reject collection');
        }
      } else {
        throw Exception('Failed to reject collection: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to reject collection. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Collection not found.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid request. Collection may not be in pending status.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Get milk rejection reasons from API
  Future<List<Map<String, dynamic>>> getRejectionReasons() async {
    try {
      final response = await _dio.get('/collections/rejection-reasons');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 || data['status'] == 'success') {
          final List<dynamic> reasonsData = data['data'] ?? [];
          return reasonsData.map((reason) => {
            'id': reason['id'],
            'name': reason['name'],
            'description': reason['description'],
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get rejection reasons');
        }
      } else {
        throw Exception('Failed to get rejection reasons: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get rejection reasons. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Rejection reasons service not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
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

  /// Get collection statistics
  /// Note: Stats endpoint not yet implemented in NestJS backend
  Future<Map<String, dynamic>> getCollectionStats() async {
    // Note: Stats endpoint may not exist in NestJS - check controller
    // May need to implement or use analytics endpoint
    throw Exception('Collection stats endpoint not yet implemented in NestJS backend');
  }
}
