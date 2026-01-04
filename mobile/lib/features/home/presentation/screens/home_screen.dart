import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../providers/tab_index_provider.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/number_formatter.dart';
import '../../../merchant/presentation/screens/wallets_screen.dart';
import '../../../merchant/presentation/screens/transactions_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../merchant/presentation/providers/wallets_provider.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../../core/providers/localization_provider.dart';

import '../../../../shared/models/overview.dart';
import 'package:d_chart/d_chart.dart';
import '../../../../shared/models/wallet.dart';
import 'package:intl/intl.dart';

import 'search_screen.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../suppliers/presentation/screens/suppliers_list_screen.dart';
import '../../../customers/presentation/screens/customers_list_screen.dart';
import '../../../suppliers/presentation/screens/collected_milk_screen.dart';
import '../../../customers/presentation/screens/sold_milk_screen.dart';
import '../../../account_access/presentation/screens/manage_account_access_screen.dart';
import '../../../agent_reports/presentation/screens/agent_report_screen.dart';
import '../providers/overview_provider.dart';
import '../../../../shared/models/user_accounts.dart';
import '../providers/user_accounts_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../shared/widgets/error_boundary.dart';
import '../../../../shared/widgets/profile_completion_widget.dart';
import '../../../../shared/widgets/account_type_badge.dart';
import '../../../market/presentation/providers/products_provider.dart';
import '../../../market/presentation/screens/all_products_screen.dart';
import '../../../market/presentation/screens/product_details_screen.dart';
import '../../../market/presentation/screens/search_screen.dart';
import '../../../market/presentation/screens/user_profile_screen.dart';

import '../../../market/domain/models/product.dart';
import '../../../market/domain/models/category.dart';
import '../../../referrals/presentation/screens/referral_screen.dart';
import '../../../../core/services/modules_service.dart';
import '../../../../shared/models/module.dart';
import '../../../../shared/widgets/module_card.dart';
import 'module_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(tabIndexProvider);
    final localizationService = ref.watch(localizationServiceProvider);
    
    final tabs = [
      const _DashboardTab(), // Index 0: Home
      const FeedScreen(), // Index 1: Feed
      const WalletsScreen(), // Index 2: Ikofi
      const ChatListScreen(), // Index 3: Chat
      const ProfileTab(), // Index 4: Profile
    ];
    
    // Add error boundary for tabs
    Widget currentTab;
    try {
      currentTab = tabs[currentIndex];
    } catch (e) {
      print('🔧 HomeScreen: Error loading tab at index $currentIndex: $e');
      currentTab = const _DashboardTab(); // Fallback to home tab
    }
    
    return Scaffold(
      body: ErrorBoundary(
        child: currentTab,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(tabIndexProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: localizationService.translate('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.dynamic_feed_outlined),
            selectedIcon: const Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: 'Ikofi',
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: localizationService.translate('chats'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: localizationService.translate('profile'),
          ),
        ],
      ),
    );
  }
}

