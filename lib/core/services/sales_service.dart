import 'package:dio/dio.dart';
import 'package:gemura/core/config/app_config.dart';
import 'package:gemura/core/services/authenticated_dio_service.dart';
import 'package:gemura/core/services/secure_storage_service.dart';
import 'package:gemura/shared/models/sale.dart';

class SalesService {
  static final SalesService _instance = SalesService._internal();
  factory SalesService() => _instance;
  SalesService._internal();

  final Dio _dio = AuthenticatedDioService.instance;

  Future<List<Sale>> getSales({Map<String, dynamic>? filters}) async {
    try {
      final token = SecureStorageService.getAuthToken();
      
      final Map<String, dynamic> requestData = {
        'token': token,
      };
      
      if (filters != null && filters.isNotEmpty) {
        requestData['filters'] = filters;
      }
      
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/sales/sales',
        data: requestData,
      );

      final data = response.data;
      
      if (data['code'] == 200) {
        final List<dynamic> salesData = data['data'] ?? [];
        print('🔍 DEBUG: Found ${salesData.length} sales in API response');
        
        final List<Sale> sales = [];
        for (int i = 0; i < salesData.length; i++) {
          try {
            final sale = Sale.fromJson(salesData[i]);
            sales.add(sale);
            print('✅ DEBUG: Successfully parsed sale ${i + 1}: ${sale.id}');
          } catch (e) {
            print('❌ DEBUG: Failed to parse sale ${i + 1}: $e');
            print('❌ DEBUG: Sale data: ${salesData[i]}');
          }
        }
        
        return sales;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch sales');
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Failed to fetch sales');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> recordSale({
    required String customerAccountCode,
    required double quantity,
    required String status,
    required DateTime saleAt,
    String? notes,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/sales/sell',
        data: {
          'token': token,
          'customer_account_code': customerAccountCode,
          'quantity': quantity,
          'status': status.toLowerCase(),
          'sale_at': saleAt.toIso8601String().replaceAll('T', ' ').substring(0, 19),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final data = response.data;
      
      if (data['code'] == 200 || data['code'] == 201) {
        return; // Success
      } else {
        throw Exception(data['message'] ?? 'Failed to record sale');
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Failed to record sale');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> updateSale({
    required String saleId,
    required String customerAccountCode,
    required double quantity,
    required String status,
    required DateTime saleAt,
    String? notes,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/sales/update',
        data: {
          'token': token,
          'sale_id': saleId,
          'customer_account_code': customerAccountCode,
          'quantity': quantity,
          'status': status.toLowerCase(),
          'sale_at': saleAt.toIso8601String().replaceAll('T', ' ').substring(0, 19),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final data = response.data;
      print('🔍 DEBUG: Update sale response: $data');
      
      if (data['code'] == 200 || data['code'] == 201) {
        print('✅ DEBUG: Sale updated successfully');
        return; // Success
      } else {
        print('❌ DEBUG: Update sale failed with code: ${data['code']}');
        throw Exception(data['message'] ?? 'Failed to update sale');
      }
    } on DioException catch (e) {
      print('❌ DEBUG: DioException in updateSale: ${e.message}');
      print('❌ DEBUG: Response status: ${e.response?.statusCode}');
      print('❌ DEBUG: Response data: ${e.response?.data}');
      
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Failed to update sale');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ DEBUG: Unexpected error in updateSale: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> cancelSale({
    required String saleId,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/sales/cancel',
        data: {
          'token': token,
          'sale_id': saleId,
        },
      );

      final data = response.data;
      print('🔍 DEBUG: Cancel sale response: $data');
      
      if (data['code'] == 200 || data['code'] == 201) {
        print('✅ DEBUG: Sale cancelled successfully');
        return; // Success
      } else {
        print('❌ DEBUG: Cancel sale failed with code: ${data['code']}');
        throw Exception(data['message'] ?? 'Failed to cancel sale');
      }
    } on DioException catch (e) {
      print('❌ DEBUG: DioException in cancelSale: ${e.message}');
      print('❌ DEBUG: Response status: ${e.response?.statusCode}');
      print('❌ DEBUG: Response data: ${e.response?.data}');
      
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Failed to cancel sale');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ DEBUG: Unexpected error in cancelSale: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}
