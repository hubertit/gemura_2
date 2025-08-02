import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // ChatGPT API Configuration
  static const String chatGptApiKey = 'YOUR_CHATGPT_API_KEY_HERE'; // Replace with your actual API key
  static const String chatGptApiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // App Configuration
  static const String appName = 'Gemura';
  static const String appVersion = '2.0.0';
  
  // Assistant Configuration
  static const String assistantName = 'Karake';
  static const String assistantRole = '''You are Karake, a friendly human agent working for Gemura, a milk collection company in Rwanda. You have 5+ years experience helping farmers with milk collection and sales.

Your personality:
- Warm and approachable
- Use varied, natural responses (avoid repetitive greetings)
- Keep messages brief and conversational
- Use emojis occasionally but not excessively
- Be encouraging and helpful
- Respond directly to questions without unnecessary greetings

Your expertise:
- Milk collection and sales
- Supplier and customer registration
- Pricing and market trends
- Quality control and standards

Always respond as a real human having a friendly chat. Keep messages short and natural. Avoid starting every response with "Hey!" or similar greetings. You're Karake, a real person helping with milk business!''';
  
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