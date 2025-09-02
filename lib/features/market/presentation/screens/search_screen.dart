import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_formatter.dart';
import '../providers/search_provider.dart';
import '../providers/categories_provider.dart';
import 'product_details_screen.dart';
import '../../domain/models/product.dart';

class MarketSearchScreen extends ConsumerStatefulWidget {
  const MarketSearchScreen({super.key});

  @override
  ConsumerState<MarketSearchScreen> createState() => _MarketSearchScreenState();
}

class _MarketSearchScreenState extends ConsumerState<MarketSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _showFilters = false;
  String _selectedSortBy = 'newest';
  int? _selectedCategoryId;
  RangeValues _priceRange = const RangeValues(0, 10000);
  String? _selectedSellerType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Listen to search controller changes for real-time search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _performSearch();
    } else {
      ref.read(searchProvider.notifier).clearSearch();
    }
  }

  void _performSearch() {
    final filters = SearchFilters(
      query: _searchController.text.trim(),
      categoryId: _selectedCategoryId,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      sellerType: _selectedSellerType,
      sortBy: _selectedSortBy,
    );
    
    ref.read(searchProvider.notifier).search(filters);
  }

  void _applyFilters() {
    setState(() {
      _showFilters = false;
    });
    _performSearch();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _priceRange = const RangeValues(0, 10000);
      _selectedSellerType = null;
      _selectedSortBy = 'newest';
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Products',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Filters Section
          if (_showFilters) _buildFiltersSection(categoriesAsync),
          
          // Search Results
          Expanded(
            child: _buildSearchResults(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(AsyncValue categoriesAsync) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Clear All',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          
          // Category Filter
          Text(
            'Category',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          categoriesAsync.when(
            data: (categories) => Wrap(
              spacing: AppTheme.spacing8,
              children: categories.map((category) {
                final isSelected = _selectedCategoryId == category.id;
                return FilterChip(
                  label: Text(category.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategoryId = selected ? category.id : null;
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }).toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error loading categories'),
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Price Range Filter
          Text(
            'Price Range (RWF)',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              '${_priceRange.start.round()}',
              '${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Seller Type Filter
          Text(
            'Seller Type',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing8,
            children: [
              'mcc',
              'farmer',
              'supplier',
              'agent',
            ].map((type) {
              final isSelected = _selectedSellerType == type;
              return FilterChip(
                label: Text(type.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSellerType = selected ? type : null;
                  });
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Sort Options
          Text(
            'Sort By',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing8,
            children: [
              {'value': 'newest', 'label': 'Newest'},
              {'value': 'oldest', 'label': 'Oldest'},
              {'value': 'price_low', 'label': 'Price: Low to High'},
              {'value': 'price_high', 'label': 'Price: High to Low'},
              {'value': 'name', 'label': 'Name A-Z'},
            ].map((sortOption) {
              final isSelected = _selectedSortBy == sortOption['value'];
              return FilterChip(
                label: Text(sortOption['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSortBy = sortOption['value']!;
                  });
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppTheme.spacing16),
          
          // Apply Filters Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.surfaceColor,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              ),
              child: Text(
                'Apply Filters',
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<SearchResult?> searchState) {
    return searchState.when(
      data: (searchResult) {
        if (searchResult == null) {
          return const Center(
            child: Text('Start typing to search products'),
          );
        }
        
        if (searchResult.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'No products found',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Try adjusting your search terms or filters',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            // Results Header
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${searchResult.total} products found',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (searchResult.filters.query?.isNotEmpty == true)
                    Text(
                      'for "${searchResult.filters.query}"',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
            
            // Products List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppTheme.spacing16),
                itemCount: searchResult.products.length + (searchResult.hasNextPage ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == searchResult.products.length) {
                    // Loading indicator for pagination
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  final product = searchResult.products[index];
                  return _buildProductCard(product);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Search failed',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              error.toString(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.borderRadius12),
                  bottomLeft: Radius.circular(AppTheme.borderRadius12),
                ),
                image: product.imageUrl != null ? DecorationImage(
                  image: NetworkImage(product.imageUrl!),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: product.imageUrl == null ? Center(
                child: Icon(
                  _getProductIcon(product.name),
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ) : null,
            ),
            
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    
                    // Category
                    if (product.categories.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing8,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                        child: Text(
                          product.categories.first,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppTheme.spacing8),
                    
                    // Seller Info
                    Text(
                      'by ${product.seller.name}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    
                    // Price
                    Text(
                      NumberFormatter.formatRWF(product.price),
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProductIcon(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('milk')) return Icons.local_drink;
    if (name.contains('cheese')) return Icons.restaurant;
    if (name.contains('yogurt')) return Icons.icecream;
    if (name.contains('butter')) return Icons.cake;
    if (name.contains('cream')) return Icons.water_drop;
    if (name.contains('powder')) return Icons.inventory_2;
    if (name.contains('ice cream')) return Icons.icecream;
    if (name.contains('condensed')) return Icons.local_drink;
    return Icons.inventory_2;
  }
}
