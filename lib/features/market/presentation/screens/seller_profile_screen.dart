import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/distance_utils.dart';
import '../../domain/models/product.dart';
import '../providers/products_provider.dart';
import 'product_details_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/domain/models/chat_room.dart';
import '../../../../shared/models/wallet.dart';

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
  String? _distanceFromUser;
  bool _isLoadingDistance = false;
  int _followerCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Simulate initial follower count
    _followerCount = widget.seller.totalSales ~/ 10; // Rough estimate
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    setState(() {
      _isLoadingDistance = true;
    });

    try {
      final currentLocation = await LocationService.instance.getCurrentLocation();
      if (currentLocation != null) {
        // For now, we'll use mock coordinates since the seller model doesn't have GPS coordinates
        // In a real app, you would get these from the seller's profile
        final mockSellerCoords = _getMockCoordinatesForLocation(widget.seller.location);
        
        if (mockSellerCoords != null) {
          final distance = DistanceUtils.calculateDistance(
            currentLocation.latitude,
            currentLocation.longitude,
            mockSellerCoords['lat']!,
            mockSellerCoords['lng']!,
          );
          
          setState(() {
            _distanceFromUser = DistanceUtils.formatDistance(distance);
          });
        }
      }
    } catch (e) {
      print('Error calculating distance: $e');
    } finally {
      setState(() {
        _isLoadingDistance = false;
      });
    }
  }

  Map<String, double>? _getMockCoordinatesForLocation(String location) {
    // Mock coordinates for different locations in Rwanda
    final locationCoordinates = {
      'Kigali, Rwanda': {'lat': -1.9403, 'lng': 30.0644},
      'Nyarugenge, Kigali': {'lat': -1.9441, 'lng': 30.0619},
      'Kacyiru, Kigali': {'lat': -1.9441, 'lng': 30.0619},
      'Kimisagara, Kigali': {'lat': -1.9441, 'lng': 30.0619},
      'Nyamirambo, Kigali': {'lat': -1.9441, 'lng': 30.0619},
      'Rwamagana, Eastern Province': {'lat': -1.9486, 'lng': 30.4347},
      'Musanze, Northern Province': {'lat': -1.4998, 'lng': 29.6344},
      'Huye, Southern Province': {'lat': -2.5967, 'lng': 29.7374},
      'Rubavu, Western Province': {'lat': -1.6931, 'lng': 29.2606},
      'Gicumbi, Northern Province': {'lat': -1.4998, 'lng': 29.6344},
    };
    
    return locationCoordinates[location];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openChatWithSeller() {
    // Create a simple chat room for the seller without wallet integration
    final chatRoom = ChatRoom(
      id: 'SELLER-${widget.seller.id}',
      name: widget.seller.name,
      description: 'Chat with ${widget.seller.name}',
      walletId: '', // No wallet integration
      wallet: Wallet(
        id: '',
        name: '',
        balance: 0,
        currency: 'RWF',
        type: 'personal',
        status: 'active',
        createdAt: DateTime.now(),
        owners: [],
        isDefault: false,
        description: '',
      ),
      members: [
        ChatMember(
          id: 'USER-CURRENT',
          name: 'You',
          email: 'user@example.com',
          role: 'member',
          joinedAt: DateTime.now(),
          isOnline: true,
        ),
        ChatMember(
          id: widget.seller.id.toString(),
          name: widget.seller.name,
          email: widget.seller.email ?? '${widget.seller.code}@seller.com',
          avatar: widget.seller.imageUrl,
          role: 'owner',
          joinedAt: DateTime.now(),
          isOnline: true,
        ),
      ],
      createdAt: DateTime.now(),
      isActive: true,
      groupAvatar: widget.seller.imageUrl,
    );

    // Navigate to the existing chat screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: chatRoom),
      ),
    );
  }

  void _makeCallToSeller() {
    if (widget.seller.phone != null && widget.seller.phone!.isNotEmpty) {
      // Show call options dialog
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.borderRadius16),
          ),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Call ${widget.seller.name}',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                widget.seller.phone!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                        'Cancel',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Here you would implement the actual call functionality
                        // For now, we'll just show a success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Calling ${widget.seller.name}...'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, size: 18),
                          const SizedBox(width: AppTheme.spacing4),
                          Text(
                            'Call',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Show error if no phone number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No phone number available for ${widget.seller.name}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
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
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                  child: Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: AppTheme.bodySmall.copyWith(
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
                    _openChatWithSeller();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.thinBorderColor,
                      width: AppTheme.thinBorderWidth,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                  child: Text(
                    'Message',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _makeCallToSeller();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.thinBorderColor,
                      width: AppTheme.thinBorderWidth,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: AppTheme.textPrimaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacing4),
                      Text(
                        'Call',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
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
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    // Create static products for this seller
    final sellerProducts = _getStaticProductsForSeller();
    
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
  }

  List<Product> _getStaticProductsForSeller() {
    // Create static products based on the seller
    final sellerId = widget.seller.id;
    final sellerName = widget.seller.name;
    final now = DateTime.now();
    
    // Different products for different sellers
    switch (sellerId) {
      case 1: // Kigali Dairy Farm
        return [
          Product(
            id: 1001,
            code: 'KDF-MILK-001',
            name: 'Fresh Cow Milk',
            description: 'Fresh, pure cow milk delivered daily from our farm',
            price: 1200.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 50,
            createdAt: now.subtract(const Duration(days: 5)),
            updatedAt: now.subtract(const Duration(days: 1)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Milk'],
            categoryIds: [1, 2],
          ),
          Product(
            id: 1002,
            code: 'KDF-YOG-001',
            name: 'Natural Yogurt',
            description: 'Creamy natural yogurt made from fresh milk',
            price: 800.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 30,
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now.subtract(const Duration(days: 1)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Yogurt'],
            categoryIds: [1, 3],
          ),
          Product(
            id: 1003,
            code: 'KDF-CHZ-001',
            name: 'Farm Cheese',
            description: 'Traditional farm-made cheese, aged to perfection',
            price: 2500.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 15,
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now.subtract(const Duration(hours: 6)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Cheese'],
            categoryIds: [1, 4],
          ),
        ];
      case 2: // Butare Dairy Cooperative
        return [
          Product(
            id: 2001,
            code: 'BDC-MILK-001',
            name: 'Premium Milk',
            description: 'High-quality milk from cooperative farms',
            price: 1100.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 40,
            createdAt: now.subtract(const Duration(days: 4)),
            updatedAt: now.subtract(const Duration(days: 1)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Milk'],
            categoryIds: [1, 2],
          ),
          Product(
            id: 2002,
            code: 'BDC-YOG-001',
            name: 'Strawberry Yogurt',
            description: 'Delicious strawberry-flavored yogurt',
            price: 900.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 25,
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now.subtract(const Duration(hours: 12)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Yogurt'],
            categoryIds: [1, 3],
          ),
        ];
      case 3: // Gisenyi Fresh Dairy
        return [
          Product(
            id: 3001,
            code: 'GFD-MILK-001',
            name: 'Organic Milk',
            description: '100% organic milk from grass-fed cows',
            price: 1500.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 35,
            createdAt: now.subtract(const Duration(days: 6)),
            updatedAt: now.subtract(const Duration(days: 1)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Milk', 'Organic'],
            categoryIds: [1, 2, 5],
          ),
          Product(
            id: 3002,
            code: 'GFD-YOG-001',
            name: 'Vanilla Yogurt',
            description: 'Smooth vanilla yogurt with natural flavoring',
            price: 850.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 20,
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now.subtract(const Duration(hours: 8)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Yogurt'],
            categoryIds: [1, 3],
          ),
          Product(
            id: 3003,
            code: 'GFD-BTR-001',
            name: 'Butter',
            description: 'Fresh farm butter, perfect for cooking',
            price: 1800.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 12,
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now.subtract(const Duration(hours: 4)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Butter'],
            categoryIds: [1, 6],
          ),
        ];
      case 4: // Musanze Dairy Center
        return [
          Product(
            id: 4001,
            code: 'MDC-MILK-001',
            name: 'Whole Milk',
            description: 'Rich whole milk with natural cream',
            price: 1300.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 45,
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now.subtract(const Duration(hours: 6)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Milk'],
            categoryIds: [1, 2],
          ),
          Product(
            id: 4002,
            code: 'MDC-YOG-001',
            name: 'Mango Yogurt',
            description: 'Tropical mango yogurt, refreshing and sweet',
            price: 950.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 18,
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now.subtract(const Duration(hours: 2)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Yogurt'],
            categoryIds: [1, 3],
          ),
        ];
      case 5: // Nyagatare Farm Fresh
        return [
          Product(
            id: 5001,
            code: 'NFF-MILK-001',
            name: 'Fresh Milk',
            description: 'Daily fresh milk from our local farm',
            price: 1000.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 60,
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now.subtract(const Duration(hours: 3)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Milk'],
            categoryIds: [1, 2],
          ),
          Product(
            id: 5002,
            code: 'NFF-YOG-001',
            name: 'Plain Yogurt',
            description: 'Simple, natural yogurt without additives',
            price: 750.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 35,
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now.subtract(const Duration(hours: 1)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Yogurt'],
            categoryIds: [1, 3],
          ),
          Product(
            id: 5003,
            code: 'NFF-CRM-001',
            name: 'Cream',
            description: 'Rich dairy cream for desserts and cooking',
            price: 1600.0,
            currency: 'RWF',
            imageUrl: null,
            isAvailable: true,
            stockQuantity: 8,
            createdAt: now.subtract(const Duration(days: 4)),
            updatedAt: now.subtract(const Duration(hours: 5)),
            sellerId: sellerId,
            seller: Seller(
              id: sellerId,
              code: widget.seller.code,
              name: sellerName,
              phone: widget.seller.phone,
              email: widget.seller.email,
            ),
            categories: ['Dairy', 'Cream'],
            categoryIds: [1, 7],
          ),
        ];
      default:
        return [];
    }
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
              _buildLocationRow(),
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

  Widget _buildLocationRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              'Location',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.seller.location,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isLoadingDistance)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                else if (_distanceFromUser != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_distanceFromUser away',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
