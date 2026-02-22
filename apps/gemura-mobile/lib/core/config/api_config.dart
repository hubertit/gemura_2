import '../config/app_config.dart';

class APIConfig {
  // Use the same OpenAI API key as the bot
  static String get openaiApiKey => AppConfig.chatGptApiKey;

  // Claude AI API key
  static String get claudeApiKey => AppConfig.claudeApiKey;

  // Google Vision API key
  static const String googleVisionApiKey = 'AIzaSyCm3QBK7IZTMe-VEBPNAc8S1YZBS-IBaKU';

  // You can add other API keys here as needed
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // Check if API keys are configured
  static bool get isOpenAIConfigured => openaiApiKey.isNotEmpty && openaiApiKey != 'YOUR_OPENAI_API_KEY_HERE';
  static bool get isClaudeConfigured => claudeApiKey.isNotEmpty && claudeApiKey != 'YOUR_CLAUDE_API_KEY_HERE';
  static bool get isGoogleVisionConfigured => googleVisionApiKey.isNotEmpty && googleVisionApiKey != 'YOUR_GOOGLE_VISION_API_KEY';

  // Get API keys with validation
  static String get openAIKey {
    if (!isOpenAIConfigured) {
      throw Exception('OpenAI API key not configured. Please check your API key in app_config.dart');
    }
    return openaiApiKey;
  }

  static String get claudeKey {
    if (!isClaudeConfigured) {
      throw Exception('Claude AI API key not configured. Please check your API key in app_config.dart');
    }
    return claudeApiKey;
  }

  static String get googleVisionKey {
    if (!isGoogleVisionConfigured) {
      throw Exception('Google Vision API key not configured');
    }
    return googleVisionApiKey;
  }
} 