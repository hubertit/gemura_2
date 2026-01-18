import 'package:dio/dio.dart';
import '../../../../core/services/authenticated_dio_service.dart';

class ReportService {
  static final Dio _dio = AuthenticatedDioService.instance;

  static Future<Map<String, dynamic>> getMyReport(String period) async {
    try {
      // NestJS uses POST /reports/my-report
      final response = await _dio.post(
        '/reports/my-report',
        data: {
          'period': period,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch report');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to fetch report: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }
}
