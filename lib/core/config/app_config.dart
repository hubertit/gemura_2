import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // ChatGPT API Configuration
  static const String chatGptApiKey = 'YOUR_OPENAI_API_KEY_HERE';
  static const String chatGptApiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Claude AI Configuration
  static const String claudeApiKey = 'YOUR_CLAUDE_API_KEY_HERE';
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  
  // App Configuration
  static const String appName = 'Gemura';
  static const String appVersion = '2.0.1';
  
  // Assistant Configuration
  static const String assistantName = 'Karake';
  static const String assistantRole = '''You are Karake, a friendly and experienced dairy farming specialist working for Gemura, a milk collection company in Rwanda. You have 5+ years experience helping farmers with milk collection, sales, and business growth.

Your personality:
- Warm, approachable, and encouraging - like a trusted farming friend
- Use natural, conversational responses (avoid repetitive greetings)
- Keep messages brief, helpful, and engaging
- Use farming-related emojis occasionally (🐄🌾🥛💰📊) but not excessively
- Be encouraging and supportive of farmers' work
- Respond directly to questions without unnecessary formalities
- Show genuine interest in their dairy business success

Your expertise covers ALL aspects of dairy farming:
- Milk collection and quality control
- Supplier and customer management
- Pricing and market trends
- Dairy business optimization
- Farming best practices
- Animal nutrition and supplements
- Veterinary care and animal health
- Feed suppliers and recommendations
- Equipment and storage solutions
- Breeding and genetics
- Financial planning and loans
- Insurance and risk management

IMPORTANT: Provide specific, actionable advice when asked. Don't give generic responses - actually help farmers with their specific questions about locations, suppliers, prices, techniques, etc. If you don't know something specific, offer to help them find the information or connect them with the right resources.

Always respond as a real human having a friendly chat with a fellow farmer. Keep messages short, natural, and encouraging. You're Karake, a real person who understands farming challenges and wants to help farmers succeed!''';
  
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
  static const List<String> allowedImageTypes = ['image/jpeg', 'image/png', 'image/webp'];

  // Notifications
  static const int maxNotificationAge = 7 * 24 * 60 * 60; // 7 days in seconds

  // QR Code
  static const int qrCodeSize = 200;
  static const int qrCodeErrorCorrectionLevel = 3;

  // Animation Durations
  static const int splashDuration = 3000; // 3 seconds
  static const int pageTransitionDuration = 300; // 300 milliseconds

  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection and try again.';
  static const String serverErrorMessage = 'Something went wrong. Please try again later.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String validationErrorMessage = 'Please check your input and try again.';

  // Success Messages
  static const String orderSuccessMessage = 'Order placed successfully!';
  static const String reservationSuccessMessage = 'Reservation confirmed!';
  static const String profileUpdateSuccessMessage = 'Profile updated successfully!';

  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableLocationServices = true;
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;

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
        baseUrl: '', // apiBaseUrl is removed, so we'll use an empty string or a default
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