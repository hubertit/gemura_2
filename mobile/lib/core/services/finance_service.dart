import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'authenticated_dio_service.dart';
import 'secure_storage_service.dart';
import '../../features/finance/domain/models/income_statement.dart';
import '../../features/finance/domain/models/transaction.dart';

class FinanceService {
  /// Get income statement (Revenue and Expenses)
  Future<IncomeStatement> getIncomeStatement({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      final fromDateStr = fromDate.toIso8601String().split('T')[0];
      final toDateStr = toDate.toIso8601String().split('T')[0];

      print('📊 Fetching income statement: $fromDateStr to $toDateStr');
      print('🌐 API URL: ${AppConfig.apiBaseUrl}/accounting/reports/income-statement');

      final response = await AuthenticatedDioService.instance.get(
        '/accounting/reports/income-statement',
        queryParameters: {
          'from_date': fromDateStr,
          'to_date': toDateStr,
        },
      );

      print('✅ Income statement response: ${response.data}');

      if (response.data['code'] == 200 && response.data['data'] != null) {
        return IncomeStatement.fromJson(response.data['data']);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Income statement DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Income statement Exception: $e');
      throw Exception('Failed to fetch income statement: $e');
    }
  }

  /// Record a revenue or expense transaction
  Future<Transaction> createTransaction({
    required String type, // 'revenue' or 'expense'
    required double amount,
    required String description,
    required DateTime transactionDate,
    String? accountId,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      final transactionDateStr = transactionDate.toIso8601String().split('T')[0];

      print('💰 Creating transaction: $type - $amount');
      print('🌐 API URL: ${AppConfig.apiBaseUrl}/accounting/transactions');

      final response = await AuthenticatedDioService.instance.post(
        '/accounting/transactions',
        data: {
          'type': type,
          'amount': amount,
          'description': description,
          'transaction_date': transactionDateStr,
          if (accountId != null) 'account_id': accountId,
        },
      );

      print('✅ Transaction response: ${response.data}');

      if (response.data['code'] == 200 && response.data['data'] != null) {
        return Transaction.fromJson(response.data['data']);
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Transaction DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Transaction Exception: $e');
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Get transactions
  Future<List<Transaction>> getTransactions({
    String? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? limit,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token available');
      }

      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      if (limit != null) queryParams['limit'] = limit;

      print('📋 Fetching transactions');
      print('🌐 API URL: ${AppConfig.apiBaseUrl}/accounting/transactions');

      final response = await AuthenticatedDioService.instance.get(
        '/accounting/transactions',
        queryParameters: queryParams,
      );

      print('✅ Transactions response: ${response.data}');

      if (response.data['code'] == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      print('❌ Transactions DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('❌ Transactions Exception: $e');
      throw Exception('Failed to fetch transactions: $e');
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
          return Exception('Resource not found.');
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
