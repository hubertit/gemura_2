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

// Top Seller model for displaying top performing sellers
class TopSeller {
  final int id;
  final String code;
  final String name;
  final String? phone;
  final String? email;
  final String? imageUrl;
  final double rating;
  final int totalSales;
  final int totalProducts;
  final int totalReviews;
  final String location;
  final bool isVerified;
  final String joinDate;

  TopSeller({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.imageUrl,
    required this.rating,
    required this.totalSales,
    required this.totalProducts,
    required this.totalReviews,
    required this.location,
    required this.isVerified,
    required this.joinDate,
  });

  factory TopSeller.fromJson(Map<String, dynamic> json) {
    return TopSeller(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      imageUrl: json['image_url'] as String?,
      rating: (json['rating'] as num).toDouble(),
      totalSales: json['total_sales'] as int,
      totalProducts: json['total_products'] as int,
      totalReviews: json['total_reviews'] as int,
      location: json['location'] as String,
      isVerified: json['is_verified'] as bool,
      joinDate: json['join_date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'email': email,
      'image_url': imageUrl,
      'rating': rating,
      'total_sales': totalSales,
      'total_products': totalProducts,
      'total_reviews': totalReviews,
      'location': location,
      'is_verified': isVerified,
      'join_date': joinDate,
    };
  }
}

// Top Sellers Provider - static top performing sellers
final topSellersProvider = FutureProvider<List<TopSeller>>((ref) async {
  // Simulate API delay
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Static top sellers data
  final topSellers = [
    TopSeller(
      id: 1,
      code: 'KDF001',
      name: 'Kigali Dairy Farm',
      phone: '+250788123456',
      email: 'info@kigalifarm.rw',
      imageUrl: null,
      rating: 4.8,
      totalSales: 1250,
      totalProducts: 15,
      totalReviews: 89,
      location: '-1.9441,30.0619', // Kigali coordinates
      isVerified: true,
      joinDate: '2023-01-15',
    ),
    TopSeller(
      id: 2,
      code: 'HDC002',
      name: 'Healthy Dairy Co.',
      phone: '+250788234567',
      email: 'contact@healthydairy.rw',
      imageUrl: null,
      rating: 4.9,
      totalSales: 980,
      totalProducts: 12,
      totalReviews: 67,
      location: '-1.4998,29.6344', // Musanze coordinates
      isVerified: true,
      joinDate: '2023-03-20',
    ),
    TopSeller(
      id: 3,
      code: 'MCF003',
      name: 'Mountain Cheese Farm',
      phone: '+250788345678',
      email: 'orders@mountaincheese.rw',
      imageUrl: null,
      rating: 4.7,
      totalSales: 750,
      totalProducts: 8,
      totalReviews: 45,
      location: '-1.6936,29.2356', // Rubavu coordinates
      isVerified: true,
      joinDate: '2023-02-10',
    ),
    TopSeller(
      id: 4,
      code: 'GDP004',
      name: 'Golden Dairy Products',
      phone: '+250788456789',
      email: 'sales@goldendairy.rw',
      imageUrl: null,
      rating: 4.6,
      totalSales: 650,
      totalProducts: 10,
      totalReviews: 52,
      location: '-2.6031,29.7439', // Huye coordinates
      isVerified: true,
      joinDate: '2023-04-05',
    ),
    TopSeller(
      id: 5,
      code: 'CD005',
      name: 'Creamy Delights',
      phone: '+250788567890',
      email: 'info@creamy.rw',
      imageUrl: null,
      rating: 4.8,
      totalSales: 420,
      totalProducts: 6,
      totalReviews: 28,
      location: '-1.3048,30.3285', // Nyagatare coordinates
      isVerified: false,
      joinDate: '2023-05-12',
    ),
  ];
  
  print('✅ Static top sellers loaded successfully: ${topSellers.length} sellers');
  return topSellers;
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
