import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/product.dart';

// API Base URL
const String baseUrl = 'https://api.gemura.rw/v2/market';

// HTTP Client Provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

class SearchFilters {
  final String? query;
  final int? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final String? sellerType;
  final String sortBy;
  final int limit;
  final int offset;

  SearchFilters({
    this.query,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.sellerType,
    this.sortBy = 'newest',
    this.limit = 20,
    this.offset = 0,
  });

  SearchFilters copyWith({
    String? query,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sellerType,
    String? sortBy,
    int? limit,
    int? offset,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sellerType: sellerType ?? this.sellerType,
      sortBy: sortBy ?? this.sortBy,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    
    if (query != null && query!.isNotEmpty) {
      params['q'] = query!;
    }
    if (categoryId != null) {
      params['category_id'] = categoryId.toString();
    }
    if (minPrice != null) {
      params['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      params['max_price'] = maxPrice.toString();
    }
    if (sellerType != null && sellerType!.isNotEmpty) {
      params['seller_type'] = sellerType!;
    }
    if (sortBy != 'newest') {
      params['sort_by'] = sortBy;
    }
    if (limit != 20) {
      params['limit'] = limit.toString();
    }
    if (offset != 0) {
      params['offset'] = offset.toString();
    }
    
    return params;
  }
}

class SearchResult {
  final List<Product> products;
  final int total;
  final int perPage;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final SearchFilters filters;

  SearchResult({
    required this.products,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.filters,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json, SearchFilters filters) {
    final products = (json['products'] as List)
        .map((productJson) => Product.fromJson(productJson))
        .toList();

    return SearchResult(
      products: products,
      total: json['total'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 20,
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      hasNextPage: json['has_next'] as bool? ?? false,
      hasPreviousPage: json['has_prev'] as bool? ?? false,
      filters: filters,
    );
  }
}

class SearchNotifier extends StateNotifier<AsyncValue<SearchResult?>> {
  final http.Client _httpClient;
  
  SearchNotifier(this._httpClient) : super(const AsyncValue.data(null));

  Future<void> search(SearchFilters filters) async {
    state = const AsyncValue.loading();
    
    try {
      final queryParams = filters.toQueryParameters();
      final uri = Uri.parse('$baseUrl/products/search.php').replace(queryParameters: queryParams);
      
      final response = await _httpClient.get(uri, headers: {'Content-Type': 'application/json'});
      
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['code'] == 200) {
          final searchResult = SearchResult.fromJson(responseBody['data'], filters);
          state = AsyncValue.data(searchResult);
        } else {
          state = AsyncValue.error(
            responseBody['message'] ?? 'Search failed',
            StackTrace.current,
          );
        }
      } else {
        state = AsyncValue.error(
          'HTTP error: ${response.statusCode}',
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasNextPage) return;

    try {
      final nextFilters = currentState.filters.copyWith(
        offset: currentState.products.length,
      );

      final queryParams = nextFilters.toQueryParameters();
      final uri = Uri.parse('$baseUrl/products/search.php').replace(queryParameters: queryParams);
      
      final response = await _httpClient.get(uri, headers: {'Content-Type': 'application/json'});
      
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['code'] == 200) {
          final nextResult = SearchResult.fromJson(responseBody['data'], nextFilters);
          
          // Combine current and new products
          final combinedProducts = [...currentState.products, ...nextResult.products];
          
          final combinedResult = SearchResult(
            products: combinedProducts,
            total: nextResult.total,
            perPage: nextResult.perPage,
            currentPage: nextResult.currentPage,
            totalPages: nextResult.totalPages,
            hasNextPage: nextResult.hasNextPage,
            hasPreviousPage: nextResult.hasPreviousPage,
            filters: nextResult.filters,
          );
          
          state = AsyncValue.data(combinedResult);
        }
      }
    } catch (error, stackTrace) {
      print('Error loading more products: $error');
    }
  }

  void clearSearch() {
    state = const AsyncValue.data(null);
  }
}

final marketSearchProvider = StateNotifierProvider<SearchNotifier, AsyncValue<SearchResult?>>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  return SearchNotifier(httpClient);
});
