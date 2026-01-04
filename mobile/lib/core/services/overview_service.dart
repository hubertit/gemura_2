import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/overview.dart';
import '../config/app_config.dart';
import 'authenticated_dio_service.dart';
import 'secure_storage_service.dart';

class OverviewService {
  static final OverviewService _instance = OverviewService._internal();
  factory OverviewService() => _instance;
  OverviewService._internal();

  final Dio _dio = AuthenticatedDioService.instance;

  /// Get overview data for the authenticated user
  Future<Overview> getOverview({
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final Map<String, dynamic> requestData = {
        'token': token,
      };

      if (dateFrom != null) {
        requestData['date_from'] = dateFrom;
      }
      if (dateTo != null) {
        requestData['date_to'] = dateTo;
      }

      final response = await _dio.post(
        '/stats/overview',
        data: requestData,
      );

      // Debug logging
      print('🔍 DEBUG OverviewService: Response status: ${response.statusCode}');
      print('🔍 DEBUG OverviewService: Response data: ${response.data}');
      print('🔍 DEBUG OverviewService: Request data: $requestData');

      if (response.statusCode == 200) {
        final data = response.data;
        print('🔍 DEBUG OverviewService: Response code: ${data['code']}, status: ${data['status']}');
        
        if (data['code'] == 200 || data['status'] == 'success') {
          final overviewData = data['data'];
          print('🔍 DEBUG OverviewService: Overview data: $overviewData');
          
          if (overviewData == null) {
            print('❌ DEBUG OverviewService: Overview data is null!');
            throw Exception('Overview data is null in API response');
          }
          
          // Check if data contains zeros or empty values
          if (overviewData is Map) {
            final summary = overviewData['summary'];
            if (summary != null) {
              print('🔍 DEBUG OverviewService: Summary data: $summary');
              final collection = summary['collection'];
              final sales = summary['sales'];
              print('🔍 DEBUG OverviewService: Collection: $collection');
              print('🔍 DEBUG OverviewService: Sales: $sales');
            }
          }
          
          return Overview.fromJson(overviewData);
        } else {
          print('❌ DEBUG OverviewService: API returned error: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to get overview data');
        }
      } else {
        throw Exception('Failed to get overview data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get overview data. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Overview service not found.';
      } else if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid date parameters. Please check your input.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
