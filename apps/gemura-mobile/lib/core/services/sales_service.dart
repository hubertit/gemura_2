import 'package:dio/dio.dart';
import 'package:gemura/core/services/authenticated_dio_service.dart';
import 'package:gemura/shared/models/sale.dart';

class SalesService {
  static final SalesService _instance = SalesService._internal();
  factory SalesService() => _instance;
  SalesService._internal();

  final Dio _dio = AuthenticatedDioService.instance;

  Future<List<Sale>> getSales({Map<String, dynamic>? filters}) async {
    try {
      final Map<String, dynamic> requestData = {
        'filters': filters ?? {},
      };
      
      final response = await _dio.post(
        '/sales/sales',
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
    String? customerAccountId,
    String? customerAccountCode,
    required double quantity,
    required String status,
    required DateTime saleAt,
    String? notes,
    String? paymentStatus,
  }) async {
    // Prefer UUID over code for consistency
    // Validate that at least one identifier is provided and not empty
    final hasValidId = customerAccountId != null && customerAccountId.isNotEmpty;
    final hasValidCode = customerAccountCode != null && customerAccountCode.isNotEmpty;
    
    if (!hasValidId && !hasValidCode) {
      throw Exception('Either customerAccountId (UUID) or customerAccountCode must be provided');
    }

    try {
      final response = await _dio.post(
        '/sales', // NestJS uses POST /sales for creating sales
        data: {
          // Prefer UUID, fallback to code
          if (hasValidId) 'customer_account_id': customerAccountId,
          if (!hasValidId && hasValidCode) 'customer_account_code': customerAccountCode,
          'quantity': quantity,
          'status': status.toLowerCase(),
          'sale_at': saleAt.toIso8601String().replaceAll('T', ' ').substring(0, 19),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (paymentStatus != null) 'payment_status': paymentStatus,
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
    String? customerAccountId,
    String? customerAccountCode,
    required double quantity,
    required String status,
    required DateTime saleAt,
    String? notes,
  }) async {
    try {
      final response = await _dio.put(
        '/sales/update',
        data: {
          'sale_id': saleId,
          if (customerAccountId != null) 'customer_account_id': customerAccountId,
          if (customerAccountId == null && customerAccountCode != null) 'customer_account_code': customerAccountCode,
          'quantity': quantity,
          'status': status.toLowerCase(),
          'sale_at': saleAt.toIso8601String().replaceAll('T', ' ').substring(0, 19),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final data = response.data;
      // print('🔍 DEBUG: Update sale response: $data');
      
      if (data['code'] == 200 || data['code'] == 201) {
        // print('✅ DEBUG: Sale updated successfully');
        return; // Success
      } else {
        // print('❌ DEBUG: Update sale failed with code: ${data['code']}');
        throw Exception(data['message'] ?? 'Failed to update sale');
      }
    } on DioException catch (e) {
      // print('❌ DEBUG: DioException in updateSale: ${e.message}');
      // print('❌ DEBUG: Response status: ${e.response?.statusCode}');
      // print('❌ DEBUG: Response data: ${e.response?.data}');
      
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Failed to update sale');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      // print('❌ DEBUG: Unexpected error in updateSale: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> cancelSale({
    required String saleId,
  }) async {
    try {
      final response = await _dio.post(
        '/sales/cancel',
        data: {
          'sale_id': saleId,
        },
      );

      final data = response.data;
      // print('🔍 DEBUG: Cancel sale response: $data');
      
      if (data['code'] == 200 || data['code'] == 201) {
        // print('✅ DEBUG: Sale cancelled successfully');
        return; // Success
      } else {
        // print('❌ DEBUG: Cancel sale failed with code: ${data['code']}');
        throw Exception(data['message'] ?? 'Failed to cancel sale');
      }
    } on DioException catch (e) {
      // print('❌ DEBUG: DioException in cancelSale: ${e.message}');
      // print('❌ DEBUG: Response status: ${e.response?.statusCode}');
      // print('❌ DEBUG: Response data: ${e.response?.data}');
      
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        throw Exception(errorData['message'] ?? 'Failed to cancel sale');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      // print('❌ DEBUG: Unexpected error in cancelSale: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}
