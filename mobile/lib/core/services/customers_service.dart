import 'package:dio/dio.dart';
import '../../shared/models/customer.dart';
import 'authenticated_dio_service.dart';

class CustomersService {
  static final CustomersService _instance = CustomersService._internal();
  factory CustomersService() => _instance;
  CustomersService._internal();

  final Dio _dio = AuthenticatedDioService.instance;

  /// Get all customers for the authenticated user
  /// Note: NestJS doesn't have a "get all customers" endpoint
  /// Using suppliers endpoint pattern - customers are relationships, not a list endpoint
  /// This returns an empty list - individual customers must be fetched by code
  Future<List<Customer>> getCustomers() async {
    try {
      // Since NestJS doesn't have GET /customers, we return empty list
      // Individual customers can be fetched using getCustomerDetails(customerCode)
      // TODO: Backend should implement GET /customers endpoint OR
      // Use a different approach like getting from sales relationships
      print('⚠️ Warning: GET /customers endpoint not available in NestJS backend');
      print('⚠️ Use getCustomerDetails(customerCode) to fetch individual customers');
      return [];
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
      final response = await _dio.post(
        '/customers',
        data: {
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
  Future<Customer> getCustomerDetails(String customerCode) async {
    try {
      // NestJS uses GET /customers/:code
      final response = await _dio.get(
        '/customers/$customerCode',
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
  /// Note: customerAccountCode should be the customer account code (string), not relationship ID
  Future<void> updateCustomerPrice({
    required String customerAccountCode, // Changed from int relationId to String accountCode
    required double pricePerLiter,
  }) async {
    try {
      final response = await _dio.put(
        '/customers/update',
        data: {
          'customer_account_code': customerAccountCode,
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
  /// Note: customerAccountCode should be the customer account code (string), not relationship ID
  Future<void> deleteCustomer({
    required String customerAccountCode, // Changed from int relationshipId to String accountCode
  }) async {
    try {
      // NestJS uses DELETE /customers/:code
      final response = await _dio.delete(
        '/customers/$customerAccountCode',
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
