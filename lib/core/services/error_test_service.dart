import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';
import 'auth_service.dart';

class ErrorTestService {
  final Dio _dio = AppConfig.dioInstance();

  /// Test invalid credentials
  Future<void> testInvalidCredentials() async {
    print('🧪 Testing invalid credentials...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'invalid@email.com',
          'password': 'wrongpassword',
        },
      );
      print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      print('✅ Invalid credentials error caught:');
      print('   Status: ${e.response?.statusCode}');
      print('   Message: ${e.response?.data?['message']}');
      print('   Error Type: ${e.type}');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }

  /// Test missing fields
  Future<void> testMissingFields() async {
    print('🧪 Testing missing fields...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'test@example.com',
          // Missing password
        },
      );
      print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      print('✅ Missing fields error caught:');
      print('   Status: ${e.response?.statusCode}');
      print('   Message: ${e.response?.data?['message']}');
      print('   Error Type: ${e.type}');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }

  /// Test network timeout
  Future<void> testNetworkTimeout() async {
    print('🧪 Testing network timeout...');
    try {
      // Use a non-existent endpoint to simulate timeout
      final response = await _dio.get(
        'https://httpbin.org/delay/10', // 10 second delay
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
      print('❌ Expected timeout but got success: ${response.statusCode}');
    } on DioException catch (e) {
      print('✅ Network timeout error caught:');
      print('   Error Type: ${e.type}');
      print('   Message: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }

  /// Test server error
  Future<void> testServerError() async {
    print('🧪 Testing server error...');
    try {
      final response = await _dio.get('https://httpbin.org/status/500');
      print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      print('✅ Server error caught:');
      print('   Status: ${e.response?.statusCode}');
      print('   Error Type: ${e.type}');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }

  /// Test unauthorized access
  Future<void> testUnauthorizedAccess() async {
    print('🧪 Testing unauthorized access...');
    try {
      // Try to access a protected endpoint without token
      final response = await _dio.get('${AppConfig.authEndpoint}/profile');
      print('❌ Expected unauthorized but got success: ${response.statusCode}');
    } on DioException catch (e) {
      print('✅ Unauthorized error caught:');
      print('   Status: ${e.response?.statusCode}');
      print('   Message: ${e.response?.data?['message']}');
      print('   Error Type: ${e.type}');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }

  /// Test invalid token
  Future<void> testInvalidToken() async {
    print('🧪 Testing invalid token...');
    try {
      // Save an invalid token
      await SecureStorageService.saveAuthToken('invalid_token_123');
      
      // Try to access a protected endpoint with invalid token
      final response = await _dio.get(
        '${AppConfig.authEndpoint}/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer invalid_token_123',
          },
        ),
      );
      print('❌ Expected invalid token error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      print('✅ Invalid token error caught:');
      print('   Status: ${e.response?.statusCode}');
      print('   Message: ${e.response?.data?['message']}');
      print('   Error Type: ${e.type}');
    } catch (e) {
      print('❌ Unexpected error: $e');
    } finally {
      // Clean up
      await SecureStorageService.removeAuthToken();
    }
  }

  /// Test registration with existing email
  Future<void> testDuplicateRegistration() async {
    print('🧪 Testing duplicate registration...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/register',
        data: {
          'name': 'Test User',
          'email': 'hubert@devslab.io', // Already exists
          'phone': '+250788123456',
          'password': 'password123',
          'role': 'owner',
          'permissions': {
            'can_collect': true,
            'can_add_supplier': true,
            'can_view_reports': true,
          },
        },
      );
      print('❌ Expected duplicate error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      print('✅ Duplicate registration error caught:');
      print('   Status: ${e.response?.statusCode}');
      print('   Message: ${e.response?.data?['message']}');
      print('   Error Type: ${e.type}');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }

  /// Test malformed JSON
  Future<void> testMalformedJson() async {
    print('🧪 Testing malformed JSON...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: 'invalid json string',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      print('❌ Expected JSON error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      print('✅ Malformed JSON error caught:');
      print('   Error Type: ${e.type}');
      print('   Message: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }

  /// Test all error scenarios
  Future<void> runAllErrorTests() async {
    print('🚀 Starting comprehensive error handling tests...\n');
    
    await testInvalidCredentials();
    print('');
    
    await testMissingFields();
    print('');
    
    await testNetworkTimeout();
    print('');
    
    await testServerError();
    print('');
    
    await testUnauthorizedAccess();
    print('');
    
    await testInvalidToken();
    print('');
    
    await testDuplicateRegistration();
    print('');
    
    await testMalformedJson();
    print('');
    
    print('✅ All error handling tests completed!');
  }

  /// Test error handling in AuthService
  Future<void> testAuthServiceErrors() async {
    print('🧪 Testing AuthService error handling...');
    
    // Test with invalid credentials
    try {
      final authService = AuthService();
      await authService.login('invalid@email.com', 'wrongpassword');
      print('❌ Expected error but got success');
    } catch (e) {
      print('✅ AuthService error handling works:');
      print('   Error: $e');
    }
  }
}
