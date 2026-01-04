import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/secure_storage_service.dart';

class ReferralService {
  static final Dio _dio = AppConfig.dioInstance();

  /// Get authentication token
  static Future<String?> _getToken() async {
    return SecureStorageService.getAuthToken();
  }

  /// Get user's referral code
  static Future<Map<String, dynamic>> getReferralCode() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/referrals/get-code.php',
        data: {
          'token': token,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }

  /// Use a referral code
  static Future<Map<String, dynamic>> useReferralCode({
    required String referralCode,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/referrals/use-code.php',
        data: {
          'token': token,
          'referral_code': referralCode,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }

  /// Get referral statistics
  static Future<Map<String, dynamic>> getReferralStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/referrals/stats.php',
        data: {
          'token': token,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }

  /// Get points balance
  static Future<Map<String, dynamic>> getPointsBalance() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/points/balance.php',
        data: {
          'token': token,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }

  /// Onboard a new user
  static Future<Map<String, dynamic>> onboardUser({
    required String name,
    required String phoneNumber,
    required String password,
    String? email,
    String? location,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/onboard/create-user.php',
        data: {
          'token': token,
          'name': name,
          'phone_number': phoneNumber,
          'password': password,
          if (email != null) 'email': email,
          if (location != null) 'location': location,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }
}
