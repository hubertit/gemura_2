import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';

class KYCService {
  static final Dio _dio = Dio();

  /// Upload KYC photo to Cloudinary
  static Future<Map<String, dynamic>> uploadPhoto({
    required File photoFile,
    required String photoType,
    required String token,
  }) async {
    try {
      // Create form data
      FormData formData = FormData.fromMap({
        'token': token,
        'photo_type': photoType,
        'photo': MultipartFile.fromFile(
          photoFile.path,
          filename: '${photoType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      // Make API call
      Response response = await _dio.post(
        '${AppConfig.apiBaseUrl}/kyc/upload_photo.php',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('KYC Photo Upload Error: $e');
      }
      rethrow;
    }
  }

  /// Get KYC status
  static Future<Map<String, dynamic>> getKycStatus(String token) async {
    try {
      Response response = await _dio.post(
        '${AppConfig.apiBaseUrl}/profile/update.php',
        data: {
          'token': token,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to get KYC status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('KYC Status Error: $e');
      }
      rethrow;
    }
  }
}
