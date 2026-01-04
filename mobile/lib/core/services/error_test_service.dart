import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';
import 'auth_service.dart';

class ErrorTestService {
  final Dio _dio = AppConfig.dioInstance();

  /// Test invalid credentials
  Future<void> testInvalidCredentials() async {
    // print('🧪 Testing invalid credentials...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'invalid@email.com',
          'password': 'wrongpassword',
        },
      );
      // print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Invalid credentials error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
      // print('   Error Type: ${e.type}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test missing fields
  Future<void> testMissingFields() async {
    // print('🧪 Testing missing fields...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'test@example.com',
          // Missing password
        },
      );
      // print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Missing fields error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
      // print('   Error Type: ${e.type}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test network timeout
  Future<void> testNetworkTimeout() async {
    // print('🧪 Testing network timeout...');
    try {
      // Use a non-existent endpoint to simulate timeout
      final response = await _dio.get(
        'https://httpbin.org/delay/10', // 10 second delay
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
      // print('❌ Expected timeout but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Network timeout error caught:');
      // print('   Error Type: ${e.type}');
      // print('   Message: ${e.message}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test server error
  Future<void> testServerError() async {
    // print('🧪 Testing server error...');
    try {
      final response = await _dio.get('https://httpbin.org/status/500');
      // print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Server error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Error Type: ${e.type}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test unauthorized access
  Future<void> testUnauthorizedAccess() async {
    // print('🧪 Testing unauthorized access...');
    try {
      // Try to access a protected endpoint without token
      final response = await _dio.get('${AppConfig.authEndpoint}/profile');
      // print('❌ Expected unauthorized but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Unauthorized error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
      // print('   Error Type: ${e.type}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test invalid token
  Future<void> testInvalidToken() async {
    // print('🧪 Testing invalid token...');
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
      // print('❌ Expected unauthorized but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Invalid token error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
      // print('   Error Type: ${e.type}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test expired token
  Future<void> testExpiredToken() async {
    // print('🧪 Testing expired token...');
    try {
      // Save an expired token (you would need a real expired token for this)
      await SecureStorageService.saveAuthToken('expired_token_123');
      
      // Try to access a protected endpoint with expired token
      final response = await _dio.get('${AppConfig.authEndpoint}/profile');
      // print('❌ Expected unauthorized but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Expired token error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
      // print('   Error Type: ${e.type}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test malformed request
  Future<void> testMalformedRequest() async {
    // print('🧪 Testing malformed request...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: 'invalid json string', // Malformed data
      );
      // print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Malformed request error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Error Type: ${e.type}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test rate limiting
  Future<void> testRateLimiting() async {
    // print('🧪 Testing rate limiting...');
    try {
      // Make multiple rapid requests to trigger rate limiting
      for (int i = 0; i < 10; i++) {
        await _dio.post(
          '${AppConfig.authEndpoint}/login',
          data: {
            'identifier': 'test@example.com',
            'password': 'password123',
          },
        );
      }
      // print('❌ Expected rate limit but got success');
    } on DioException catch (e) {
      // print('✅ Rate limiting error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
      // print('   Error Type: ${e.type}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test all error scenarios
  Future<void> runAllTests() async {
    // print('🚀 Starting error test suite...');
    
    await testInvalidCredentials();
    await testMissingFields();
    await testNetworkTimeout();
    await testServerError();
    await testUnauthorizedAccess();
    await testInvalidToken();
    await testExpiredToken();
    await testMalformedRequest();
    await testRateLimiting();
    
    // print('✅ Error test suite completed!');
  }
}
