import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'authenticated_dio_service.dart';
import 'secure_storage_service.dart';
import '../../shared/models/receivable.dart';

class ReceivablesService {
  /// Get all accounts receivable
  Future<ReceivablesSummary> getReceivables({
    String? customerAccountId,
    String? dateFrom,
    String? dateTo,
    String? paymentStatus,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      final queryParams = <String, dynamic>{};
      if (customerAccountId != null) queryParams['customer_account_id'] = customerAccountId;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;

      print('📊 Fetching receivables');
      print('🌐 API URL: ${AppConfig.apiBaseUrl}/accounting/receivables');

      final response = await AuthenticatedDioService.instance.get(
        '/accounting/receivables',
        queryParameters: queryParams,
      );

      print('✅ Receivables response: ${response.data}');

      if (response.data['code'] == 200 && response.data['data'] != null) {
        return ReceivablesSummary.fromJson(response.data['data']);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Receivables DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Receivables Exception: $e');
      throw Exception('Failed to fetch receivables: $e');
    }
  }

  /// Record payment for a sale
  Future<Map<String, dynamic>> recordPayment({
    required String saleId,
    required double amount,
    String? paymentDate,
    String? notes,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      print('💰 Recording payment for sale: $saleId');
      print('🌐 API URL: ${AppConfig.apiBaseUrl}/sales/$saleId/payment');

      final response = await AuthenticatedDioService.instance.post(
        '/sales/$saleId/payment',
        data: {
          'amount': amount,
          if (paymentDate != null) 'payment_date': paymentDate,
          if (notes != null) 'notes': notes,
        },
      );

      print('✅ Payment response: ${response.data}');

      if (response.data['code'] == 200 && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Payment DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Payment Exception: $e');
      throw Exception('Failed to record payment: $e');
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      switch (statusCode) {
        case 401:
          return Exception('Unauthorized. Please login again.');
        case 403:
          return Exception('Access denied. You don\'t have permission.');
        case 404:
          return Exception('Sale not found.');
        case 400:
          final message = data['message'] ?? 'Invalid request';
          return Exception(message);
        case 500:
          return Exception('Server error. Please try again later.');
        default:
          final message = data['message'] ?? 'Failed to process request';
          return Exception(message);
      }
    } else {
      return Exception('Network error. Please check your connection.');
    }
  }
}
