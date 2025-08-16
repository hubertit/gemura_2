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

  Future<List<Sale>> getSales() async {
    try {
      final token = SecureStorageService.getAuthToken();
      
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/sales/sales',
        data: {
          'token': token,
        },
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
}
