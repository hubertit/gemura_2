import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';

class FeedService {
  static final Dio _dio = AppConfig.dioInstance();

  /// Get authentication token
  static Future<String?> _getToken() async {
    return SecureStorageService.getAuthToken();
  }

  /// Get all feed posts
  static Future<Map<String, dynamic>> getPosts({
    int? postId,
    int? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/get.php',
        data: {
          'token': token,
          if (postId != null) 'post_id': postId,
          if (userId != null) 'user_id': userId,
          'limit': limit,
          'offset': offset,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error getting posts: ${e.message}');
      }
      rethrow;
    }
  }

  /// Get comments for a post
  static Future<Map<String, dynamic>> getComments({
    required int postId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/comments/get.php',
        data: {
          'token': token,
          'post_id': postId,
          'limit': limit,
          'offset': offset,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error getting comments: ${e.message}');
      }
      rethrow;
    }
  }

  /// Get user's bookmarked posts
  static Future<Map<String, dynamic>> getBookmarks({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/bookmarks.php',
        data: {
          'token': token,
          'limit': limit,
          'offset': offset,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error getting bookmarks: ${e.message}');
      }
      rethrow;
    }
  }

  /// Get user's liked posts
  static Future<Map<String, dynamic>> getLikedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/likes.php',
        data: {
          'token': token,
          'limit': limit,
          'offset': offset,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error getting liked posts: ${e.message}');
      }
      rethrow;
    }
  }

  /// Create a new post
  static Future<Map<String, dynamic>> createPost({
    required String content,
    String? mediaUrl,
    List<String>? hashtags,
    String? location,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/create.php',
        data: {
          'token': token,
          'content': content,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (hashtags != null) 'hashtags': hashtags,
          if (location != null) 'location': location,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error creating post: ${e.message}');
      }
      rethrow;
    }
  }

  /// Create a comment
  static Future<Map<String, dynamic>> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/comments/create.php',
        data: {
          'token': token,
          'post_id': postId,
          'content': content,
          if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error creating comment: ${e.message}');
      }
      rethrow;
    }
  }

  /// Like or unlike a post
  static Future<Map<String, dynamic>> toggleLike({
    required int postId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/like.php',
        data: {
          'token': token,
          'post_id': postId,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error toggling like: ${e.message}');
      }
      rethrow;
    }
  }

  /// Like or unlike a comment
  static Future<Map<String, dynamic>> toggleCommentLike({
    required int commentId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/comments/like.php',
        data: {
          'token': token,
          'comment_id': commentId,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error toggling comment like: ${e.message}');
      }
      rethrow;
    }
  }

  /// Bookmark or unbookmark a post
  static Future<Map<String, dynamic>> toggleBookmark({
    required int postId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/bookmark.php',
        data: {
          'token': token,
          'post_id': postId,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error toggling bookmark: ${e.message}');
      }
      rethrow;
    }
  }

  /// Update a post
  static Future<Map<String, dynamic>> updatePost({
    required int postId,
    String? content,
    String? mediaUrl,
    List<String>? hashtags,
    String? location,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/update.php',
        data: {
          'token': token,
          'post_id': postId,
          if (content != null) 'content': content,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (hashtags != null) 'hashtags': hashtags,
          if (location != null) 'location': location,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error updating post: ${e.message}');
      }
      rethrow;
    }
  }

  /// Update a comment
  static Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/comments/update.php',
        data: {
          'token': token,
          'comment_id': commentId,
          'content': content,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error updating comment: ${e.message}');
      }
      rethrow;
    }
  }

  /// Delete a post (soft delete)
  static Future<Map<String, dynamic>> deletePost({
    required int postId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/delete.php',
        data: {
          'token': token,
          'post_id': postId,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error deleting post: ${e.message}');
      }
      rethrow;
    }
  }

  /// Delete a comment (soft delete)
  static Future<Map<String, dynamic>> deleteComment({
    required int commentId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/comments/delete.php',
        data: {
          'token': token,
          'comment_id': commentId,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error deleting comment: ${e.message}');
      }
      rethrow;
    }
  }

  /// Follow or unfollow a user
  static Future<Map<String, dynamic>> toggleFollow({
    required int userId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '/feed/follow.php',
        data: {
          'token': token,
          'user_id': userId,
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error toggling follow: ${e.message}');
      }
      rethrow;
    }
  }
}
