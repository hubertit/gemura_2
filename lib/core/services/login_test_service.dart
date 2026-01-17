import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';
import 'authenticated_dio_service.dart';

class LoginTestService {
  final Dio _dio = AppConfig.dioInstance();

  /// Test successful login
  Future<void> testSuccessfulLogin() async {
    // print('🧪 Testing successful login...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'hubert@devslab.io',
          'password': 'password123',
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        // print('✅ Login successful!');
        // print('   User: ${data['user']['name']}');
        // print('   Email: ${data['user']['email']}');
        // print('   Token: ${data['user']['token']?.substring(0, 20)}...');
        // print('   Account: ${data['account']['code']}');
        // print('   Role: ${data['account']['type']}');
      } else {
        // print('❌ Login failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // print('❌ Login error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test login with wrong password
  Future<void> testWrongPassword() async {
    // print('🧪 Testing wrong password...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'hubert@devslab.io',
          'password': 'wrongpassword',
        },
      );
      // print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Wrong password error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test login with non-existent email
  Future<void> testNonExistentEmail() async {
    // print('🧪 Testing non-existent email...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'nonexistent@example.com',
          'password': 'password123',
        },
      );
      // print('❌ Expected error but got success: ${response.statusCode}');
    } on DioException catch (e) {
      // print('✅ Non-existent email error caught:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test login with phone number
  Future<void> testLoginWithPhone() async {
    // print('🧪 Testing login with phone number...');
    try {
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': '250788606765',
          'password': 'password123',
        },
      );
      
      if (response.statusCode == 200) {
        // print('✅ Phone login successful!');
        final data = response.data['data'];
        // print('   User: ${data['user']['name']}');
        // print('   Phone: ${data['user']['phone']}');
      } else {
        // print('❌ Phone login failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // print('❌ Phone login error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test token storage and retrieval
  Future<void> testTokenStorage() async {
    // print('🧪 Testing token storage...');
    try {
      // Login to get a token
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'hubert@devslab.io',
          'password': 'password123',
        },
      );
      
      if (response.statusCode == 200) {
        final token = response.data['data']['user']['token'];
        
        // Save token
        await SecureStorageService.saveAuthToken(token);
        // print('✅ Token saved successfully');
        
        // Retrieve token
        final retrievedToken = await SecureStorageService.getAuthToken();
        if (retrievedToken == token) {
          // print('✅ Token retrieved successfully');
        } else {
          // print('❌ Token mismatch');
        }
        
        // Clean up
        await SecureStorageService.removeAuthToken();
        // print('✅ Token cleaned up');
      }
    } on DioException catch (e) {
      // print('❌ Token storage error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test profile retrieval with token
  Future<void> testProfileRetrieval() async {
    // print('🧪 Testing profile retrieval...');
    try {
      // First login to get token
      final loginResponse = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'hubert@devslab.io',
          'password': 'password123',
        },
      );
      
      if (loginResponse.statusCode == 200) {
        final token = loginResponse.data['data']['user']['token'];
        
        // Use token to get profile
        final profileResponse = await _dio.get(
          '${AppConfig.authEndpoint}/profile',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );
        
        if (profileResponse.statusCode == 200) {
          // print('✅ Profile retrieved successfully!');
          final profile = profileResponse.data['data'];
          // print('   Name: ${profile['name']}');
          // print('   Email: ${profile['email']}');
          // print('   Phone: ${profile['phone']}');
        } else {
          // print('❌ Profile retrieval failed: ${profileResponse.statusCode}');
        }
      }
    } on DioException catch (e) {
      // print('❌ Profile retrieval error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Test logout
  Future<void> testLogout() async {
    // print('🧪 Testing logout...');
    try {
      // First login to get token
      final loginResponse = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'identifier': 'hubert@devslab.io',
          'password': 'password123',
        },
      );
      
      if (loginResponse.statusCode == 200) {
        final token = loginResponse.data['data']['user']['token'];
        
        // Test logout
        final logoutResponse = await _dio.post(
          '${AppConfig.authEndpoint}/logout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );
        
        if (logoutResponse.statusCode == 200) {
          // print('✅ Logout successful!');
        } else {
          // print('❌ Logout failed: ${logoutResponse.statusCode}');
        }
      }
    } on DioException catch (e) {
      // print('❌ Logout error:');
      // print('   Status: ${e.response?.statusCode}');
      // print('   Message: ${e.response?.data?['message']}');
    } catch (e) {
      // print('❌ Unexpected error: $e');
    }
  }

  /// Run all login tests
  Future<void> runAllTests() async {
    // print('🚀 Starting login test suite...');
    
    await testSuccessfulLogin();
    await testWrongPassword();
    await testNonExistentEmail();
    await testLoginWithPhone();
    await testTokenStorage();
    await testProfileRetrieval();
    await testLogout();
    
    // print('✅ Login test suite completed!');
  }
}
