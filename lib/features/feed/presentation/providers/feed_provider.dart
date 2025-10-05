import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/post.dart';
import '../../../../core/services/feed_service.dart';

class FeedState {
  final List<Post> posts;
  final bool isLoading;
  final String? error;
  final bool hasMorePosts;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.hasMorePosts = true,
  });

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
    bool? hasMorePosts,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await FeedService.getPosts(limit: 20, offset: 0);
      
      if (mounted) {
        if (response['code'] == 200) {
          final postsData = response['data'] as List<dynamic>;
          final posts = postsData.map((postData) => _mapApiPostToModel(postData)).toList();
          
          state = state.copyWith(
            isLoading: false,
            posts: posts,
            hasMorePosts: posts.length >= 20,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: response['message'] ?? 'Failed to load posts',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load posts: ${e.toString()}',
        );
      }
    }
  }

  Future<void> refreshFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await FeedService.getPosts(limit: 20, offset: 0);
      
      if (mounted) {
        if (response['code'] == 200) {
          final postsData = response['data'] as List<dynamic>;
          final posts = postsData.map((postData) => _mapApiPostToModel(postData)).toList();
          
          state = state.copyWith(
            isLoading: false,
            posts: posts,
            hasMorePosts: posts.length >= 20,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: response['message'] ?? 'Failed to refresh posts',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to refresh posts: ${e.toString()}',
        );
      }
    }
  }

  Future<void> loadMorePosts() async {
    if (!state.hasMorePosts || state.isLoading) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final response = await FeedService.getPosts(
        limit: 20, 
        offset: state.posts.length,
      );
      
      if (mounted) {
        if (response['code'] == 200) {
          final postsData = response['data'] as List<dynamic>;
          final newPosts = postsData.map((postData) => _mapApiPostToModel(postData)).toList();
          
          state = state.copyWith(
            isLoading: false,
            posts: [...state.posts, ...newPosts],
            hasMorePosts: newPosts.length >= 20,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: response['message'] ?? 'Failed to load more posts',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load more posts: ${e.toString()}',
        );
      }
    }
  }

  Future<void> likePost(String postId) async {
    // Optimistic update - change UI immediately
    final currentPost = state.posts.firstWhere((post) => post.id == postId);
    final isCurrentlyLiked = currentPost.isLiked;
    final currentLikesCount = currentPost.likesCount;
    
    // Update UI immediately
    final optimisticPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          isLiked: !isCurrentlyLiked,
          likesCount: isCurrentlyLiked ? currentLikesCount - 1 : currentLikesCount + 1,
        );
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: optimisticPosts);
    
    // Call API in background
    try {
      final response = await FeedService.toggleLike(postId: int.parse(postId));
      
      if (response['code'] == 200) {
        // Update with actual server response
        final updatedPosts = state.posts.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              isLiked: response['data']['is_liked'] ?? !isCurrentlyLiked,
              likesCount: response['data']['likes_count'] ?? (isCurrentlyLiked ? currentLikesCount - 1 : currentLikesCount + 1),
            );
          }
          return post;
        }).toList();
        
        state = state.copyWith(posts: updatedPosts);
      } else {
        // Revert optimistic update on API failure
        final revertedPosts = state.posts.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              isLiked: isCurrentlyLiked,
              likesCount: currentLikesCount,
            );
          }
          return post;
        }).toList();
        
        state = state.copyWith(posts: revertedPosts);
      }
    } catch (e) {
      // Revert optimistic update on error
      final revertedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            isLiked: isCurrentlyLiked,
            likesCount: currentLikesCount,
          );
        }
        return post;
      }).toList();
      
      state = state.copyWith(posts: revertedPosts);
    }
  }

  void sharePost(String postId) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(sharesCount: post.sharesCount + 1);
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: updatedPosts);
  }

  void addComment(String postId, String content) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(commentsCount: post.commentsCount + 1);
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: updatedPosts);
  }

  Future<void> bookmarkPost(String postId) async {
    // Optimistic update - change UI immediately
    final currentPost = state.posts.firstWhere((post) => post.id == postId);
    final isCurrentlyBookmarked = currentPost.isBookmarked;
    final currentBookmarksCount = currentPost.bookmarksCount;
    
    // Update UI immediately
    final optimisticPosts = state.posts.map((post) {
      if (post.id == postId) {
        return post.copyWith(
          isBookmarked: !isCurrentlyBookmarked,
          bookmarksCount: isCurrentlyBookmarked ? currentBookmarksCount - 1 : currentBookmarksCount + 1,
        );
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: optimisticPosts);
    
    // Call API in background
    try {
      final response = await FeedService.toggleBookmark(postId: int.parse(postId));
      
      if (response['code'] == 200) {
        // Update with actual server response
        final updatedPosts = state.posts.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              isBookmarked: response['data']['is_bookmarked'] ?? !isCurrentlyBookmarked,
              bookmarksCount: response['data']['bookmarks_count'] ?? (isCurrentlyBookmarked ? currentBookmarksCount - 1 : currentBookmarksCount + 1),
            );
          }
          return post;
        }).toList();
        
        state = state.copyWith(posts: updatedPosts);
      } else {
        // Revert optimistic update on API failure
        final revertedPosts = state.posts.map((post) {
          if (post.id == postId) {
            return post.copyWith(
              isBookmarked: isCurrentlyBookmarked,
              bookmarksCount: currentBookmarksCount,
            );
          }
          return post;
        }).toList();
        
        state = state.copyWith(posts: revertedPosts);
      }
    } catch (e) {
      // Revert optimistic update on error
      final revertedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            isBookmarked: isCurrentlyBookmarked,
            bookmarksCount: currentBookmarksCount,
          );
        }
        return post;
      }).toList();
      
      state = state.copyWith(posts: revertedPosts);
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

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});