class _MarketTab extends ConsumerWidget {
  const _MarketTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizationService = ref.watch(localizationServiceProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            localizationService.translate('market'),
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: -0.5,
            ),
          ),
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

        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh market data
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // Featured Products Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: AppTheme.spacing16,
                ),
                child: _buildSectionTitle(localizationService.translate('featuredProducts'), localizationService, context),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final featuredProductsAsync = ref.watch(featuredProductsProvider);
                  return featuredProductsAsync.when(
                    data: (featuredProducts) => SizedBox(
                      height: 200,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                        scrollDirection: Axis.horizontal,
                        itemCount: featuredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildFeaturedProductCard(featuredProducts[index], localizationService, context);
                        },
                      ),
                    ),
                    loading: () => SkeletonLoaders.featuredProductsHomeSkeleton(),
                    error: (error, stack) => SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'Error loading featured products',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Categories Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: AppTheme.spacing16,
                ),
                child: _buildSectionTitle(localizationService.translate('categories'), localizationService, context),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final categoriesAsync = ref.watch(categoriesProvider);
                  return categoriesAsync.when(
                    data: (categories) => SizedBox(
                      height: 100,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _buildCategoryCard(category, localizationService);
                        },
                      ),
                    ),
                    loading: () => SkeletonLoaders.categoriesListSkeleton(),
                    error: (error, stack) => SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Error loading categories',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Recent Listings Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: AppTheme.spacing16,
                ),
                child: _buildSectionTitle(localizationService.translate('recentListings'), localizationService, context),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final recentProductsAsync = ref.watch(recentProductsProvider);
                  return recentProductsAsync.when(
                    data: (recentProducts) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                      child: Column(
                        children: recentProducts.take(3).map((product) => 
                          _buildProductCard(product, localizationService, context)
                        ).toList(),
                      ),
                    ),
                    loading: () => SkeletonLoaders.recentProductsHomeSkeleton(),
                    error: (error, stack) => Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Center(
                        child: Text(
                          'Error loading recent products',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Top Sellers Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: AppTheme.spacing16,
                ),
                child: _buildSectionTitle(localizationService.translate('topSellers'), localizationService, context),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final topSellersAsync = ref.watch(topSellersProvider);
                  return topSellersAsync.when(
                    data: (topSellers) => SizedBox(
                      height: 180,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                        scrollDirection: Axis.horizontal,
                        itemCount: topSellers.length,
                        itemBuilder: (context, index) {
                          return _buildTopSellerCard(topSellers[index], localizationService, context);
                        },
                      ),
                    ),
                    loading: () => SkeletonLoaders.featuredProductsHomeSkeleton(),
                    error: (error, stack) => SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          'Error loading top sellers',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Bottom padding
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, dynamic localizationService, BuildContext context) {
    // Only show "see all" button for featured products
    final showSeeAllButton = title == localizationService.translate('featuredProducts');
    
    return Row(
      mainAxisAlignment: showSeeAllButton ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        if (showSeeAllButton)
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllProductsScreen(),
                ),
              );
            },
            child: Text(
              localizationService.translate('seeAll'),
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedProductCard(Product product, dynamic localizationService, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: AppTheme.spacing16),
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
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.borderRadius12),
                  topRight: Radius.circular(AppTheme.borderRadius12),
                ),
                image: product.imageUrl != null ? DecorationImage(
                  image: NetworkImage(product.imageUrl!),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: product.imageUrl == null ? Center(
                child: Icon(
                  _getProductIconByName(product.name),
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ) : null,
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormatter.formatRWF(product.price),
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

  Widget _buildTopSellerCard(TopSeller seller, dynamic localizationService, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(user: seller),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppTheme.spacing16),
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
            // Seller Avatar and Verification Badge
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.borderRadius12),
                  topRight: Radius.circular(AppTheme.borderRadius12),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        seller.name.substring(0, 1).toUpperCase(),
                        style: AppTheme.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (seller.isVerified)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Seller Info
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seller.name,
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    seller.location,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 10,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        seller.rating.toString(),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category, dynamic localizationService) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to category
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: AppTheme.spacing16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Icon(
                _getCategoryIcon(category.name),
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              category.name,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, dynamic localizationService, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
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
            Container(
              width: 80,
              height: 80,
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
              child: product.imageUrl == null ? Icon(
                _getProductIconByName(product.name),
                size: 32,
                color: AppTheme.primaryColor,
              ) : null,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.seller.name,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        NumberFormatter.formatRWF(product.price),
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                        child: Text(
                          localizationService.translate('buyNow'),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
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
    ));
  }

  IconData _getProductIconByName(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('milk')) return Icons.local_drink;
    if (name.contains('cheese')) return Icons.restaurant;
    if (name.contains('yogurt')) return Icons.icecream;
    if (name.contains('butter')) return Icons.cake;
    if (name.contains('cream')) return Icons.water_drop;
    if (name.contains('powder')) return Icons.inventory_2;
    if (name.contains('ice cream')) return Icons.icecream;
    if (name.contains('condensed')) return Icons.local_drink;
    return Icons.inventory_2; // Default icon
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('dairy')) return Icons.local_drink;
    if (name.contains('milk')) return Icons.local_drink;
    if (name.contains('cheese')) return Icons.restaurant;
    if (name.contains('yogurt')) return Icons.icecream;
    if (name.contains('butter')) return Icons.cake;
    if (name.contains('cream')) return Icons.water_drop;
    if (name.contains('beverages')) return Icons.local_cafe;
    if (name.contains('snacks')) return Icons.fastfood;
    if (name.contains('grains')) return Icons.grain;
    if (name.contains('vegetables')) return Icons.eco;
    if (name.contains('fruits')) return Icons.apple;
    if (name.contains('meat')) return Icons.set_meal;
    return Icons.category; // Default icon
  }
}

class _DashboardTab extends ConsumerStatefulWidget {
  const _DashboardTab();

