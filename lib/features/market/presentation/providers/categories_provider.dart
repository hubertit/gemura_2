import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/category.dart';

// API Base URL
const String baseUrl = 'https://api.gemura.rw/v2/market';

// HTTP Client Provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// Categories Provider - fetches all categories from API
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    print('🔄 Fetching categories from: $baseUrl/categories/list.php');
    final response = await ref.read(httpClientProvider).get(
      Uri.parse('$baseUrl/categories/list.php'),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 Categories response status: ${response.statusCode}');
    print('📡 Categories response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 200 && data['data'] != null) {
        final categories = (data['data']['categories'] as List)
            .map((json) => Category.fromJson(json))
            .toList();
        print('✅ Categories loaded successfully: ${categories.length} categories');
        return categories;
      }
    }
    
    throw Exception('Failed to load categories: ${response.statusCode} - ${response.body}');
  } catch (e) {
    print('❌ Error loading categories: $e');
    throw Exception('Error loading categories: $e');
  }
});
