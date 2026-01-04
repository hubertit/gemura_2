import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/feed_service.dart';
import '../../domain/models/post.dart';
import '../../../market/presentation/screens/user_profile_screen.dart';
import '../providers/feed_provider.dart';
import 'comments_screen.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';

class LikedPostsScreen extends ConsumerStatefulWidget {
  const LikedPostsScreen({super.key});

  @override
  ConsumerState<LikedPostsScreen> createState() => _LikedPostsScreenState();
}

class _LikedPostsScreenState extends ConsumerState<LikedPostsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Post> _likedPosts = [];
  bool _isLoading = false;
  String? _error;
  int _offset = 0;
  final int _limit = 10;
  bool _hasMoreLikedPosts = true;

  @override
  void initState() {
    super.initState();
    _loadLikedPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreLikedPosts) {
      _loadMoreLikedPosts();
    }
  }

  Future<void> _loadLikedPosts({bool isRefresh = false}) async {
    if (isRefresh) {
      _offset = 0;
      _hasMoreLikedPosts = true;
    }
    if (!_hasMoreLikedPosts && !isRefresh) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) _error = null;
    });

    try {
      final response = await FeedService.getLikedPosts(
        limit: _limit,
        offset: _offset,
      );

      if (response['code'] == 200) {
        final postsData = response['data'] as List<dynamic>;
        final newLikedPosts =
            postsData.map((postData) => _mapApiPostToModel(postData)).toList();

        setState(() {
          if (isRefresh) {
            _likedPosts = newLikedPosts;
          } else {
            _likedPosts.addAll(newLikedPosts);
          }
          _offset += newLikedPosts.length;
          _hasMoreLikedPosts = newLikedPosts.length == _limit;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load liked posts';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load liked posts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreLikedPosts() async {
    await _loadLikedPosts();
  }

  Future<void> _refreshLikedPosts() async {
    await _loadLikedPosts(isRefresh: true);
  }

  Future<void> _unlikePost(Post post) async {
    // Optimistic update - remove from UI immediately
    setState(() {
      _likedPosts.removeWhere((p) => p.id == post.id);
    });

    // Call API in background
    try {
      final response = await FeedService.toggleLike(postId: int.parse(post.id));

      if (response['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post removed from liked posts'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } else {
        // Revert optimistic update on API failure
        setState(() {
          _likedPosts.add(post);
        });
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _likedPosts.add(post);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlike post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bookmarkPost(Post post) async {
    // Optimistic update - change UI immediately
    final isCurrentlyBookmarked = post.isBookmarked;
    final currentBookmarksCount = post.bookmarksCount;
    
    setState(() {
      final index = _likedPosts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _likedPosts[index] = post.copyWith(
          isBookmarked: !isCurrentlyBookmarked,
          bookmarksCount: isCurrentlyBookmarked ? currentBookmarksCount - 1 : currentBookmarksCount + 1,
        );
      }
    });

    // Call API in background
    try {
      final response = await FeedService.toggleBookmark(postId: int.parse(post.id));

      if (response['code'] == 200) {
        // Update with actual server response
        setState(() {
          final index = _likedPosts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _likedPosts[index] = post.copyWith(
              isBookmarked: response['data']['is_bookmarked'] ?? !isCurrentlyBookmarked,
              bookmarksCount: response['data']['bookmarks_count'] ?? (isCurrentlyBookmarked ? currentBookmarksCount - 1 : currentBookmarksCount + 1),
            );
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['data']['is_bookmarked'] == true
                    ? 'Post bookmarked'
                    : 'Post removed from bookmarks',
              ),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } else {
        // Revert optimistic update on API failure
        setState(() {
          final index = _likedPosts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _likedPosts[index] = post.copyWith(
              isBookmarked: isCurrentlyBookmarked,
              bookmarksCount: currentBookmarksCount,
            );
          }
        });
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        final index = _likedPosts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _likedPosts[index] = post.copyWith(
            isBookmarked: isCurrentlyBookmarked,
            bookmarksCount: currentBookmarksCount,
          );
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to bookmark post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: Text(
          'Liked Posts',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLikedPosts,
        child: _isLoading && _likedPosts.isEmpty
            ? _buildLoadingState()
            : _error != null && _likedPosts.isEmpty
                ? _buildErrorState()
                : _likedPosts.isEmpty
                    ? _buildEmptyState()
                    : CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          // Posts Section
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < _likedPosts.length) {
                                  return _buildLikedPostCard(_likedPosts[index]);
                                }
                                return null;
                              },
                              childCount: _likedPosts.length,
                            ),
                          ),
                          
                          // Loading indicator for pagination
                          if (_isLoading && _likedPosts.isNotEmpty)
                            SliverToBoxAdapter(
                              child: SkeletonLoaders.feedPostsSkeleton(count: 3),
                            ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SkeletonLoaders.feedPostsSkeleton(count: 5);
  }

  Widget _buildErrorState() {
    return Center(
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
            'Failed to load liked posts',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            _error ?? 'Unknown error',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing16),
          ElevatedButton(
            onPressed: _loadLikedPosts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'No liked posts yet!',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Like posts from the feed to save them here.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLikedPostCard(Post post) {
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
            _buildPostMedia(post),
          
          // Post Actions (Like, Comment, Share)
          _buildPostActions(post),
          
          // Post Stats
          _buildPostStats(post),
          
          // Post Caption
          if (post.content != null && post.content!.isNotEmpty)
            _buildPostCaption(post),
          
          // Time Posted
          _buildTimePosted(post),
        ],
      ),
    );
  }

  Widget _buildPostHeader(Post post) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: [
          CircleAvatar(
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
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.userName,
                      style: AppTheme.titleSmall.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (post.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: AppTheme.spacing4),
                        child: Icon(
                          Icons.verified,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                Text(
                  _getTimeAgo(post.createdAt),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(Post post) {
    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
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
      ),
    );
  }

  Widget _buildPostStats(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Row(
        children: [
          Text(
            '${post.likesCount} Likes',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Text(
            '${post.commentsCount} Comments',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Text(
            '${post.sharesCount} Shares',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Text(
            '${post.bookmarksCount} Bookmarks',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPostActions(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _unlikePost(post),
            child: const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing24),
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
            onTap: () => _bookmarkPost(post),
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

  Widget _buildPostCaption(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Text(
        post.content!,
        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
    );
  }

  Widget _buildTimePosted(Post post) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        bottom: AppTheme.spacing12,
      ),
      child: Text(
        _getTimeAgo(post.createdAt),
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textSecondaryColor,
        ),
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

  Post _mapApiPostToModel(Map<String, dynamic> postData) {
    return Post(
      id: postData['id'].toString(),
      userId: postData['user_id'].toString(),
      userName: postData['user_name'] ?? 'Unknown User',
      userAvatar: postData['user_avatar'],
      content: postData['content'] ?? '',
      imageUrls: postData['media_url'] != null ? [postData['media_url']] : [],
      createdAt: DateTime.tryParse(postData['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(postData['updated_at'] ?? '') ?? DateTime.now(),
      likesCount: int.tryParse(postData['likes_count']?.toString() ?? '0') ?? 0,
      commentsCount: int.tryParse(postData['comments_count']?.toString() ?? '0') ?? 0,
      sharesCount: int.tryParse(postData['shares_count']?.toString() ?? '0') ?? 0,
      bookmarksCount: int.tryParse(postData['bookmarks_count']?.toString() ?? '0') ?? 0,
      isLiked: postData['is_liked'] == true,
      isBookmarked: postData['is_bookmarked'] == true,
      hashtags: List<String>.from(postData['hashtags'] ?? []),
      location: postData['location'],
      isVerified: postData['kyc_status'] == 'verified',
    );
  }
}
