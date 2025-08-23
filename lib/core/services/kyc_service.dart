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
      if (kDebugMode) {
        print('🔧 KYCService: Starting photo upload for type: $photoType');
        print('🔧 KYCService: File path: ${photoFile.path}');
        print('🔧 KYCService: File exists: ${await photoFile.exists()}');
        print('🔧 KYCService: File size: ${await photoFile.length()} bytes');
        
        // Check file size limit (5MB)
        final fileSize = await photoFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('File size too large. Maximum size is 5MB.');
        }
        
        // Check file extension
        final extension = photoFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          throw Exception('Invalid file format. Only JPG, JPEG, and PNG are allowed.');
        }
      }

      // Create form data
      FormData formData = FormData.fromMap({
        'token': token,
        'photo_type': photoType,
        'photo': MultipartFile.fromFile(
          photoFile.path,
          filename: '${photoType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      if (kDebugMode) {
        print('🔧 KYCService: Form data created successfully');
        print('🔧 KYCService: Making API call to: ${AppConfig.apiBaseUrl}/kyc/upload_photo.php');
      }

      // Make API call
      Response response = await _dio.post(
        '${AppConfig.apiBaseUrl}/kyc/upload_photo.php',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) {
            return status! < 500; // Accept all status codes less than 500
          },
        ),
      );

      if (kDebugMode) {
        print('🔧 KYCService: Response status: ${response.statusCode}');
        print('🔧 KYCService: Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔧 KYCService: Photo Upload Error: $e');
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
