import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/localization_provider.dart';
import '../providers/products_provider.dart';
import '../../domain/models/product.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';

class AllProductsScreen extends ConsumerWidget {
  const AllProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizationService = ref.watch(localizationServiceProvider);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          localizationService.translate('featuredProducts'),
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) => products.isEmpty
            ? _buildEmptyState(localizationService)
            : _buildProductsGrid(products, localizationService),
        loading: () => SkeletonLoaders.productsGridSkeleton(count: 8),
        error: (error, stack) => Center(
          child: Text(
            'Error loading products: $error',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic localizationService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            localizationService.translate('noProductsAvailable') ?? 'No products available',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            localizationService.translate('checkBackLater') ?? 'Check back later for new products',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products, dynamic localizationService) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppTheme.spacing16,
        mainAxisSpacing: AppTheme.spacing16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index], localizationService);
      },
    );
  }

  Widget _buildProductCard(Product product, dynamic localizationService) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to product details
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.borderRadius12),
                  ),
                  image: product.imageUrl != null ? DecorationImage(
                    image: NetworkImage(product.imageUrl!),
                    fit: BoxFit.cover,
                  ) : null,
                ),
              ),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      product.seller.name,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RWF ${product.price.toStringAsFixed(0)}',
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing8,
                            vertical: AppTheme.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: product.isAvailable 
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                          ),
                          child: Text(
                            product.isAvailable 
                                ? (localizationService.translate('available') ?? 'Available')
                                : (localizationService.translate('unavailable') ?? 'Unavailable'),
                            style: AppTheme.bodySmall.copyWith(
                              color: product.isAvailable 
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
}
