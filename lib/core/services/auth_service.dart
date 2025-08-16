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

  /// Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        AppConfig.authEndpoint + '/forgot-password',
        data: {
          'email': email,
        },
      );
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Forgot password failed: $e');
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post(
        AppConfig.authEndpoint + '/reset-password',
        data: {
          'token': token,
          'password': newPassword,
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
      // Try to get from cache first
      final cachedUserData = SecureStorageService.getUserData();
      if (cachedUserData != null) {
        return {'data': cachedUserData};
      }
      
      // If no cache, fetch from API
      final response = await _authenticatedDio.get(AppConfig.authEndpoint + '/profile');
      
      // Cache the profile data
      if (response.statusCode == 200 && response.data['data'] != null) {
        await SecureStorageService.saveUserData(response.data['data']);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Get profile failed: $e');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _authenticatedDio.put(
        AppConfig.authEndpoint + '/profile',
        data: profileData,
      );
      
      // Update cached user data
      if (response.statusCode == 200 && response.data['data'] != null) {
        await SecureStorageService.saveUserData(response.data['data']);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
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
