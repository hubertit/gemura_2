import 'package:dio/dio.dart';
import '../../shared/models/customer.dart';
import '../config/app_config.dart';
import 'authenticated_dio_service.dart';
import 'secure_storage_service.dart';

class CustomersService {
  static final CustomersService _instance = CustomersService._internal();
  factory CustomersService() => _instance;
  CustomersService._internal();

  final Dio _dio = AuthenticatedDioService.instance;

  /// Get all customers for the authenticated user
  Future<List<Customer>> getCustomers() async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/customers/get',
        data: {
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Check if the API response indicates success
        if (data['code'] == 200 || data['status'] == 'success') {
          final List<dynamic> customersData = data['data'] ?? [];
          return customersData.map((json) => Customer.fromApiResponse(json)).toList();
        } else {
          final errorMessage = data['message'] ?? 'Failed to get customers';
          // Check if the message contains success info but is still an error
          if (errorMessage.toString().toLowerCase().contains('successfully') && data['status'] != 'success') {
            throw Exception('Customer created but failed to refresh list. Please try again.');
          }
          throw Exception(errorMessage);
        }
      } else {
        throw Exception('Failed to get customers: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get customers. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Customers service not found.';
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

  /// Create a new customer
  Future<void> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? nid,
    String? address,
    required double pricePerLiter,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/customers/create',
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
          // API returns success, no need to return customer data
          return;
        } else {
          throw Exception(data['message'] ?? 'Failed to create customer');
        }
      } else {
        throw Exception('Failed to create customer: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to create customer. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid customer data. Please check your input.';
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

  /// Get customer details
  Future<Customer> getCustomerDetails(String customerId) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/customers/details',
        data: {
          'token': token,
          'customer_id': customerId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return Customer.fromApiResponse(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to get customer details');
        }
      } else {
        throw Exception('Failed to get customer details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get customer details. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Customer not found.';
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

  /// Update customer price per liter
  Future<void> updateCustomerPrice({
    required int relationId,
    required double pricePerLiter,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/customers/update',
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
          throw Exception(data['message'] ?? 'Failed to update customer');
        }
      } else {
        throw Exception('Failed to update customer: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update customer. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Customer relationship not found or not owned by this customer.';
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

  /// Delete customer relationship
  Future<void> deleteCustomer({
    required int relationshipId,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/customers/delete',
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
          throw Exception(data['message'] ?? 'Failed to delete customer');
        }
      } else {
        throw Exception('Failed to delete customer: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to delete customer. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Customer relationship not found or already inactive.';
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
