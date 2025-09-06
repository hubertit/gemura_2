import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/feed_provider.dart';
import '../../domain/models/post.dart';
import '../../../market/presentation/screens/seller_profile_screen.dart';
import '../../../market/presentation/providers/products_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedProvider.notifier).loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          'Feed',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Navigate to activity/notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: () {
              // TODO: Navigate to messages
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).refreshFeed(),
        child: feedState.isLoading && feedState.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Posts Section
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < feedState.posts.length) {
                          return _buildPostCard(feedState.posts[index]);
                        }
                        return null;
                      },
                      childCount: feedState.posts.length,
                    ),
                  ),
                  
                  // Loading indicator for pagination
                  if (feedState.isLoading && feedState.posts.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacing16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create post screen
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildPostHeader(post),
          
          // Post Image(s)
          if (post.imageUrls.isNotEmpty)
            _buildPostImages(post),
          
          // Post Actions (Like, Comment, Share)
          _buildPostActions(post),
          
          // Post Stats
          _buildPostStats(post),
          
          // Post Caption
          if (post.content != null && post.content!.isNotEmpty)
            _buildPostCaption(post),
          
          // Comments Section
          if (post.commentsCount > 0)
            _buildCommentsSection(post),
          
          // Time Posted
          _buildTimePosted(post),
        ],
      ),
    );
  }

  Widget _buildPostHeader(Post post) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToUserProfile(post),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: post.userAvatar != null
                  ? NetworkImage(post.userAvatar!)
                  : null,
              child: post.userAvatar == null
                  ? const Icon(Icons.person, size: 16, color: AppTheme.textSecondaryColor)
                  : null,
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToUserProfile(post),
              child: Row(
                children: [
                  Text(
                    post.userName,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (post.isVerified) ...[
                    const SizedBox(width: AppTheme.spacing4),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show post options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostImages(Post post) {
    if (post.imageUrls.length == 1) {
      return AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          post.imageUrls.first,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppTheme.borderColor,
              child: const Icon(
                Icons.image_not_supported,
                color: AppTheme.textSecondaryColor,
                size: 48,
              ),
            );
          },
        ),
      );
    } else {
      return SizedBox(
        height: 300,
        child: PageView.builder(
          itemCount: post.imageUrls.length,
          itemBuilder: (context, index) {
            return Image.network(
              post.imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.borderColor,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: AppTheme.textSecondaryColor,
                    size: 48,
                  ),
                );
              },
            );
          },
        ),
      );
    }
  }

  Widget _buildPostActions(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(feedProvider.notifier).likePost(post.id),
            child: Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: post.isLiked ? Colors.red : AppTheme.textPrimaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          GestureDetector(
            onTap: () {
              // TODO: Navigate to comments
            },
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppTheme.textPrimaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          GestureDetector(
            onTap: () => ref.read(feedProvider.notifier).sharePost(post.id),
            child: const Icon(
              Icons.send_outlined,
              color: AppTheme.textPrimaryColor,
              size: 24,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.bookmark_border,
            color: AppTheme.textPrimaryColor,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPostStats(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.likesCount > 0)
            Text(
              '${post.likesCount} likes',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (post.commentsCount > 0) ...[
            const SizedBox(height: AppTheme.spacing4),
            GestureDetector(
              onTap: () {
                // TODO: Navigate to comments
              },
              child: Text(
                'View all ${post.commentsCount} comments',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostCaption(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${post.userName} ',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextSpan(
              text: post.content!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
      child: Text(
        'View all ${post.commentsCount} comments',
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildTimePosted(Post post) {
    final timeAgo = _getTimeAgo(post.createdAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing12,
        AppTheme.spacing4,
        AppTheme.spacing12,
        AppTheme.spacing12,
      ),
      child: Text(
        timeAgo,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textSecondaryColor,
        ),
      ),
    );
  }

  void _navigateToUserProfile(Post post) {
    // Create a mock seller from the post data
    final seller = TopSeller(
      id: int.tryParse(post.userId) ?? 1,
      code: post.userId,
      name: post.userName,
      email: '${post.userId}@example.com',
      phone: '+250700000000',
      imageUrl: post.userAvatar,
      totalProducts: 0,
      totalSales: 0,
      rating: 4.5,
      isVerified: post.isVerified,
      location: 'Kigali, Rwanda',
      joinDate: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SellerProfileScreen(seller: seller),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
