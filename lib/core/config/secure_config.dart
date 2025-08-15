import 'package:flutter_dotenv/flutter_dotenv.dart';

class SecureConfig {
  static String? _openaiApiKey;
  static String? _claudeApiKey;
  static String? _googleVisionApiKey;
<<<<<<< HEAD
=======
  static String? _yourApiKey;
  static String? _apiBaseUrl;
>>>>>>> 9e50ede (feat: Enhanced login screen with email/phone toggle and country code selection)
  static bool _initialized = false;

  /// Initialize environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      _initialized = true;
      print('Environment variables loaded successfully');
    } catch (e) {
      print('Warning: .env file not found, using fallback API keys');
      // Continue with fallback keys
    }
  }

  /// Get OpenAI API key from environment or fallback
  static String get openaiApiKey {
    if (_openaiApiKey != null) return _openaiApiKey!;
    
    if (_initialized) {
      _openaiApiKey = dotenv.env['OPENAI_API_KEY'];
    }
    
    _openaiApiKey ??= 'YOUR_OPENAI_API_KEY_HERE';
    return _openaiApiKey!;
  }

  /// Get Claude API key from environment or fallback
  static String get claudeApiKey {
    if (_claudeApiKey != null) return _claudeApiKey!;
    
    if (_initialized) {
      _claudeApiKey = dotenv.env['CLAUDE_API_KEY'];
    }
    
    _claudeApiKey ??= 'YOUR_CLAUDE_API_KEY_HERE';
    return _claudeApiKey!;
  }

  /// Get Google Vision API key from environment or fallback
  static String get googleVisionApiKey {
    if (_googleVisionApiKey != null) return _googleVisionApiKey!;
    
    if (_initialized) {
      _googleVisionApiKey = dotenv.env['GOOGLE_VISION_API_KEY'];
    }
    
    _googleVisionApiKey ??= 'YOUR_GOOGLE_VISION_API_KEY';
    return _googleVisionApiKey!;
  }

<<<<<<< HEAD
=======
  /// Get Your API key from environment or fallback
  static String get yourApiKey {
    if (_yourApiKey != null) return _yourApiKey!;
    
    if (_initialized) {
      _yourApiKey = dotenv.env['YOUR_API_KEY'];
    }
    
    _yourApiKey ??= 'YOUR_API_KEY_HERE';
    return _yourApiKey!;
  }

  /// Get API Base URL from environment or fallback
  static String get apiBaseUrl {
    if (_apiBaseUrl != null) return _apiBaseUrl!;
    
    if (_initialized) {
      _apiBaseUrl = dotenv.env['API_BASE_URL'];
    }
    
    _apiBaseUrl ??= 'https://api.gemura.rw/v2';
    return _apiBaseUrl!;
  }

>>>>>>> 9e50ede (feat: Enhanced login screen with email/phone toggle and country code selection)
  /// Check if API keys are configured
  static bool get isOpenAIConfigured => openaiApiKey.isNotEmpty && 
      openaiApiKey != 'YOUR_OPENAI_API_KEY_HERE';
  
  static bool get isClaudeConfigured => claudeApiKey.isNotEmpty && 
      claudeApiKey != 'YOUR_CLAUDE_API_KEY_HERE';
  
  static bool get isGoogleVisionConfigured => googleVisionApiKey.isNotEmpty && 
      googleVisionApiKey != 'YOUR_GOOGLE_VISION_API_KEY';
<<<<<<< HEAD
} 
=======
      
  static bool get isYourApiConfigured => yourApiKey.isNotEmpty && 
      yourApiKey != 'YOUR_API_KEY_HERE';
}
>>>>>>> 9e50ede (feat: Enhanced login screen with email/phone toggle and country code selection)
