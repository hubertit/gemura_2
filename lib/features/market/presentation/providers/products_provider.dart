import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';

// API Base URL
const String baseUrl = 'https://api.gemura.rw/v2/market';

// HTTP Client Provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// Products Provider - fetches all products from API
final productsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    print('🔄 Fetching all products from: $baseUrl/products/list.php?limit=100');
    final response = await ref.read(httpClientProvider).get(
      Uri.parse('$baseUrl/products/list.php?limit=100'),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 All products response status: ${response.statusCode}');
    print('📡 All products response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 200 && data['data'] != null) {
        final products = (data['data']['products'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
        print('✅ All products loaded successfully: ${products.length} products');
        return products;
      }
    }
    
    throw Exception('Failed to load products: ${response.statusCode} - ${response.body}');
  } catch (e) {
    print('❌ Error loading products: $e');
    throw Exception('Error loading products: $e');
  }
});

// Featured Products Provider - fetches featured products from API
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    print('🔄 Fetching featured products from: $baseUrl/products/featured.php?limit=5');
    final response = await ref.read(httpClientProvider).get(
      Uri.parse('$baseUrl/products/featured.php?limit=5'),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 Featured products response status: ${response.statusCode}');
    print('📡 Featured products response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 200 && data['data'] != null) {
        final products = (data['data']['products'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
        print('✅ Featured products loaded successfully: ${products.length} products');
        return products;
      }
    }
    
    throw Exception('Failed to load featured products: ${response.statusCode} - ${response.body}');
  } catch (e) {
    print('❌ Error loading featured products: $e');
    throw Exception('Error loading featured products: $e');
  }
});

// Recent Products Provider - fetches recent products from API
final recentProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    print('🔄 Fetching recent products from: $baseUrl/products/recent.php?limit=10');
    final response = await ref.read(httpClientProvider).get(
      Uri.parse('$baseUrl/products/recent.php?limit=10'),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 Recent products response status: ${response.statusCode}');
    print('📡 Recent products response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code'] == 200 && data['data'] != null) {
        final products = (data['data']['products'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
        print('✅ Recent products loaded successfully: ${products.length} products');
        return products;
      }
    }
    
    throw Exception('Failed to load recent products: ${response.statusCode} - ${response.body}');
  } catch (e) {
    print('❌ Error loading recent products: $e');
    throw Exception('Error loading recent products: $e');
  }
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
        final categories = (data['data'] as List)
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