  @override
  ConsumerState<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<_DashboardTab> {
  // Wallet balance visibility state
  final Map<String, bool> _walletBalanceVisibility = {};

  // Method to handle balance visibility changes
  void _onBalanceVisibilityChanged(String walletId, bool showBalance) {
    setState(() {
      _walletBalanceVisibility[walletId] = showBalance;
    });
  }

  // Helper method to capitalize first letter
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Static mock wallets as fallback for home screen - Joint ikofi temporarily hidden
  List<Wallet> get homeWallets => [
    Wallet(
      id: 'WALLET-1',
      name: 'Main Ikofi',
      balance: 250000,
      currency: 'RWF',
      type: 'individual',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      owners: ['You'],
      isDefault: true,
    ),
    // Temporarily hidden - Joint Ikofi
    // Wallet(
    //   id: 'WALLET-2',
    //   name: 'Joint Ikofi',
    //   balance: 1200000,
    //   currency: 'RWF',
    //   type: 'joint',
    //   status: 'active',
    //   createdAt: DateTime.now().subtract(const Duration(days: 60)),
    //   owners: ['You', 'Alice', 'Eric'],
    //   isDefault: false,
    //   description: 'Joint savings for family expenses',
    //   targetAmount: 2000000,
    //   targetDate: DateTime.now().add(const Duration(days: 180)),
    // ),
    Wallet(
      id: 'WALLET-3',
      name: 'Vacation Fund',
      balance: 350000,
      currency: 'RWF',
      type: 'individual',
      status: 'inactive',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      owners: ['You'],
      isDefault: false,
      description: 'Vacation savings',
      targetAmount: 500000,
      targetDate: DateTime.now().add(const Duration(days: 90)),
    ),
  ];



  // Temporarily hidden - Mock recent milk transactions
  // List<Transaction> get mockTransactions => [
  //   Transaction(
  //     id: 'MLK-1001',
  //     amount: 157500,
  //     currency: 'RWF',
  //     type: 'collection',
  //     status: 'success',
  //     date: DateTime.now().subtract(const Duration(hours: 2)),
  //     description: 'Milk Collection - Jean Pierre',
  //     paymentMethod: 'Mobile Money',
  //     customerName: 'Jean Pierre Ndayisaba',
  //     customerPhone: '0788123456',
  //     reference: 'COL-20240601-001',
  //   ),
  //   Transaction(
  //     id: 'MLK-1002',
  //     amount: 133000,
  //     currency: 'RWF',
  //     type: 'sale',
  //     status: 'success',
  //     date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
  //     description: 'Milk Sale - Hotel Rwanda',
  //     paymentMethod: 'Bank',
  //     customerName: 'Hotel Rwanda Restaurant',
  //     customerPhone: '0722123456',
  //     reference: 'SALE-20240601-002',
  //   ),
  //   Transaction(
  //     id: 'MLK-1003',
  //     amount: 84000,
  //     currency: 'RWF',
  //     type: 'collection',
  //     status: 'pending',
  //     date: DateTime.now().subtract(const Duration(days: 2)),
  //     description: 'Milk Collection - Marie Claire',
  //     paymentMethod: 'Mobile Money',
  //     customerName: 'Marie Claire Uwimana',
  //     customerPhone: '0733123456',
  //     reference: 'COL-20240530-001',
  //   ),
  // ];

  // Temporarily hidden - Mock chart data
  // Map<String, double> get paymentMethodBreakdown => {
  //   'Mobile Money': 60,
  //   'Card': 25,
  //   'Bank': 10,
  //   'QR/USSD': 5,
  // };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Gemura',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        actions: [
          _AnimatedReferralIcon(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final userInfo = ref.watch(userAccountsProvider);
              final accountId = userInfo.value?.data.user.defaultAccountId;
              
              return userInfo.when(
                data: (user) {
                  final unreadCountAsync = ref.watch(unreadCountProvider(accountId));
                  
                  return unreadCountAsync.when(
                    data: (unreadCount) {
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                              );
                            },
                          ),
                                                     if (unreadCount > 0)
                             Positioned(
                               right: 8,
                               top: 8,
                               child: GestureDetector(
                                 onTap: () {
                                   Navigator.of(context).push(
                                     MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                                   );
                                 },
                                 child: Container(
                                   padding: const EdgeInsets.all(2),
                                   decoration: BoxDecoration(
                                     color: Colors.red,
                                     borderRadius: BorderRadius.circular(10),
                                   ),
                                   constraints: const BoxConstraints(
                                     minWidth: 16,
                                     minHeight: 16,
                                   ),
                                   child: Text(
                                     unreadCount > 99 ? '99+' : unreadCount.toString(),
                                     style: const TextStyle(
                                       color: Colors.white,
                                       fontSize: 10,
                                     ),
                                     textAlign: TextAlign.center,
                                   ),
                                 ),
                               ),
                             ),
                        ],
                      );
                    },
                    loading: () => IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                    ),
                    error: (_, __) => IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                    ),
                  );
                },
                loading: () => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
                error: (_, __) => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(overviewProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dynamic Ikofi Cards
            Consumer(
              builder: (context, ref, child) {
                final walletsAsync = ref.watch(walletsNotifierProvider);
                
                return walletsAsync.when(
                  loading: () => SkeletonLoaders.homeTabSkeleton(),
                  error: (error, stack) => SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: AppTheme.textHintColor),
                          const SizedBox(height: AppTheme.spacing8),
                          Consumer(
                            builder: (context, ref, child) {
                              final localizationService = ref.watch(localizationServiceProvider);
                              return Text(
                                localizationService.translate('failedToLoadWallets'),
                                style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (apiWallets) {
                    // Use API wallets, fallback to mock if empty
                    final wallets = apiWallets.isNotEmpty ? apiWallets : homeWallets;
                    
                    if (wallets.isEmpty) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, color: AppTheme.textHintColor),
                              const SizedBox(height: AppTheme.spacing8),
                              Consumer(
                                builder: (context, ref, child) {
                                  final localizationService = ref.watch(localizationServiceProvider);
                                  return Text(
                                    localizationService.translate('noWalletsAvailable'),
                                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return SizedBox(
                      height: 180, // Increased height to match wallet card natural height
                      child: PageView.builder(
                        itemCount: wallets.length,
                        controller: PageController(viewportFraction: 0.92),
                        itemBuilder: (context, index) {
                          final isFirst = index == 0;
                          final isLast = index == wallets.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(
                              left: isFirst ? 0 : AppTheme.spacing8,
                              right: isLast ? 0 : AppTheme.spacing8,
                            ),
                            child: WalletCard(
                              wallet: wallets[index], 
                              showBalance: _walletBalanceVisibility[wallets[index].id] ?? true,
                              onShowBalanceChanged: (showBalance) => _onBalanceVisibilityChanged(wallets[index].id, showBalance),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TransactionsScreen(wallet: wallets[index]),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing16),
            // Modules Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final localizationService = ref.watch(localizationServiceProvider);
                      return Text(
                        localizationService.translate('modules') ?? 'Modules',
                        style: AppTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _ModulesGrid(),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            // Milk Business Metrics
            // Overview metrics section
            Consumer(
              builder: (context, ref, child) {
                final overviewAsync = ref.watch(overviewProvider);
                
                return overviewAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: AppTheme.spacing8),
                              Text(
                                'Overview',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing12),
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: AppTheme.spacing8),
                              Text(
                                'Overview',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing12),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.error_outline, color: AppTheme.errorColor, size: 32),
                                const SizedBox(height: AppTheme.spacing8),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final localizationService = ref.watch(localizationServiceProvider);
                                    return Text(
                                      localizationService.translate('failedToLoadOverview'),
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (overview) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: AppTheme.spacing8),
                              Consumer(
                                builder: (context, ref, child) {
                                  final localizationService = ref.watch(localizationServiceProvider);
                                  return Text(
                                    localizationService.translate('overview'),
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textPrimaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing12),
                          Row(
                            children: [
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final localizationService = ref.watch(localizationServiceProvider);
                                    return _buildMetricCard(
                                      localizationService.translate('collections'),
                                      '${NumberFormat('#,##0.0').format(overview.summary.collection.liters)} L',
                                      '${NumberFormat('#,###').format(overview.summary.collection.value)} Frw • ${overview.summary.collection.transactions} txns',
                                      Icons.local_shipping,
                                      AppTheme.primaryColor,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const CollectedMilkScreen(),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final localizationService = ref.watch(localizationServiceProvider);
                                    return _buildMetricCard(
                                      localizationService.translate('sales'),
                                      '${NumberFormat('#,##0.0').format(overview.summary.sales.liters)} L',
                                      '${NumberFormat('#,###').format(overview.summary.sales.value)} Frw • ${overview.summary.sales.transactions} txns',
                                      Icons.point_of_sale,
                                      Colors.green,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const SoldMilkScreen(),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing12),
                          Row(
                            children: [
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final localizationService = ref.watch(localizationServiceProvider);
                                    return _buildCombinedMetricCard(
                                      localizationService.translate('suppliers'),
                                      overview.summary.suppliers.active,
                                      overview.summary.suppliers.inactive,
                                      Icons.person_add,
                                      Colors.orange,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const SuppliersListScreen(),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacing8),
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final localizationService = ref.watch(localizationServiceProvider);
                                    return _buildCombinedMetricCard(
                                      localizationService.translate('customers'),
                                      overview.summary.customers.active,
                                      overview.summary.customers.inactive,
                                      Icons.business,
                                      Colors.purple,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const CustomersListScreen(),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing8),
            // Chart section with overview data
            Consumer(
              builder: (context, ref, child) {
                final overviewAsync = ref.watch(overviewProvider);
                
                return overviewAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                      ),
                      child: Container(
                        height: 162,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                      ),
                      child: Container(
                        height: 162,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: AppTheme.errorColor, size: 32),
                              const SizedBox(height: AppTheme.spacing8),
                              Consumer(
                                builder: (context, ref, child) {
                                  final localizationService = ref.watch(localizationServiceProvider);
                                  return Text(
                                    localizationService.translate('failedToLoadChartData'),
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  data: (overview) => Column(
                    children: [
                      // Chart title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Consumer(
                            builder: (context, ref, child) {
                              final localizationService = ref.watch(localizationServiceProvider);
                              return Text(
                                '${localizationService.translate('milkCollectionSales')} (${_formatChartPeriod(overview.chartPeriod ?? overview.breakdownType)})',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      // Area chart section with legends
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                            border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 162,
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: DChartComboO(
                                   groupList: [
                                     OrdinalGroup(
                                       id: 'Collection',
                                       data: overview.breakdown.map((item) => 
                                         OrdinalData(domain: item.label, measure: item.collection.liters)
                                       ).toList(),
                                       color: AppTheme.primaryColor.withOpacity(0.85),
                                       chartType: ChartType.bar,
                                     ),
                                     OrdinalGroup(
                                       id: 'Sales',
                                       data: overview.breakdown.map((item) => 
                                         OrdinalData(domain: item.label, measure: item.sales.liters)
                                       ).toList(),
                                       color: Colors.grey.withOpacity(0.85),
                                       chartType: ChartType.bar,
                                     ),
                                   ],
                                   animate: true,
                                   domainAxis: DomainAxis(
                                     showLine: true,
                                     labelStyle: const LabelStyle(
                                       color: AppTheme.textSecondaryColor,
                                       fontSize: 12,
                                       fontWeight: FontWeight.w600,
                                     ),
                                   ),
                                   measureAxis: MeasureAxis(
                                     showLine: true,
                                     labelStyle: const LabelStyle(
                                       color: AppTheme.textSecondaryColor,
                                       fontSize: 12,
                                       fontWeight: FontWeight.w600,
                                     ),
                                   ),
                                 ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing12),
                              // Chart Legend
                              Consumer(
                                builder: (context, ref, child) {
                                  final localizationService = ref.watch(localizationServiceProvider);
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildLegendItem(
                                        localizationService.translate('collections'),
                                        AppTheme.primaryColor.withOpacity(0.85),
                                        Icons.local_shipping,
                                      ),
                                      const SizedBox(width: AppTheme.spacing16),
                                      _buildLegendItem(
                                        localizationService.translate('sales'),
                                        Colors.grey.withOpacity(0.85),
                                        Icons.point_of_sale,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing8),
            // Recent transactions from API
            Consumer(
              builder: (context, ref, child) {
                final overviewAsync = ref.watch(overviewProvider);
                
                return overviewAsync.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 32),
                            const SizedBox(height: AppTheme.spacing8),
                            Consumer(
                              builder: (context, ref, child) {
                                final localizationService = ref.watch(localizationServiceProvider);
                                return Text(
                                  localizationService.translate('failedToLoadRecentTransactions'),
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  data: (overview) {
                    final recentTransactions = overview.recentTransactions ?? [];
                    
                    if (recentTransactions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                            border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, color: AppTheme.textHintColor, size: 32),
                                const SizedBox(height: AppTheme.spacing8),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final localizationService = ref.watch(localizationServiceProvider);
                                    return Text(
                                      localizationService.translate('noRecentTransactions'),
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                          child: Consumer(
                            builder: (context, ref, child) {
                              final localizationService = ref.watch(localizationServiceProvider);
                              return Text(
                                localizationService.translate('recentTransactions'),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        ...recentTransactions.take(5).map((tx) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
                          child: _buildOverviewTransactionItem(tx),
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  Color _getChartColor(String method) {
    switch (method) {
      case 'Mobile Money':
        return const Color(0xFF43A047); // green
      case 'Card':
        return const Color(0xFF1976D2); // blue
      case 'Bank':
        return const Color(0xFFFBC02D); // yellow
      case 'QR/USSD':
        return const Color(0xFF8E24AA); // purple
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              value,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTransactionItem(OverviewTransaction transaction) {
    final isCollection = transaction.type.toLowerCase() == 'collection';
    final statusColor = _getStatusColor(transaction.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(
          color: AppTheme.thinBorderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing4,
        ),
        onTap: () => _showTransactionDetails(context, transaction),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            isCollection ? Icons.arrow_downward : Icons.arrow_upward,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          isCollection
            ? (transaction.supplierAccount?.name ?? 'Unknown Supplier')
            : (transaction.customerAccount?.name ?? 'Unknown Customer'),
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          _formatTransactionDate(transaction.transactionAt),
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textHintColor,
            fontSize: 11,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${NumberFormat('#,##0.0').format(transaction.quantity)} L',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${NumberFormat('#,###').format(transaction.totalAmount)} Frw',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                _capitalize(transaction.status).toUpperCase(),
                style: AppTheme.bodySmall.copyWith(
                  color: statusColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatTransactionDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM dd').format(date);
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _formatChartPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'last_7_days':
        return 'Iminsi 7';
      case 'last_30_days':
        return '30 Days';
      case 'last_90_days':
        return '90 Days';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return _capitalize(period);
    }
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCombinedMetricCard(String title, int activeCount, int inactiveCount, IconData icon, Color color, {VoidCallback? onTap}) {
    return Consumer(
      builder: (context, ref, child) {
        final localizationService = ref.watch(localizationServiceProvider);
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: AppTheme.spacing4),
                    Text(
                      title,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$activeCount',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            localizationService.translate('active'),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$inactiveCount',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            localizationService.translate('inactive'),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDetails(BuildContext context, OverviewTransaction transaction) {
    final isCollection = transaction.type.toLowerCase() == 'collection';
    final statusColor = _getStatusColor(transaction.status);
    final statusIcon = _getStatusIcon(transaction.status);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          isCollection ? Icons.arrow_downward : Icons.arrow_upward,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _capitalize(transaction.type),
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Consumer(
                              builder: (context, ref, child) {
                                final localizationService = ref.watch(localizationServiceProvider);
                                return Text(
                                  isCollection
                                    ? (transaction.supplierAccount?.name ?? localizationService.translate('unknownSupplier'))
                                    : (transaction.customerAccount?.name ?? localizationService.translate('unknownCustomer')),
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _capitalize(transaction.status),
                              style: AppTheme.bodySmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Transaction details
                  Consumer(
                    builder: (context, ref, child) {
                      final localizationService = ref.watch(localizationServiceProvider);
                      return Column(
                        children: [
                          _buildDetailRow(localizationService.translate('quantity'), '${NumberFormat('#,##0.0').format(transaction.quantity)} L'),
                          _buildDetailRow(localizationService.translate('amount'), '${NumberFormat('#,###').format(transaction.totalAmount)} Frw'),
                          _buildDetailRow(localizationService.translate('date'), _formatTransactionDate(transaction.transactionAt)),
                          _buildDetailRow(localizationService.translate('time'), _formatTransactionTime(DateTime.parse(transaction.transactionAt))),
                        ],
                      );
                    },
                  ),

                ],
              ),
            ),
            const SizedBox(height: AppTheme.actionSheetBottomSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTransactionTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Modules Grid Widget
class _ModulesGrid extends StatelessWidget {
  const _ModulesGrid();

  @override
  Widget build(BuildContext context) {
    final modules = ModulesService.getModules(context);
    
    // Get primary modules (first 6) for home screen
    final primaryModules = modules.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppTheme.spacing8,
        mainAxisSpacing: AppTheme.spacing8,
        childAspectRatio: 1.0,
      ),
      itemCount: primaryModules.length,
      itemBuilder: (context, index) {
        final module = primaryModules[index];
        return ModuleCard(
          module: module,
          onTap: () {
            // If module has a direct route, use it
            if (module.route != null) {
              // Handle direct route navigation if needed
              module.actions.first.onTap();
            } else {
              // Navigate to module detail screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ModuleDetailScreen(module: module),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('This is a placeholder for $title.')),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final localizationService = ref.watch(localizationServiceProvider);
        return Center(child: Text(localizationService.translate('transactions')));
      },
    );
  }
}
class _WalletsTab extends StatelessWidget {
  const _WalletsTab();
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final localizationService = ref.watch(localizationServiceProvider);
        return Center(child: Text(localizationService.translate('wallets')));
      },
    );
  }
}
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  @override
  void initState() {
    super.initState();
    // Initialize user accounts data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userAccountsNotifierProvider.notifier).fetchUserAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return authState.when(
      data: (user) {
        // Add null check and logging
        print('🔧 ProfileTab: Received user data: ${user?.name}');
        print('🔧 ProfileTab: User is null: ${user == null}');
        
        if (user == null) {
          print('🔧 ProfileTab: User is null, showing loading state');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Validate user data
        if (user.name.isEmpty) {
          print('🔧 ProfileTab: User name is empty, showing error state');
          return Scaffold(
            appBar: AppBar(
              title: Consumer(
                builder: (context, ref, child) {
                  final localizationService = ref.watch(localizationServiceProvider);
                  return Text(localizationService.translate('profile'));
                },
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Profile data is incomplete'),
                  const SizedBox(height: 8),
                  const Text('Please try refreshing or contact support'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Refresh the profile data
                      ref.read(authProvider.notifier).refreshProfile();
                    },
                    child: const Text('Refresh Profile'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Consumer(
              builder: (context, ref, child) {
                final localizationService = ref.watch(localizationServiceProvider);
                return Text(localizationService.translate('profile'));
              },
            ),
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
            titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Enhanced Profile Header Section
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.surfaceColor,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Avatar with Status
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            backgroundImage: (user.profileImg != null && user.profileImg!.isNotEmpty
                              ? NetworkImage(user.profileImg!)
                              : (user.profilePicture != null && user.profilePicture!.isNotEmpty
                                ? NetworkImage(user.profilePicture!)
                                : null)) as ImageProvider<Object>?,
                            child: ((user.profileImg == null || user.profileImg!.isEmpty) && (user.profilePicture == null || user.profilePicture!.isEmpty))
                                ? Text(
                                    (user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U'),
                                    style: AppTheme.headlineLarge.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  )
                                : null,
                          ),
                          // Status indicator
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                                                          decoration: BoxDecoration(
                              color: user.isActive ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.surfaceColor, width: 2),
                              ),
                              child: Icon(
                                user.isActive ? Icons.check : Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // User Name
                      Consumer(
                        builder: (context, ref, child) {
                          final localizationService = ref.watch(localizationServiceProvider);
                          return Text(
                            user.name.isNotEmpty ? user.name : localizationService.translate('userName'),
                            style: AppTheme.headlineLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Account Switcher
                      Consumer(
                        builder: (context, ref, child) {
                          final userAccountsState = ref.watch(userAccountsNotifierProvider);
                          
                          return userAccountsState.when(
                            data: (userAccounts) {
                              if (userAccounts == null || userAccounts.data.accounts.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              
                              final currentAccount = userAccounts.data.accounts.firstWhere(
                                (account) => account.isDefault,
                                orElse: () => userAccounts.data.accounts.first,
                              );
                              
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance,
                                          size: 16,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Consumer(
                                          builder: (context, ref, child) {
                                            final localizationService = ref.watch(localizationServiceProvider);
                                            return Text(
                                              localizationService.translate('currentAccount'),
                                              style: AppTheme.bodySmall.copyWith(
                                                color: AppTheme.textSecondaryColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                currentAccount.accountName,
                                                style: AppTheme.bodyMedium.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimaryColor,
                                                ),
                                              ),
                                              Text(
                                                'Role: ${currentAccount.role}',
                                                style: AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.textSecondaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              AccountTypeBadge(
                                                accountType: user.accountType,
                                                compact: true,
                                                showIcon: false,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (userAccounts.data.accounts.length > 1)
                                          Consumer(
                                            builder: (context, ref, child) {
                                              final localizationService = ref.watch(localizationServiceProvider);
                                              final isSwitching = ref.watch(userAccountsNotifierProvider.notifier).isSwitching;
                                              
                                              return Container(
                                                margin: const EdgeInsets.only(top: 8),
                                                child: TextButton.icon(
                                                  onPressed: isSwitching ? null : () => _showAccountSwitcher(context, ref, userAccounts.data.accounts),
                                                  icon: isSwitching 
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.swap_horiz,
                                                        color: AppTheme.primaryColor,
                                                        size: 18,
                                                      ),
                                                  label: Text(
                                                    isSwitching 
                                                      ? localizationService.translate('switching')
                                                      : localizationService.translate('switchAccount'),
                                                    style: AppTheme.bodySmall.copyWith(
                                                      color: AppTheme.primaryColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    backgroundColor: AppTheme.surfaceColor,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      side: BorderSide(
                                                        color: AppTheme.borderColor,
                                                        width: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                                                              child: Consumer(
                                  builder: (context, ref, child) {
                                    final localizationService = ref.watch(localizationServiceProvider);
                                    return Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(localizationService.translate('loadingAccounts')),
                                      ],
                                    );
                                  },
                                ),
                            ),
                            error: (error, stack) => Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.errorColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 16,
                                    color: AppTheme.errorColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final localizationService = ref.watch(localizationServiceProvider);
                                        return Text(
                                          localizationService.translate('failedToLoadAccounts'),
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.errorColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (user?.about != null && user?.about != '')
                        if (user?.about != null && user!.about!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              user!.about!,
                              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondaryColor),
                              textAlign: TextAlign.center,
                            ),
                          ),

                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Profile Completion Status Section
                if (user != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ProfileCompletionWidget(user: user),
                  ),
                const SizedBox(height: 16),
                // Contact Information Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final localizationService = ref.watch(localizationServiceProvider);
                            return Text(
                              localizationService.translate('contactInformation'),
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                      if (user?.email != null && user!.email!.isNotEmpty)
                        _buildInfoTile(Icons.email_outlined, 'Email', user.email!),
                      if (user?.phoneNumber != null && user?.phoneNumber != '')
                                                    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                              _buildInfoTile(Icons.phone, 'Phone', user!.phoneNumber!),
                                              if (user?.address != null && user!.address!.isNotEmpty)
                          _buildInfoTile(Icons.location_on_outlined, 'Address', user!.address!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Account Actions Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final localizationService = ref.watch(localizationServiceProvider);
                            return Text(
                              localizationService.translate('account'),
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final localizationService = ref.watch(localizationServiceProvider);
                          return _buildActionTile(
                            Icons.edit_outlined,
                            localizationService.translate('editProfile'),
                            '',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final localizationService = ref.watch(localizationServiceProvider);
                          return _buildActionTile(
                            Icons.lock_outline,
                            localizationService.translate('changePassword'),
                            '',
                            () {
                              // TODO: Implement change password
                            },
                          );
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final localizationService = ref.watch(localizationServiceProvider);
                          return _buildActionTile(
                            Icons.people,
                            localizationService.translate('manageEmployees'),
                            '',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ManageAccountAccessScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Support & Settings Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final localizationService = ref.watch(localizationServiceProvider);
                            return Text(
                              localizationService.translate('supportSettings'),
                              style: AppTheme.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final localizationService = ref.watch(localizationServiceProvider);
                          return _buildActionTile(
                            Icons.settings,
                            localizationService.translate('settings'),
                            '',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final localizationService = ref.watch(localizationServiceProvider);
                          return _buildActionTile(
                            Icons.store,
                            localizationService.translate('market'),
                            'Buy and sell dairy products',
                            () {
                              // Navigate to market tab
                              ref.read(tabIndexProvider.notifier).state = 1;
                            },
                          );
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final localizationService = ref.watch(localizationServiceProvider);
                          return _buildActionTile(
                            Icons.analytics,
                            localizationService.translate('myReport'),
                            '',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AgentReportScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final localizationService = ref.watch(localizationServiceProvider);
                          return _buildActionTile(
                            Icons.help_outline,
                            localizationService.translate('helpSupport'),
                            '',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const HelpSupportScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final localizationService = ref.watch(localizationServiceProvider);
                          return _buildActionTile(
                            Icons.info_outline,
                            localizationService.translate('about'),
                            '',
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AboutScreen(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Account Actions Section (Logout & Delete)
                _AccountActionsWidget(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textSecondaryColor,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive 
            ? AppTheme.errorColor.withOpacity(0.1)
            : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondaryColor,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showAccountSwitcher(BuildContext context, WidgetRef ref, List<UserAccount> accounts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final localizationService = ref.watch(localizationServiceProvider);
                    return Text(
                      localizationService.translate('switchAccount'),
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...accounts.map((account) => _buildAccountOption(context, ref, account)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOption(BuildContext context, WidgetRef ref, UserAccount account) {
    final isCurrentAccount = account.isDefault;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentAccount 
          ? AppTheme.primaryColor.withOpacity(0.08)
          : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentAccount 
            ? AppTheme.primaryColor.withOpacity(0.4)
            : AppTheme.borderColor,
          width: isCurrentAccount ? 2 : 1,
        ),
        boxShadow: isCurrentAccount ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentAccount 
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isCurrentAccount ? [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Icon(
            isCurrentAccount ? Icons.account_balance_wallet : Icons.account_balance,
            color: isCurrentAccount ? Colors.white : AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          account.accountName,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: isCurrentAccount ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                account.accountCode,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  account.role.toUpperCase(),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Consumer(
          builder: (context, ref, child) {
            final isSwitching = ref.watch(userAccountsNotifierProvider.notifier).isSwitching;
            
            if (isCurrentAccount) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ref.watch(localizationServiceProvider).translate('current'),
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSwitching ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSwitching ? AppTheme.primaryColor : AppTheme.borderColor,
                  width: 1.5,
                ),
                boxShadow: isSwitching ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSwitching) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isSwitching 
                      ? ref.watch(localizationServiceProvider).translate('switching')
                      : ref.watch(localizationServiceProvider).translate('switch'),
                    style: AppTheme.bodySmall.copyWith(
                      color: isSwitching ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isSwitching) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.swap_horiz,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        onTap: isCurrentAccount ? null : () async {
          // Check if already switching
          final isSwitching = ref.read(userAccountsNotifierProvider.notifier).isSwitching;
          if (isSwitching) return;
          
          Navigator.pop(context);
          
                      // Show loading snackbar
            if (context.mounted) {
              final localizationService = ref.read(localizationServiceProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(localizationService.translate('switchingToAccount').replaceAll('{account}', account.accountName)),
                    ],
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            }
          
          try {
            final success = await ref.read(userAccountsNotifierProvider.notifier).switchAccount(account.accountId, context);
            
            // Dismiss loading snackbar
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
            
            if (success && context.mounted) {
              // Account switch successful - all data has been refreshed
              // Success message is handled in the provider
              print('Account switch successful - all data refreshed');
            } else if (context.mounted) {
              final localizationService = ref.read(localizationServiceProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                AppTheme.errorSnackBar(
                  message: localizationService.translate('failedToSwitchAccount'),
                ),
              );
            }
          } catch (e) {
            // Dismiss loading snackbar
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
            
            print('Switch account error: $e');
            final localizationService = ref.read(localizationServiceProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              AppTheme.errorSnackBar(
                message: '❌ ${localizationService.translate('failedToSwitchAccount')}',
              ),
            );
          }
        },
      ),
    );
  }
}

class _AccountActionsWidget extends ConsumerWidget {
  const _AccountActionsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.thinBorderColor, width: AppTheme.thinBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer(
              builder: (context, ref, child) {
                final localizationService = ref.watch(localizationServiceProvider);
                return Text(
                  localizationService.translate('accountActions'),
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                );
              },
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final localizationService = ref.watch(localizationServiceProvider);
              return _buildActionTile(
                Icons.logout,
                localizationService.translate('signOut'),
                localizationService.translate('signOutAccount'),
                () async {
                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: Text(localizationService.translate('signOut')),
                      content: Text(localizationService.translate('signOutConfirm')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(localizationService.translate('cancel')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(localizationService.translate('signOut')),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldLogout == true) {
                    // Sign out and navigate to login screen
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final localizationService = ref.watch(localizationServiceProvider);
              return _buildActionTile(
                Icons.delete_forever,
                localizationService.translate('deleteAccount'),
                localizationService.translate('permanentlyDeleteAccount'),
                () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.surfaceColor,
                      title: Text(localizationService.translate('deleteAccount'), style: AppTheme.titleMedium.copyWith(color: AppTheme.errorColor)),
                      content: Text(localizationService.translate('deleteAccountConfirm'), style: AppTheme.bodyMedium),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(localizationService.translate('cancel'), style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryColor)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(localizationService.translate('delete'), style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref.read(authProvider.notifier).deleteAccount();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          AppTheme.errorSnackBar(message: 'Error: $e'),
                        );
                      }
                    }
                  }
                },
                isDestructive: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive 
            ? AppTheme.errorColor.withOpacity(0.1)
            : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textSecondaryColor,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondaryColor,
      ),
      onTap: onTap,
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();
  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _selectedMethod = 'Mobile Money';
  final List<String> _methods = ['Mobile Money', 'Card', 'Bank'];

  // Mock ikofi (same as homeWallets) - Joint ikofi temporarily hidden
  final List<Wallet> _wallets = [
    Wallet(
      id: 'WALLET-1',
      name: 'Main Ikofi',
      balance: 250000,
      currency: 'RWF',
      type: 'individual',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      owners: ['You'],
      isDefault: true,
    ),
    // Temporarily hidden - Joint Ikofi
    // Wallet(
    //   id: 'WALLET-2',
    //   name: 'Joint Ikofi',
    //   balance: 1200000,
    //   currency: 'RWF',
    //   type: 'joint',
    //   status: 'active',
    //   createdAt: DateTime.now().subtract(const Duration(days: 60)),
    //   owners: ['You', 'Alice', 'Eric'],
    //   isDefault: false,
    // ),
    Wallet(
      id: 'WALLET-3',
      name: 'Vacation Fund',
      balance: 350000,
      currency: 'RWF',
      type: 'individual',
      status: 'inactive',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      owners: ['You'],
      isDefault: false,
      description: 'Vacation savings',
      targetAmount: 500000,
      targetDate: DateTime.now().add(const Duration(days: 90)),
    ),
  ];
  Wallet? _selectedWallet;

  @override
  void initState() {
    super.initState();
    _selectedWallet = _wallets.firstWhere((w) => w.isDefault, orElse: () => _wallets.first);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: AppTheme.spacing16, right: AppTheme.spacing16, bottom: bottom + AppTheme.spacing16, top: AppTheme.spacing16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Top Up Ikofi', style: AppTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacing16),
            Text('To Ikofi', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.spacing8),
            DropdownButtonFormField<Wallet>(
              value: _selectedWallet,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              items: _wallets.map((w) => DropdownMenuItem(
                value: w,
                child: Text('${w.name} (${w.balance.toStringAsFixed(0)} ${w.currency})'),
              )).toList(),
              onChanged: (w) => setState(() => _selectedWallet = w),
              validator: (w) => w == null ? 'Select an ikofi' : null,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text('Amount', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.spacing8),
            TextFormField(
              controller: _amountController,
              style: AppTheme.bodySmall,
              decoration: const InputDecoration(
                hintText: 'Enter amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount required';
                final n = num.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text('Payment Method', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppTheme.spacing8),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(),
              ),
              items: _methods.map((m) => DropdownMenuItem(
                value: m,
                child: Text(m),
              )).toList(),
              onChanged: (m) => setState(() => _selectedMethod = m),
              validator: (m) => m == null ? 'Select a method' : null,
            ),
            const SizedBox(height: AppTheme.spacing16),
            PrimaryButton(
              label: 'Submit',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submit,
            ),
            const SizedBox(height: AppTheme.actionSheetBottomSpacing),
          ],
        ),
      ),
    );
  }
}

class _AnimatedReferralIcon extends StatefulWidget {
  @override
  _AnimatedReferralIconState createState() => _AnimatedReferralIconState();
}

class _AnimatedReferralIconState extends State<_AnimatedReferralIcon>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create animation controller with faster duration for more dynamic effect
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Create gentle rotation animation (subtle 15 degrees)
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.26, // ~15 degrees in radians
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Create gentle scale animation (subtle 1.1x scale)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Create gentle color animation (subtle color shift)
    _colorAnimation = ColorTween(
      begin: AppTheme.primaryColor,
      end: AppTheme.primaryColor.withOpacity(0.7),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation and repeat it
    _startAnimation();
  }

  void _startAnimation() {
    _controller.forward().then((_) {
        _controller.reverse().then((_) {
          // Wait 1 second before repeating for faster cycles
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _startAnimation();
            }
          });
        });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: IconButton(
              icon: Icon(
                Icons.card_giftcard,
                color: _colorAnimation.value,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReferralScreen(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
} 
