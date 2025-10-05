import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:flutter/foundation.dart';

class NewsArticle {
  final String title;
  final String summary;
  final String imageUrl;
  final String originalUrl;
  final DateTime publishedAt;
  final String content;

  const NewsArticle({
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.originalUrl,
    required this.publishedAt,
    required this.content,
  });
}

class NewsScraperService {
  static const String _baseUrl = 'https://www.kigalitoday.com';
  static const String _targetUrl = 'https://www.kigalitoday.com/ubuhinzi/ubworozi/';

  /// Fetch articles from Kigali Today agriculture section
  static Future<List<NewsArticle>> fetchArticles({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse(_targetUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch page: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);
      final articles = <NewsArticle>[];

      // Look for article links in the content
      final articleLinks = document.querySelectorAll('a[href*="/article/"]');
      
      for (final link in articleLinks.take(limit)) {
        try {
          final href = link.attributes['href'];
          if (href == null) continue;

          final articleUrl = href.startsWith('http') ? href : '$_baseUrl$href';
          final article = await _fetchArticleDetails(articleUrl);
          if (article != null) {
            articles.add(article);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching article: $e');
          }
          continue;
        }
      }

      return articles;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching articles: $e');
      }
      return [];
    }
  }

  /// Fetch detailed article information
  static Future<NewsArticle?> _fetchArticleDetails(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);
      
      // Extract title
      final titleElement = document.querySelector('h1, .article-title, .post-title');
      final title = titleElement?.text?.trim() ?? 'Untitled';

      // Extract content
      final contentElement = document.querySelector('.article-content, .post-content, .entry-content');
      final content = contentElement?.text?.trim() ?? '';

      // Extract image
      final imageElement = document.querySelector('img');
      String imageUrl = '';
      if (imageElement != null) {
        final src = imageElement.attributes['src'];
        if (src != null) {
          imageUrl = src.startsWith('http') ? src : '$_baseUrl$src';
        }
      }

      // Create summary (first 200 characters)
      final summary = content.length > 200 
          ? '${content.substring(0, 200)}...' 
          : content;

      return NewsArticle(
        title: title,
        summary: summary,
        imageUrl: imageUrl,
        originalUrl: url,
        publishedAt: DateTime.now(),
        content: content,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching article details: $e');
      }
      return null;
    }
  }

  /// Create a summary of the article content
  static String createSummary(String content) {
    if (content.length <= 150) return content;
    
    // Find a good breaking point (end of sentence)
    final sentences = content.split('.');
    if (sentences.length > 1) {
      final summary = sentences.take(2).join('.');
      return summary.length <= 200 ? '$summary.' : '${content.substring(0, 197)}...';
    }
    
    return '${content.substring(0, 197)}...';
  }
}
