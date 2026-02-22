import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Service to check backend API health status
class HealthCheckService {
  static const String _healthEndpoint = '/health';
  static const Duration _timeout = Duration(seconds: 5);

  /// Check if the backend API is available
  /// Returns true if API is healthy, false otherwise
  static Future<bool> checkHealth() async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: _timeout,
          receiveTimeout: _timeout,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final response = await dio.get(
        _healthEndpoint,
        options: Options(
          validateStatus: (status) {
            // Only consider 200-299 as success, throw error for others
            return status != null && status >= 200 && status < 300;
          },
        ),
      );
      
      // If we get here, status is 200-299
      // Verify the response has the expected structure
      final data = response.data;
      if (data is Map && data['status'] == 'ok') {
        return true;
      }
      
      // If status code is 200-299 but structure is different, still consider healthy
      return true;
    } on DioException {
      // Handle Dio-specific errors
      // Connection errors, timeouts, 404s, etc. all mean API is not available
      return false;
    } catch (_) {
      // Any other error means API is not available
      return false;
    }
  }

  /// Check health with retry logic
  /// [maxRetries] - Maximum number of retry attempts (default: 2)
  /// [retryDelay] - Delay between retries (default: 1 second)
  static Future<bool> checkHealthWithRetry({
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i <= maxRetries; i++) {
      final isHealthy = await checkHealth();
      if (isHealthy) {
        return true;
      }
      
      // Wait before retry (except on last attempt)
      if (i < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }
    
    return false;
  }
}
