import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';

class AuthenticatedDioService {
  static Dio? _authenticatedDio;
  
  /// Get authenticated Dio instance with token interceptor
  static Dio get instance {
    if (_authenticatedDio == null) {
      _authenticatedDio = _createAuthenticatedDio();
    }
    return _authenticatedDio!;
  }
  
  /// Create authenticated Dio instance
  static Dio _createAuthenticatedDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    
    // Add token interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to all requests
          final token = SecureStorageService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            // Add to Authorization header (Bearer token) - primary method for NestJS endpoints
            options.headers['Authorization'] = 'Bearer $token';
            
            // Also add to query parameters as fallback (TokenGuard checks both header and query)
            options.queryParameters['token'] = token;
            
            // NOTE: Do NOT add token to request body for NestJS endpoints
            // All NestJS endpoints use TokenGuard which extracts token from:
            // 1. Authorization header (Bearer token)
            // 2. Query parameter (token=...)
            // 3. Request body (token field) - but DTOs don't allow extra properties
            // 
            // Since all current endpoints are NestJS and use DTOs with validation,
            // adding token to body causes validation errors like "[property token should not exist]"
            // 
            // Only add to body for legacy PHP endpoints if needed in the future
          } else {
            print('⚠️ AuthenticatedDioService: No token found in storage');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - token expired or invalid
          if (error.response?.statusCode == 401) {
            // Clear stored token and user data
            await SecureStorageService.removeAuthToken();
            await SecureStorageService.removeUserData();
            await SecureStorageService.removeLoginState();
            
            // You might want to navigate to login screen here
            // For now, we'll just pass the error through
          }
          handler.next(error);
        },
      ),
    );
    
    // Add logging interceptor for debugging
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => null, // print('🌐 API: $obj'),
      ),
    );
    
    return dio;
  }
  
  /// Refresh the authenticated Dio instance (useful after token refresh)
  static void refreshInstance() {
    _authenticatedDio = _createAuthenticatedDio();
  }
  
  /// Clear the instance (useful for logout)
  static void clearInstance() {
    _authenticatedDio = null;
  }
}
