import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../shared/models/user_accounts.dart';
import 'authenticated_dio_service.dart';
import 'secure_storage_service.dart';

class UserAccountsService {
  UserAccountsService();

  /// Fetch user accounts
  Future<UserAccountsResponse> getUserAccounts() async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      print('🔑 Token: ${token.substring(0, 10)}...');
      print('🌐 API URL: ${AppConfig.apiBaseUrl}/accounts/get');

      final response = await AuthenticatedDioService.instance.post(
        '/accounts/get',
        data: {
          'token': token, // API expects token in request body
        },
      );

      print('✅ Response: ${response.data}');
      return UserAccountsResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Exception: $e');
      throw Exception('Failed to fetch user accounts: $e');
    }
  }

  /// Switch default account
  Future<SwitchAccountResponse> switchAccount(int accountId) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      final response = await AuthenticatedDioService.instance.post(
        '/accounts/switch',
        data: {
          'token': token, // API expects token in request body
          'account_id': accountId,
        },
      );

      return SwitchAccountResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to switch account: $e');
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
          return Exception('Forbidden');
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
