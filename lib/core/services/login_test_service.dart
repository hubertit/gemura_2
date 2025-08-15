import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';
import 'authenticated_dio_service.dart';

class LoginTestService {
  final Dio _dio = AppConfig.dioInstance();

  /// Test login with real credentials
  Future<Map<String, dynamic>> testLogin() async {
    try {
      print('🔗 Testing login integration...');
      
      final loginData = {
        'identifier': 'hubert@devslab.io',
        'password': 'password',
      };

      print('📤 Sending login request:');
      print('   Identifier: ${loginData['identifier']}');
      print('   Password: ${loginData['password']}');

      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: loginData,
      );

      print('✅ Login Response Status: ${response.statusCode}');
      print('📥 Login Response Data: ${response.data}');

      // Test caching functionality
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          print('💾 Testing caching...');
          
          // Save auth token
          if (data['user']?['token'] != null) {
            await SecureStorageService.saveAuthToken(data['user']['token']);
            print('✅ Auth token cached');
          }
          
          // Save user data
          if (data['user'] != null) {
            await SecureStorageService.saveUserData(data['user']);
            print('✅ User data cached');
          }
          
          // Save login state
          await SecureStorageService.saveLoginState(true);
          print('✅ Login state cached');
          
          // Test authenticated Dio
          print('🔐 Testing authenticated requests...');
          final authDio = AuthenticatedDioService.instance;
          print('✅ Authenticated Dio instance created');
          
          // Test profile endpoint with token
          try {
            final profileResponse = await authDio.get('${AppConfig.authEndpoint}/profile');
            print('✅ Profile request successful: ${profileResponse.statusCode}');
          } catch (e) {
            print('⚠️ Profile request failed (expected if endpoint doesn\'t exist): $e');
          }
        }
      }

      return response.data;
    } on DioException catch (e) {
      print('❌ Login DioException: ${e.type}');
      print('❌ Error Message: ${e.message}');
      print('❌ Response Status: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');
      
      rethrow;
    } catch (e) {
      print('❌ Login General Error: $e');
      rethrow;
    }
  }

  /// Test cached data retrieval
  Future<void> testCachedData() async {
    print('📋 Testing cached data retrieval...');
    
    final token = SecureStorageService.getAuthToken();
    final userData = SecureStorageService.getUserData();
    final isLoggedIn = SecureStorageService.getLoginState();
    
    print('🔑 Cached Token: ${token != null ? 'Present' : 'Not found'}');
    print('👤 Cached User Data: ${userData != null ? 'Present' : 'Not found'}');
    print('🔐 Login State: $isLoggedIn');
    
    if (userData != null) {
      print('📊 User Details:');
      print('   Name: ${userData['name']}');
      print('   Email: ${userData['email']}');
      print('   Phone: ${userData['phone']}');
      print('   Status: ${userData['status']}');
    }
  }

  /// Clear all test data
  Future<void> clearTestData() async {
    print('🧹 Clearing test data...');
    await SecureStorageService.clearAllCachedData();
    print('✅ Test data cleared');
  }
}
