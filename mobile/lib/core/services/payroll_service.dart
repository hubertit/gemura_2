import 'package:dio/dio.dart';
import 'authenticated_dio_service.dart';

class PayrollService {
  final Dio _dio = AuthenticatedDioService.instance;

  /// Generate payroll with selected suppliers and date range
  Future<Map<String, dynamic>> generatePayroll({
    required List<String> supplierAccountCodes,
    required DateTime periodStart,
    required DateTime periodEnd,
    int? paymentTermsDays,
  }) async {
    try {
      final response = await _dio.post(
        '/payroll/runs/generate',
        data: {
          'supplier_account_codes': supplierAccountCodes,
          'period_start': periodStart.toIso8601String().split('T')[0],
          'period_end': periodEnd.toIso8601String().split('T')[0],
          if (paymentTermsDays != null) 'payment_terms_days': paymentTermsDays,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to generate payroll');
        }
      } else {
        throw Exception('Failed to generate payroll: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to generate payroll. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 400) {
        final backendMsg = e.response?.data?['message'];
        errorMessage = backendMsg ?? 'Invalid payroll data. Please check your input.';
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

  /// Get payroll runs
  Future<List<Map<String, dynamic>>> getPayrollRuns() async {
    try {
      final response = await _dio.get('/payroll/runs');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        } else {
          throw Exception(data['message'] ?? 'Failed to get payroll runs');
        }
      } else {
        throw Exception('Failed to get payroll runs: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get payroll runs. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
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

  /// Mark payroll as paid
  Future<Map<String, dynamic>> markPayrollAsPaid({
    required String runId,
    DateTime? paymentDate,
    String? payslipId,
  }) async {
    try {
      final response = await _dio.post(
        '/payroll/runs/$runId/mark-paid',
        data: {
          if (paymentDate != null) 'payment_date': paymentDate.toIso8601String().split('T')[0],
          if (payslipId != null) 'payslip_id': payslipId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to mark payroll as paid');
        }
      } else {
        throw Exception('Failed to mark payroll as paid: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to mark payroll as paid. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 400) {
        final backendMsg = e.response?.data?['message'];
        errorMessage = backendMsg ?? 'Invalid request. Please check your input.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Payroll run not found.';
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

  /// Export payroll to Excel or PDF
  /// Returns the file bytes that can be saved to a file
  Future<List<int>> exportPayroll({
    required String runId,
    String format = 'excel', // 'excel' or 'pdf'
  }) async {
    try {
      final response = await _dio.get(
        '/payroll/runs/$runId/export',
        queryParameters: {'format': format},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': format == 'pdf' 
              ? 'application/pdf' 
              : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Return the file bytes - UI layer should handle saving to file
        return List<int>.from(response.data);
      } else {
        throw Exception('Failed to export payroll: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to export payroll. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Payroll run not found.';
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
