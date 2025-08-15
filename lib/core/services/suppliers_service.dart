import 'package:dio/dio.dart';
import '../../shared/models/supplier.dart';
import '../config/app_config.dart';
import 'authenticated_dio_service.dart';
import 'secure_storage_service.dart';

class SuppliersService {
  static final SuppliersService _instance = SuppliersService._internal();
  factory SuppliersService() => _instance;
  SuppliersService._internal();

  final Dio _dio = AuthenticatedDioService.instance;

  /// Get all suppliers for the authenticated user
  Future<List<Supplier>> getSuppliers() async {
    try {
      final token = await SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/suppliers/get',
        data: {
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Check if the API response indicates success
        if (data['code'] == 200 || data['status'] == 'success') {
          final List<dynamic> suppliersData = data['data']?['suppliers'] ?? data['data'] ?? [];
          return suppliersData.map((json) => Supplier.fromApiResponse(json)).toList();
        } else {
          final errorMessage = data['message'] ?? 'Failed to get suppliers';
          // Check if the message contains success info but is still an error
          if (errorMessage.toString().toLowerCase().contains('successfully') && data['status'] != 'success') {
            throw Exception('Supplier created but failed to refresh list. Please try again.');
          }
          throw Exception(errorMessage);
        }
      } else {
        throw Exception('Failed to get suppliers: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get suppliers. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Suppliers service not found.';
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

  /// Create a new supplier
  Future<void> createSupplier({
    required String name,
    required String phone,
    String? email,
    String? nid,
    String? address,
    required double pricePerLiter,
  }) async {
    try {
      final token = await SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/suppliers/create',
        data: {
          'token': token,
          'name': name,
          'phone': phone,
          'email': email,
          'nid': nid,
          'address': address,
          'price_per_liter': pricePerLiter,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Check if the API response indicates success
        if (data['code'] == 200 || data['code'] == 201 || data['status'] == 'success') {
          // API returns success, no need to return supplier data
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to create supplier');
        }
      } else {
        throw Exception('Failed to create supplier: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to create supplier. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid supplier data. Please check your input.';
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

  /// Get supplier details
  Future<Supplier> getSupplierDetails(String supplierId) async {
    try {
      final token = await SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/suppliers/details',
        data: {
          'token': token,
          'supplier_id': supplierId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return Supplier.fromApiResponse(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to get supplier details');
        }
      } else {
        throw Exception('Failed to get supplier details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get supplier details. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Supplier not found.';
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

  /// Update supplier price per liter
  Future<void> updateSupplierPrice({
    required int relationId,
    required double pricePerLiter,
  }) async {
    try {
      final token = await SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/suppliers/update',
        data: {
          'token': token,
          'relation_id': relationId,
          'price_per_liter': pricePerLiter,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to update supplier');
        }
      } else {
        throw Exception('Failed to update supplier: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update supplier. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Supplier relationship not found or not owned by this customer.';
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

  /// Delete supplier relationship
  Future<void> deleteSupplier({
    required int relationshipId,
  }) async {
    try {
      final token = await SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/suppliers/delete',
        data: {
          'token': token,
          'relationship_id': relationshipId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to delete supplier');
        }
      } else {
        throw Exception('Failed to delete supplier: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to delete supplier. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Supplier relationship not found or already inactive.';
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
}
