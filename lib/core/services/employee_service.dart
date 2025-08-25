import 'package:dio/dio.dart';
import '../../shared/models/user.dart';
import '../../shared/models/employee.dart';
import '../config/app_config.dart';
import 'authenticated_dio_service.dart';
import 'secure_storage_service.dart';

class EmployeeService {
  static final EmployeeService _instance = EmployeeService._internal();
  factory EmployeeService() => _instance;
  EmployeeService._internal();

  final Dio _dio = AuthenticatedDioService.instance;

  /// Register a new employee
  Future<bool> registerEmployee({
    required Map<String, dynamic> userData,
    required Map<String, dynamic> accountAccess,
  }) async {
    try {
      print('🔧 EmployeeService: Starting employee registration...');
      print('🔧 EmployeeService: User data: $userData');
      print('🔧 EmployeeService: Account access: $accountAccess');
      
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        print('🔧 EmployeeService: No authentication token found');
        throw Exception('No authentication token found');
      }
      
      print('🔧 EmployeeService: Token found: ${token.substring(0, 10)}...');
      print('🔧 EmployeeService: Making API call to: /employees/create');

      final response = await _dio.post(
        '/employees/create',
        data: {
          'token': token,
          'user_data': userData,
          'account_access': accountAccess,
        },
      );

      print('🔧 EmployeeService: Response status: ${response.statusCode}');
      print('🔧 EmployeeService: Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        // Check if the API response indicates success
        if (data['code'] == 200 || data['status'] == 'success') {
          print('🔧 EmployeeService: Employee registration successful');
          return true;
        } else {
          final errorMessage = data['message'] ?? 'Failed to register employee';
          print('🔧 EmployeeService: API returned error: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        print('🔧 EmployeeService: HTTP error: ${response.statusCode}');
        throw Exception('Failed to register employee: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('🔧 EmployeeService: DioException occurred: ${e.message}');
      print('🔧 EmployeeService: DioException type: ${e.type}');
      print('🔧 EmployeeService: DioException response: ${e.response?.data}');
      print('🔧 EmployeeService: DioException status: ${e.response?.statusCode}');
      
      String errorMessage = 'Failed to register employee. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Employee service not found.';
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
      
      print('🔧 EmployeeService: Final error message: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get all employees for an account
  Future<List<Employee>> getAccountEmployees([String? accountId]) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final Map<String, dynamic> requestData = {
        'token': token,
      };
      
      // Only include account_id if provided, otherwise API will use default account
      if (accountId != null && accountId.isNotEmpty) {
        requestData['account_id'] = accountId;
      }

      final response = await _dio.post(
        '/employees/get',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Check if the API response indicates success
        if (data['code'] == 200 || data['status'] == 'success') {
          final List<dynamic> employeesData = data['data'] ?? [];
          return employeesData.map((json) => Employee.fromJson(json)).toList();
        } else {
          final errorMessage = data['message'] ?? 'Failed to get employees';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception('Failed to get employees: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get employees. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Employees service not found.';
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

  /// Update employee access permissions
  Future<bool> updateEmployeeAccess({
    required String accessId,
    required String role,
    required List<String> permissions,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/employees/update-access',
        data: {
          'token': token,
          'access_id': accessId,
          'role': role,
          'permissions': permissions,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Check if the API response indicates success
        if (data['code'] == 200 || data['status'] == 'success') {
          return true;
        } else {
          final errorMessage = data['message'] ?? 'Failed to update employee access';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception('Failed to update employee access: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update employee access. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Employee not found.';
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

  /// Revoke employee access
  Future<bool> revokeEmployeeAccess(String accessId) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/employees/delete',
        data: {
          'token': token,
          'access_id': accessId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Check if the API response indicates success
        if (data['code'] == 200 || data['status'] == 'success') {
          return true;
        } else {
          final errorMessage = data['message'] ?? 'Failed to revoke employee access';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception('Failed to revoke employee access: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to revoke employee access. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'Unauthorized. You do not have permission to revoke this access.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Employee not found or not accessible.';
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
