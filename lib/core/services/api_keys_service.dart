import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../shared/models/api_key.dart';
import 'authenticated_dio_service.dart';
import 'secure_storage_service.dart';

class ApiKeysService {
  ApiKeysService();

  /// Fetch API keys
  Future<ApiKeysResponse> getApiKeys() async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      print('🔑 Token: ${token.substring(0, 10)}...');
      print('🌐 API URL: ${AppConfig.apiBaseUrl}/api_keys/get');

      final response = await AuthenticatedDioService.instance.post(
        '/api_keys/get',
        data: {
          'token': token, // API expects token in request body
        },
      );

      print('✅ Response: ${response.data}');
      return ApiKeysResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Exception: $e');
      throw Exception('Failed to fetch API keys: $e');
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return Exception(data['message']);
      }
      
      switch (statusCode) {
        case 400:
          return Exception('Bad request');
        case 401:
          return Exception('Unauthorized');
        case 403:
          return Exception('Forbidden - Insufficient permissions');
        case 404:
          return Exception('Not found');
        case 500:
          return Exception('Internal server error');
        default:
          return Exception('Network error: $statusCode');
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('Receive timeout');
    } else {
      return Exception('Network error: ${e.message}');
    }
  }
}
