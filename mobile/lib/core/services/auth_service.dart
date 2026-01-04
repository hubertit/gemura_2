import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../shared/models/registration_request.dart';
import 'secure_storage_service.dart';
import 'authenticated_dio_service.dart';

class AuthService {
  final Dio _dio;
  final Dio _authenticatedDio;

  AuthService() 
    : _dio = AppConfig.dioInstance(),
      _authenticatedDio = AuthenticatedDioService.instance;

  /// Register a new user
  Future<Map<String, dynamic>> register(RegistrationRequest request) async {
    try {
      final response = await _dio.post(
        AppConfig.authEndpoint + '/register',
        data: request.toJson(),
      );
      
      // Cache user data and token if registration is successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data != null) {
          // Save auth token
          if (data['user']?['token'] != null) {
            await SecureStorageService.saveAuthToken(data['user']['token']);
          }
          
          // Save user data
          if (data['user'] != null) {
            await SecureStorageService.saveUserData(data['user']);
          }
          
          // Save login state
          await SecureStorageService.saveLoginState(true);
          
          // Refresh authenticated Dio instance with new token
          AuthenticatedDioService.refreshInstance();
        }
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
    try {
      // Use identifier field as per API specification
      final loginData = {
        'identifier': emailOrPhone,
        'password': password,
      };
      
      final response = await _dio.post(
        AppConfig.authEndpoint + '/login',
        data: loginData,
      );
      
      // Cache user data and token if login is successful
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          // Save auth token
          if (data['user']?['token'] != null) {
            await SecureStorageService.saveAuthToken(data['user']['token']);
          }
          
          // Save user data with account information
          if (data['user'] != null && data['account'] != null) {
            final userData = Map<String, dynamic>.from(data['user']);
            userData['role'] = data['account']['type'];
            userData['accountCode'] = data['account']['code'];
            userData['accountName'] = data['account']['name']; // Save account name
            userData['accountType'] = data['account']['type'] ?? 'mcc'; // Save account type
            await SecureStorageService.saveUserData(userData);
          }
          
          // Save login state
          await SecureStorageService.saveLoginState(true);
          
          // Refresh authenticated Dio instance with new token
          AuthenticatedDioService.refreshInstance();
        }
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Request password reset
  Future<Map<String, dynamic>> requestPasswordReset({String? phone, String? email}) async {
    try {
      final data = <String, dynamic>{};
      if (phone != null && phone.isNotEmpty) data['phone'] = phone;
      if (email != null && email.isNotEmpty) data['email'] = email;
      
      final response = await _dio.post(
        AppConfig.authEndpoint + '/request_reset.php',
        data: data,
      );
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Request password reset failed: $e');
    }
  }

  /// Reset password with code
  Future<Map<String, dynamic>> resetPasswordWithCode(int userId, String resetCode, String newPassword) async {
    try {
      final response = await _dio.post(
        AppConfig.authEndpoint + '/reset_password.php',
        data: {
          'user_id': userId,
          'reset_code': resetCode,
          'new_password': newPassword,
        },
      );
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint with authenticated request
      await _authenticatedDio.post(AppConfig.authEndpoint + '/logout');
    } on DioException catch (e) {
      // Even if logout fails, clear local data
      await _clearLocalData();
      throw _handleDioError(e);
    } catch (e) {
      // Clear local data on any error
      await _clearLocalData();
      throw Exception('Logout failed: $e');
    }
  }
  
  /// Clear local data (token, user data, cache)
  Future<void> _clearLocalData() async {
    await SecureStorageService.removeAuthToken();
    await SecureStorageService.removeUserData();
    await SecureStorageService.removeLoginState();
    await SecureStorageService.clearAllCachedData();
    AuthenticatedDioService.clearInstance();
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      // Always fetch from API to ensure we have the latest data
      final response = await _authenticatedDio.get(
        AppConfig.apiBaseUrl + '/profile/get.php',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      // Cache the profile data
      if (response.statusCode == 200 && response.data['data'] != null) {
        final userData = response.data['data']['user'];
        if (userData != null) {
          await SecureStorageService.saveUserData(userData);
        }
      }
      
      return response.data;
    } on DioException catch (e) {
      // If API call fails, try to get from cache as fallback
      final cachedUserData = SecureStorageService.getUserData();
      if (cachedUserData != null) {
        return {'data': cachedUserData};
      }
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Get profile failed: $e');
    }
  }

  /// Force refresh user profile from API (ignores cache)
  Future<Map<String, dynamic>> refreshProfile() async {
    try {
      // Get token for request body
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        print('🔧 AuthService: No authentication token found for profile refresh');
        throw Exception('No authentication token found');
      }
      print('🔧 AuthService: Token found for profile refresh: ${token.substring(0, 10)}...');

      // Always fetch from API, ignore cache
      final response = await _authenticatedDio.post(
        AppConfig.apiBaseUrl + '/profile/get.php',
        data: {'token': token},
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      // Cache the fresh profile data
      if (response.statusCode == 200 && response.data['data'] != null) {
        final userData = response.data['data']['user'];
        if (userData != null) {
          await SecureStorageService.saveUserData(userData);
        }
      }
      
      return response.data;
    } on DioException catch (e) {
      print('Refresh profile DioException: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('Refresh profile error: $e');
      throw Exception('Refresh profile failed: $e');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      print('🔧 AuthService: Starting profile update...');
      print('🔧 AuthService: Profile data: $profileData');
      
      // v2 PHP APIs expect token in body
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        print('🔧 AuthService: No authentication token found');
        throw Exception('No authentication token found');
      }
      print('🔧 AuthService: Token found: ${token.substring(0, 10)}...');

      final body = {
        'token': token,
        ...profileData,
      };
      print('🔧 AuthService: Request body: $body');

      print('🔧 AuthService: Making API call to: ${AppConfig.apiBaseUrl}/profile/update.php');
      final response = await _authenticatedDio.post(
        AppConfig.apiBaseUrl + '/profile/update.php',
        data: body,
      );
      
      print('🔧 AuthService: Response status: ${response.statusCode}');
      print('🔧 AuthService: Response data: ${response.data}');
      
      // Update cached user data (response shape: { data: { user: {...}, account: {...} } })
      if (response.statusCode == 200 && response.data['data'] != null) {
        final updatedUser = response.data['data']['user'];
        if (updatedUser != null) {
          print('🔧 AuthService: Updating cached user data');
          await SecureStorageService.saveUserData(updatedUser);
        }
      }
      
      print('🔧 AuthService: Profile update completed successfully');
      return response.data;
    } on DioException catch (e) {
      print('🔧 AuthService: DioException occurred: ${e.message}');
      print('🔧 AuthService: DioException type: ${e.type}');
      print('🔧 AuthService: DioException response: ${e.response?.data}');
      print('🔧 AuthService: DioException status: ${e.response?.statusCode}');
      throw _handleDioError(e);
    } catch (e) {
      print('🔧 AuthService: General exception: $e');
      throw Exception('Update profile failed: $e');
    }
  }

  /// Handle Dio errors
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(AppConfig.networkErrorMessage);
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server error';
        
        switch (statusCode) {
          case 400:
            return Exception('Bad request: $message');
          case 401:
            return Exception(AppConfig.authErrorMessage);
          case 403:
            return Exception('Access denied: $message');
          case 404:
            return Exception('Resource not found: $message');
          case 422:
            return Exception('Validation error: $message');
          case 500:
            return Exception(AppConfig.serverErrorMessage);
          default:
            return Exception('Error $statusCode: $message');
        }
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.connectionError:
        return Exception(AppConfig.networkErrorMessage);
      default:
        return Exception('Network error: ${e.message}');
    }
  }
}
