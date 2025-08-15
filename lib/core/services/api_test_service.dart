import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../shared/models/registration_request.dart';

class ApiTestService {
  final Dio _dio;

  ApiTestService() : _dio = AppConfig.dioInstance();

  /// Test registration API
  Future<Map<String, dynamic>> testRegistration() async {
    try {
      print('🔗 Testing API connection to: ${AppConfig.apiBaseUrl}');
      print('📡 Endpoint: ${AppConfig.authEndpoint}/register');
      
      // Create test registration data
      final testRequest = RegistrationRequest(
        name: 'Test User',
        email: 'test@example.com',
        phone: '+250788123456',
        password: 'password123',
        nid: null, // Optional
        role: 'owner',
        permissions: {
          'can_collect': true,
          'can_add_supplier': true,
          'can_view_reports': true,
        },
      );

      print('📤 Sending request:');
      print('   Name: ${testRequest.name}');
      print('   Email: ${testRequest.email}');
      print('   Phone: ${testRequest.phone}');
      print('   Role: ${testRequest.role}');
      print('   NID: ${testRequest.nid ?? "null"}');
      print('   Permissions: ${testRequest.permissions}');

      final response = await _dio.post(
        '${AppConfig.authEndpoint}/register',
        data: testRequest.toJson(),
      );

      print('✅ Response Status: ${response.statusCode}');
      print('📥 Response Data: ${response.data}');
      print('📋 Response Headers: ${response.headers}');

      return response.data;
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ Error Message: ${e.message}');
      print('❌ Response Status: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');
      print('❌ Request Data: ${e.requestOptions.data}');
      print('❌ Request URL: ${e.requestOptions.uri}');
      print('❌ Request Headers: ${e.requestOptions.headers}');
      
      rethrow;
    } catch (e) {
      print('❌ General Error: $e');
      rethrow;
    }
  }

  /// Test login API
  Future<Map<String, dynamic>> testLogin() async {
    try {
      print('🔗 Testing login API...');
      
      final response = await _dio.post(
        '${AppConfig.authEndpoint}/login',
        data: {
          'email': 'test@example.com',
          'password': 'password123',
        },
      );

      print('✅ Login Response Status: ${response.statusCode}');
      print('📥 Login Response Data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      print('❌ Login DioException: ${e.type}');
      print('❌ Login Error Message: ${e.message}');
      print('❌ Login Response Status: ${e.response?.statusCode}');
      print('❌ Login Response Data: ${e.response?.data}');
      
      rethrow;
    } catch (e) {
      print('❌ Login General Error: $e');
      rethrow;
    }
  }

  /// Test API connectivity
  Future<bool> testConnectivity() async {
    try {
      print('🔗 Testing API connectivity...');
      
      // Try to get configs endpoint to test connectivity
      final response = await _dio.get('${AppConfig.configsEndpoint}');
      
      print('✅ Connectivity test successful');
      print('📥 Configs Response: ${response.data}');
      
      return true;
    } on DioException catch (e) {
      print('❌ Connectivity test failed: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Connectivity test failed: $e');
      return false;
    }
  }
}
