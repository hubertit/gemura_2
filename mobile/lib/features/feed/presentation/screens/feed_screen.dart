import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/feed_provider.dart';
import '../../domain/models/post.dart';
import '../../../market/presentation/screens/user_profile_screen.dart';
import '../../../market/presentation/providers/products_provider.dart';
import 'comments_screen.dart';
import 'bookmarks_screen.dart';
import 'liked_posts_screen.dart';
import 'create_post_screen.dart';
import 'edit_post_screen.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/feed_service.dart';

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
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BookmarksScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LikedPostsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).refreshFeed(),
        child: Consumer(
          builder: (context, ref, child) {
            final feedState = ref.watch(feedProvider);
            
            // Loading state
            if (feedState.isLoading && feedState.posts.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SkeletonLoaders.feedPostsSkeleton(count: 5),
              );
            }
            
            // Error state
            if (feedState.error != null && feedState.posts.isEmpty) {
              return _buildErrorState(feedState.error!);
            }
            
            // Empty state
            if (!feedState.isLoading && feedState.posts.isEmpty) {
              return _buildEmptyState();
            }
            
            return CustomScrollView(
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
                  SliverToBoxAdapter(
                    child: SkeletonLoaders.feedPostsSkeleton(count: 3),
                  ),
              ],
            );
          },
        ),
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

  /// Get current user ID from auth provider
  String _getCurrentUserId() {
    final authState = ref.read(authProvider);
    return authState.when(
      data: (user) => user?.id ?? '',
      loading: () => '',
      error: (_, __) => '',
    );
  }

  /// Handle post menu actions
  void _handlePostMenuAction(String action, Post post) {
    switch (action) {
      case 'edit':
        _navigateToEditPost(post);
        break;
      case 'delete':
        _showDeleteConfirmation(post);
        break;
    }
  }

  /// Navigate to edit post screen
  void _navigateToEditPost(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditPostScreen(post: post),
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(Post post) async {
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Delete Post',
      message: 'Are you sure you want to delete this post? This action cannot be undone.',
    );
    
    if (confirmed) {
      _deletePost(post);
    }
  }

  /// Delete post
  Future<void> _deletePost(Post post) async {
    try {
      // Call API
      final response = await FeedService.deletePost(postId: int.parse(post.id));
      
      if (response['code'] == 200) {
        // Refresh feed to remove deleted post
        ref.read(feedProvider.notifier).refreshFeed();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response['message'] ?? 'Failed to delete post'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPostHeader(Post post) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToUserProfile(post),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: post.userAvatar != null
                  ? NetworkImage(post.userAvatar!)
                  : null,
              child: post.userAvatar == null
                  ? Text(
                      post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'U',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    )
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
          // 3 dots menu for post owner
          if (post.userId == _getCurrentUserId()) // Only show for post owner
            PopupMenuButton<String>(
              onSelected: (value) => _handlePostMenuAction(value, post),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Post'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Post', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: const Icon(
                Icons.more_vert,
                color: AppTheme.textSecondaryColor,
              ),
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CommentsScreen(post: post),
                ),
              );
            },
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppTheme.textPrimaryColor,
              size: 24,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => ref.read(feedProvider.notifier).bookmarkPost(post.id),
            child: Icon(
              post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: post.isBookmarked ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
              size: 24,
            ),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CommentsScreen(post: post),
                  ),
                );
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
      totalReviews: 0,
      rating: 4.5,
      isVerified: post.isVerified,
      location: '-1.9441,30.0619', // Kigali coordinates
      joinDate: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(user: seller),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Instagram-style time formatting
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1y' : '${years}y';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1mo' : '${months}mo';
    } else if (difference.inDays >= 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1w' : '${weeks}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Failed to load feed',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              error,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: () => ref.read(feedProvider.notifier).refreshFeed(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                  vertical: AppTheme.spacing12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.feed_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No posts yet',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Be the first to share something with the community!',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreatePostScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                  vertical: AppTheme.spacing12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
