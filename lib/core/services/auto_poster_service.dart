import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';
import 'news_scraper_service.dart';

class AutoPosterService {
  static final Dio _dio = AppConfig.dioInstance();

  /// Get authentication token for system account
  static Future<String?> _getSystemToken() async {
    try {
      // Login with system account credentials
      final response = await _dio.post(
        '/auth/login.php',
        data: {
          'identifier': '250788000000',
          'password': 'Pass123',
        },
      );

      if (response.data['code'] == 200) {
        final token = response.data['data']['user']['token'];
        // Store token for future use
        await SecureStorageService.storeAuthToken(token);
        return token;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting system token: $e');
      }
      return null;
    }
  }

  /// Post an article to the feed
  static Future<bool> postArticle(NewsArticle article) async {
    try {
      final token = await _getSystemToken();
      if (token == null) {
        if (kDebugMode) {
          print('Failed to get system token');
        }
        return false;
      }

      // Create hashtags based on content
      final hashtags = _generateHashtags(article.title, article.content);
      
      // Create post content
      final postContent = _createPostContent(article);

      final response = await _dio.post(
        '/feed/create.php',
        data: {
          'token': token,
          'content': postContent,
          'media_url': article.imageUrl.isNotEmpty ? article.imageUrl : null,
          'hashtags': hashtags,
          'location': 'Kigali Today',
        },
      );

      if (response.data['code'] == 201) {
        if (kDebugMode) {
          print('Successfully posted: ${article.title}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to post article: ${response.data['message']}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error posting article: $e');
      }
      return false;
    }
  }

  /// Create post content from article
  static String _createPostContent(NewsArticle article) {
    final summary = NewsScraperService.createSummary(article.content);
    return '📰 ${article.title}\n\n$summary\n\n🔗 Read more: ${article.originalUrl}';
  }

  /// Generate relevant hashtags
  static List<String> _generateHashtags(String title, String content) {
    final hashtags = <String>[];
    final text = '${title.toLowerCase()} ${content.toLowerCase()}';
    
    // Agriculture and livestock related hashtags
    if (text.contains('ubworozi') || text.contains('amata') || text.contains('inka')) {
      hashtags.add('#Ubworozi');
      hashtags.add('#Amata');
    }
    
    if (text.contains('ubuhinzi') || text.contains('ibihingwa')) {
      hashtags.add('#Ubuhinzi');
    }
    
    if (text.contains('rwanda') || text.contains('u rwanda')) {
      hashtags.add('#Rwanda');
    }
    
    if (text.contains('minisitiri') || text.contains('gahunda')) {
      hashtags.add('#Gahunda');
    }
    
    // Always add news and agriculture tags
    hashtags.addAll(['#Amakuru', '#Ubuhinzi', '#KigaliToday']);
    
    return hashtags.take(5).toList(); // Limit to 5 hashtags
  }

  /// Fetch and post articles from Kigali Today
  static Future<void> fetchAndPostArticles({int limit = 20}) async {
    try {
      if (kDebugMode) {
        print('Starting to fetch articles from Kigali Today...');
      }

      final articles = await NewsScraperService.fetchArticles(limit: limit);
      
      if (kDebugMode) {
        print('Fetched ${articles.length} articles');
      }

      int successCount = 0;
      for (final article in articles) {
        try {
          final success = await postArticle(article);
          if (success) {
            successCount++;
            if (kDebugMode) {
              print('Posted: ${article.title}');
            }
          }
          
          // Add delay between posts to avoid rate limiting
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          if (kDebugMode) {
            print('Error posting article ${article.title}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('Successfully posted $successCount out of ${articles.length} articles');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchAndPostArticles: $e');
      }
    }
  }
}
