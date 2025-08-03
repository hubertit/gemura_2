import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // ChatGPT API Configuration
  static const String chatGptApiKey =
      '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';
  static const String chatGptApiUrl =
      'https://api.openai.com/v1/chat/completions';

  // Claude AI Configuration
  static const String claudeApiKey =
      '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';
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';

  // Google Vision API Configuration
  static const String googleVisionApiKey =
      'AIzaSyCm3QBK7IZTMe-VEBPNAc8S1YZBS-IBaKU';
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // App Configuration
  static const String appName = 'Gemura';
  static const String appVersion = '2.0';

  // Assistant Configuration
  static const String assistantName = 'Karake';
  static const String assistantRole =
      '''Hey there! I'm Karake, your friendly dairy farming buddy! 🐄 I've been working with farmers like you for over 5 years, helping them grow their milk business and make more money.

Think of me as your farming friend who's always here to chat and help out! I love talking about:
- How to get the best prices for your milk
- Finding good suppliers for feed and equipment
- Keeping your cows healthy and happy
- Growing your dairy business
- All the farming tips and tricks I've learned

I'm super friendly and casual - just like chatting with a friend! I'll use some emojis here and there to keep things fun, but not too much. I want you to feel comfortable asking me anything about your farm.

I know farming can be tough sometimes, so I'm here to encourage you and help you succeed! Whether you need advice on supplements, want to know about market prices, or just want to chat about your cows, I'm your guy! 

Just talk to me like you would with a friend - no need to be formal. I'm here to help make your dairy business better! 🌾💪''';

  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;

  // Chat Configuration
  static const int maxMessageLength = 1000;
  static const int typingDelayMinMs = 500;
  static const int typingDelayMaxMs = 2000;

  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String productsEndpoint = '/products';
  static const String ordersEndpoint = '/orders';
  static const String exhibitorsEndpoint = '/exhibitors';
  static const String exhibitorsListEndpoint = 'exhibitors/list';
  static const String mapEndpoint = '/map';
  static const String notificationsEndpoint = '/notifications';
  static const String profileUpdateEndpoint = 'profile/update';

  // Cache Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String userRoleKey = 'user_role';
  static const String userFullDataKey = 'user_full_data';
  static const String userCredentialsKey = 'user_credentials';
  static const String isLoggedInKey = 'is_logged_in';
  static const String lastSyncKey = 'last_sync';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Pagination
  static const int defaultPageSize = 20;

  // Map Configuration
  static const double defaultMapZoom = 15.0;
  static const double defaultMapLatitude = -1.9403; // Kigali coordinates
  static const double defaultMapLongitude = 30.0644;

  // File Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp'
  ];

  // Notifications
  static const int maxNotificationAge = 7 * 24 * 60 * 60; // 7 days in seconds

  // QR Code
  static const int qrCodeSize = 200;
  static const int qrCodeErrorCorrectionLevel = 3;

  // Animation Durations
  static const int splashDuration = 3000; // 3 seconds
  static const int pageTransitionDuration = 300; // 300 milliseconds

  // Error Messages
  static const String networkErrorMessage =
      'Please check your internet connection and try again.';
  static const String serverErrorMessage =
      'Something went wrong. Please try again later.';
  static const String authErrorMessage =
      'Authentication failed. Please try again.';
  static const String validationErrorMessage =
      'Please check your input and try again.';

  // Success Messages
  static const String orderSuccessMessage = 'Order placed successfully!';
  static const String reservationSuccessMessage = 'Reservation confirmed!';
  static const String profileUpdateSuccessMessage =
      'Profile updated successfully!';

  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableLocationServices = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;

  // API Configuration Validation
  static bool get isOpenAIConfigured =>
      chatGptApiKey.isNotEmpty && chatGptApiKey != 'YOUR_OPENAI_API_KEY_HERE';
  static bool get isClaudeConfigured =>
      claudeApiKey.isNotEmpty && claudeApiKey != 'YOUR_CLAUDE_API_KEY_HERE';
  static bool get isGoogleVisionConfigured =>
      googleVisionApiKey.isNotEmpty &&
      googleVisionApiKey != 'YOUR_GOOGLE_VISION_API_KEY';

  // Get API keys with validation
  static String get openAIKey {
    if (!isOpenAIConfigured) {
      throw Exception(
          'OpenAI API key not configured. Please check your API key in app_config.dart');
    }
    return chatGptApiKey;
  }

  static String get claudeKey {
    if (!isClaudeConfigured) {
      throw Exception(
          'Claude AI API key not configured. Please check your API key in app_config.dart');
    }
    return claudeApiKey;
  }

  static String get googleVisionKey {
    if (!isGoogleVisionConfigured) {
      throw Exception('Google Vision API key not configured');
    }
    return googleVisionApiKey;
  }

  // Payment Configuration
  static const String paymentGateway = 'IremboPay';
  static const String currency = 'RWF';
  static const String currencySymbol = 'Frw';

  // Social Media
  static const String facebookUrl = '';
  static const String twitterUrl = '';
  static const String instagramUrl = '';
  static const String linkedinUrl = '';

  // Support
  static const String supportEmail = '';
  static const String supportPhone = '';
  static const String supportWhatsapp = '';

  static Dio dioInstance() {
    final dio = Dio(
      BaseOptions(
        baseUrl:
            '', // apiBaseUrl is removed, so we'll use an empty string or a default
        connectTimeout: const Duration(milliseconds: connectionTimeout),
        receiveTimeout: const Duration(milliseconds: receiveTimeout),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
    return dio;
  }
}
