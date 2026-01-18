import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'authenticated_dio_service.dart';

class FeedService {
  static final Dio _dio = AuthenticatedDioService.instance;

  /// Get all feed posts
  static Future<Map<String, dynamic>> getPosts({
    int? postId,
    int? userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (postId != null) queryParams['postId'] = postId;
      if (userId != null) queryParams['userId'] = userId;

      final response = await _dio.get(
        '/feed/posts',
        queryParameters: queryParams,
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
      final response = await _dio.get(
        '/feed/comments',
        queryParameters: {
          'postId': postId,
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
      final response = await _dio.get(
        '/feed/posts',
        queryParameters: {
          'bookmarked': true,
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
      final response = await _dio.get(
        '/feed/interactions/my',
        queryParameters: {
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
      final response = await _dio.post(
        '/feed/posts',
        data: {
          'content': content,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
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
      final response = await _dio.post(
        '/feed/comments',
        data: {
          'postId': postId,
          'content': content,
          if (parentCommentId != null) 'parentCommentId': parentCommentId,
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
      final response = await _dio.post(
        '/feed/interactions',
        data: {
          'postId': postId,
          'type': 'like',
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
      // Note: Comment likes might be handled differently in NestJS
      // This may need adjustment based on actual API implementation
      final response = await _dio.post(
        '/feed/interactions',
        data: {
          'commentId': commentId,
          'type': 'like',
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
      // Update post with bookmark field
      final response = await _dio.patch(
        '/feed/posts/$postId',
        data: {
          'bookmarked': true, // Toggle logic handled by backend
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
      final response = await _dio.patch(
        '/feed/posts/$postId',
        data: {
          if (content != null) 'content': content,
          if (mediaUrl != null) 'mediaUrl': mediaUrl,
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
      final response = await _dio.patch(
        '/feed/comments/$commentId',
        data: {
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
      final response = await _dio.delete(
        '/feed/posts/$postId',
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
      final response = await _dio.delete(
        '/feed/comments/$commentId',
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
      final response = await _dio.post(
        '/feed/follow',
        data: {
          'userId': userId,
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
