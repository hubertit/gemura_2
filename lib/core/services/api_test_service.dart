import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../shared/models/registration_request.dart';

class ApiTestService {
  final Dio _dio = AppConfig.dioInstance();

  /// Test API connectivity
  Future<void> testApiConnectivity() async {
    // print('🧪 Testing API connectivity...');
    try {
      final response = await _dio.get('${AppConfig.authEndpoint}/health');
      // print('✅ API is reachable');
      // print('   Status: ${response.statusCode}');
      // print('   Response: ${response.data}');
    } on DioException catch (e) {
      // print('❌ API connectivity failed:');
      // print('   Error Type: ${e.type}');
      // print('   Message: ${e.message}');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Response: ${e.response?.data}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test authentication endpoints
  Future<void> testAuthEndpoints() async {
    // print('🧪 Testing authentication endpoints...');
    
    // Test login endpoint
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'test@example.com',
          'password': 'password123',
        },
      );
      // print('✅ Login endpoint is accessible');
      // print('   Status: ${response.statusCode}');
    } on DioException catch (e) {
      // print('❌ Login endpoint error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    }

    // Test registration endpoint
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/register',
        data: {
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '+250788123456',
          'password': 'password123',
          'role': 'owner',
        },
      );
      // print('✅ Registration endpoint is accessible');
      // print('   Status: ${response.statusCode}');
    } on DioException catch (e) {
      // print('❌ Registration endpoint error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    }
  }

  /// Test business endpoints
  Future<void> testBusinessEndpoints() async {
    // print('🧪 Testing business endpoints...');
    
    // Test suppliers endpoint
    try {
      final response = await _dio.post(
        '${AppConfig.suppliersEndpoint}/get',
        data: {'token': 'test_token'},
      );
      // print('✅ Suppliers endpoint is accessible');
      // print('   Status: ${response.statusCode}');
    } on DioException catch (e) {
      // print('❌ Suppliers endpoint error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    }

    // Test customers endpoint
    try {
      final response = await _dio.post(
        '${AppConfig.customersEndpoint}/get',
        data: {'token': 'test_token'},
      );
      // print('✅ Customers endpoint is accessible');
      // print('   Status: ${response.statusCode}');
    } on DioException catch (e) {
      // print('❌ Customers endpoint error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    }

    // Test sales endpoint
    try {
      final response = await _dio.post(
        '${AppConfig.salesEndpoint}/sales',
        data: {'token': 'test_token'},
      );
      // print('✅ Sales endpoint is accessible');
      // print('   Status: ${response.statusCode}');
    } on DioException catch (e) {
      // print('❌ Sales endpoint error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    }
  }

  /// Test error handling
  Future<void> testErrorHandling() async {
    // print('🧪 Testing error handling...');
    
    // Test invalid endpoint
    try {
      final response = await _dio.get('${AppConfig.authEndpoint}/invalid');
      // print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Error handling works correctly:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    }

    // Test malformed request
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: 'invalid json',
      );
      // print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Malformed request handled correctly:');
      // print('   Error Type: ${e.type}');
      // print('   Message: ${e.message}');
    }
  }

  /// Run all API tests
  Future<void> runAllTests() async {
    // print('🚀 Starting API test suite...');
    
    await testApiConnectivity();
    await testAuthEndpoints();
    await testBusinessEndpoints();
    await testErrorHandling();
    
    // print('✅ API test suite completed!');
  }
}
