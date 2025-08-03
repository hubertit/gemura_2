import 'package:flutter_dotenv/flutter_dotenv.dart';

class SecureConfig {
  static String? _openaiApiKey;
  static String? _claudeApiKey;
  static String? _googleVisionApiKey;
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

  /// Check if API keys are configured
  static bool get isOpenAIConfigured => openaiApiKey.isNotEmpty && 
      openaiApiKey != 'YOUR_OPENAI_API_KEY_HERE';
  
  static bool get isClaudeConfigured => claudeApiKey.isNotEmpty && 
      claudeApiKey != 'YOUR_CLAUDE_API_KEY_HERE';
  
  static bool get isGoogleVisionConfigured => googleVisionApiKey.isNotEmpty && 
      googleVisionApiKey != 'YOUR_GOOGLE_VISION_API_KEY';
} 