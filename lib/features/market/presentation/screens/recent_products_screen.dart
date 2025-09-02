import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/providers/localization_provider.dart';
import '../providers/products_provider.dart';
import '../../domain/models/product.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import 'search_screen.dart';

class RecentProductsScreen extends ConsumerWidget {
  const RecentProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizationService = ref.watch(localizationServiceProvider);
    final recentProductsAsync = ref.watch(recentProductsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          localizationService.translate('recentListings'),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarketSearchScreen(),
                ),
              );
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
      body: recentProductsAsync.when(
        data: (recentProducts) => recentProducts.isEmpty
            ? _buildEmptyState(localizationService)
            : _buildRecentProductsList(recentProducts, localizationService),
        loading: () => SkeletonLoaders.productsListSkeleton(count: 6),
        error: (error, stack) => Center(
          child: Text(
            'Error loading recent products: $error',
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
            Icons.history_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            localizationService.translate('noRecentProducts') ?? 'No recent products',
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

  Widget _buildRecentProductsList(List<Product> products, dynamic localizationService) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildRecentProductCard(products[index], localizationService, index);
      },
    );
  }

  Widget _buildRecentProductCard(Product product, dynamic localizationService, int index) {
    return Container(
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius12),
                bottomLeft: Radius.circular(AppTheme.borderRadius12),
              ),
              image: product.imageUrl != null ? DecorationImage(
                image: NetworkImage(product.imageUrl!),
                fit: BoxFit.cover,
              ) : null,
            ),
          ),
          
          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                          '#${index + 1}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Expanded(
                        child: Text(
                          product.name,
                          style: AppTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                                          Text(
                          product.seller.name,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  const SizedBox(height: AppTheme.spacing4),
                  if (product.description != null)
                    Text(
                      product.description!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppTheme.spacing12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        NumberFormatter.formatRWF(product.price),
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: AppTheme.spacing4),
                          Text(
                            _getTimeAgo(product.createdAt),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
