import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/secure_storage_service.dart';

class ReportService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  static Future<Map<String, dynamic>> getMyReport(String period) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Use localhost for development
      final apiUrl = 'http://localhost/gemura2/api/v2/reports/my_report.php';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'period': period,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch report');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }
}
