import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/feed_service.dart';
import '../../domain/models/post.dart';
import '../providers/feed_provider.dart';
import 'comments_screen.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Post> _bookmarks = [];
  bool _isLoading = false;
  bool _hasMoreBookmarks = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreBookmarks();
    }
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await FeedService.getBookmarks(limit: 20, offset: 0);
      
      if (response['code'] == 200) {
        final bookmarksData = response['data'] as List<dynamic>;
        final bookmarks = bookmarksData.map((postData) => _mapApiPostToModel(postData)).toList();
        
        setState(() {
          _bookmarks = bookmarks;
          _isLoading = false;
          _hasMoreBookmarks = bookmarks.length >= 20;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load bookmarks';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load bookmarks: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreBookmarks() async {
    if (!_hasMoreBookmarks || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await FeedService.getBookmarks(
        limit: 20,
        offset: _bookmarks.length,
      );
      
      if (response['code'] == 200) {
        final bookmarksData = response['data'] as List<dynamic>;
        final newBookmarks = bookmarksData.map((postData) => _mapApiPostToModel(postData)).toList();
        
        setState(() {
          _bookmarks = [..._bookmarks, ...newBookmarks];
          _isLoading = false;
          _hasMoreBookmarks = newBookmarks.length >= 20;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = response['message'] ?? 'Failed to load more bookmarks';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load more bookmarks: ${e.toString()}';
      });
    }
  }

  Future<void> _refreshBookmarks() async {
    await _loadBookmarks();
  }

  Future<void> _removeBookmark(Post post) async {
    try {
      final response = await FeedService.toggleBookmark(postId: int.parse(post.id));
      
      if (response['code'] == 200) {
        setState(() {
          _bookmarks.removeWhere((p) => p.id == post.id);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post removed from bookmarks'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove bookmark: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
    }
  }

  Future<void> _likePost(Post post) async {
    try {
      final response = await FeedService.toggleLike(postId: int.parse(post.id));
      
      if (response['code'] == 200) {
        setState(() {
          final index = _bookmarks.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _bookmarks[index] = post.copyWith(
              isLiked: response['data']['is_liked'] ?? !post.isLiked,
              likesCount: response['data']['likes_count'] ?? post.likesCount,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like post: ${e.toString()}'),
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
          'Saved Posts',
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
        onRefresh: _refreshBookmarks,
        child: _isLoading && _bookmarks.isEmpty
            ? _buildLoadingState()
            : _error != null && _bookmarks.isEmpty
                ? _buildErrorState()
                : _bookmarks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppTheme.spacing16),
                        itemCount: _bookmarks.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _bookmarks.length) {
                            return _buildLoadingIndicator();
                          }
                          return _buildBookmarkCard(_bookmarks[index]);
                        },
                      ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
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
            'Failed to load bookmarks',
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
            onPressed: _loadBookmarks,
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
            Icons.bookmark_border,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'No saved posts yet',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Posts you bookmark will appear here',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: AppTheme.thinBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          _buildPostHeader(post),
          
          // Post Content
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Text(
                post.content!,
                style: AppTheme.bodyMedium,
              ),
            ),
          
          // Post Media
          if (post.imageUrls.isNotEmpty)
            _buildPostMedia(post),
          
          // Post Stats
          _buildPostStats(post),
          
          // Post Actions
          _buildPostActions(post),
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
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (post.isVerified) ...[
                      const SizedBox(width: AppTheme.spacing4),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ],
                ),
                Text(
                  _getTimeAgo(post.createdAt),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') {
                _removeBookmark(post);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_remove, color: Colors.red),
                    SizedBox(width: AppTheme.spacing8),
                    Text('Remove from bookmarks'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(Post post) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        image: DecorationImage(
          image: NetworkImage(post.imageUrls.first),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPostStats(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: Row(
        children: [
          if (post.likesCount > 0) ...[
            Text(
              '${post.likesCount} likes',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
          ],
          if (post.commentsCount > 0) ...[
            Text(
              '${post.commentsCount} comments',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
          ],
          if (post.sharesCount > 0) ...[
            Text(
              '${post.sharesCount} shares',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
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
            onTap: () => _likePost(post),
            child: Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: post.isLiked ? Colors.red : AppTheme.textPrimaryColor,
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
          Icon(
            Icons.bookmark,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.spacing16),
      child: Center(
        child: CircularProgressIndicator(),
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

  /// Map API response data to Post model
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
