import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../domain/models/product.dart';
import '../providers/products_provider.dart';
import 'product_details_screen.dart';

class SellerProfileScreen extends ConsumerStatefulWidget {
  final TopSeller seller;

  const SellerProfileScreen({
    super.key,
    required this.seller,
  });

  @override
  ConsumerState<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  int _followerCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Simulate initial follower count
    _followerCount = widget.seller.totalSales ~/ 10; // Rough estimate
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = ref.watch(localizationServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.seller.name,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: _buildProfileHeader(),
          ),
          // Stats and Follow Button
          SliverToBoxAdapter(
            child: _buildStatsAndActions(),
          ),
          // Bio Section
          SliverToBoxAdapter(
            child: _buildBioSection(),
          ),
          // Tab Bar
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.surfaceColor,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                labelStyle: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: localizationService.translate('products')),
                  Tab(text: localizationService.translate('reviews')),
                  Tab(text: 'About'),
                ],
              ),
            ),
          ),
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildReviewsTab(),
                _buildAboutTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: [
          // Profile Picture
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  widget.seller.name.substring(0, 1).toUpperCase(),
                  style: AppTheme.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.seller.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.surfaceColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppTheme.spacing16),
          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.seller.name,
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.seller.location,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Rating
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.seller.rating.toString(),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${widget.seller.totalProducts} products)',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: Column(
        children: [
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Products', widget.seller.totalProducts.toString()),
              _buildStatItem('Followers', _followerCount.toString()),
              _buildStatItem('Following', '${_followerCount ~/ 2}'),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isFollowing = !_isFollowing;
                      if (_isFollowing) {
                        _followerCount++;
                      } else {
                        _followerCount--;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? AppTheme.surfaceColor : AppTheme.primaryColor,
                    foregroundColor: _isFollowing ? AppTheme.textPrimaryColor : Colors.white,
                    side: BorderSide(
                      color: _isFollowing ? AppTheme.thinBorderColor : AppTheme.primaryColor,
                      width: AppTheme.thinBorderWidth,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                  child: Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isFollowing ? AppTheme.textPrimaryColor : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement message functionality
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.thinBorderColor,
                      width: AppTheme.thinBorderWidth,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                  child: Text(
                    'Message',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${widget.seller.name}',
            style: AppTheme.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Premium dairy products from ${widget.seller.location}. '
            'We specialize in fresh, high-quality dairy products '
            'delivered directly from our farm to your doorstep.',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimaryColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                widget.seller.location,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Icon(
                Icons.calendar_today,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Joined ${widget.seller.joinDate}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final productsAsync = ref.watch(productsProvider);
        return productsAsync.when(
          data: (products) {
            // Filter products by seller
            final sellerProducts = products.where((p) => p.sellerId == widget.seller.id).toList();
            
            if (sellerProducts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      'No products available',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'This seller hasn\'t added any products yet',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.spacing12,
                mainAxisSpacing: AppTheme.spacing12,
                childAspectRatio: 0.8,
              ),
              itemCount: sellerProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(sellerProducts[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Error loading products',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.borderRadius12),
                    topRight: Radius.circular(AppTheme.borderRadius12),
                  ),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppTheme.borderRadius12),
                          topRight: Radius.circular(AppTheme.borderRadius12),
                        ),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.inventory_2,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RWF ${product.price.toStringAsFixed(0)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    // Mock reviews data
    final reviews = [
      {
        'name': 'John Doe',
        'rating': 5.0,
        'comment': 'Excellent quality products! Very fresh and delivered on time.',
        'date': '2 days ago',
      },
      {
        'name': 'Jane Smith',
        'rating': 4.0,
        'comment': 'Good service, but delivery was a bit late.',
        'date': '1 week ago',
      },
      {
        'name': 'Mike Johnson',
        'rating': 5.0,
        'comment': 'Amazing dairy products! Will definitely order again.',
        'date': '2 weeks ago',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
          padding: const EdgeInsets.all(AppTheme.spacing16),
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      (review['name'] as String).substring(0, 1).toUpperCase(),
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['name'] as String,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              return Icon(
                                i < (review['rating'] as double).toInt()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              review['date'] as String,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                review['comment'] as String,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimaryColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Contact Information',
            [
              _buildInfoRow('Phone', widget.seller.phone ?? 'Not provided'),
              _buildInfoRow('Email', widget.seller.email ?? 'Not provided'),
              _buildInfoRow('Location', widget.seller.location),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildInfoCard(
            'Business Information',
            [
              _buildInfoRow('Seller Code', widget.seller.code),
              _buildInfoRow('Join Date', widget.seller.joinDate),
              _buildInfoRow('Verification', widget.seller.isVerified ? 'Verified' : 'Not Verified'),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildInfoCard(
            'Performance',
            [
              _buildInfoRow('Rating', '${widget.seller.rating}/5.0'),
              _buildInfoRow('Total Products', widget.seller.totalProducts.toString()),
              _buildInfoRow('Total Sales', widget.seller.totalSales.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
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
          Text(
            title,
            style: AppTheme.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report),
              title: Text(
                'Report Seller',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(
                'Share Profile',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(
                'Block Seller',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement block functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
