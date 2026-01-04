class SecureConfig {
  static String? _openaiApiKey;
  static String? _claudeApiKey;
  static String? _googleVisionApiKey;
  static String? _yourApiKey;
  static String? _apiBaseUrl;
  static bool _initialized = false;

  /// Initialize configuration (no longer uses .env)
  static Future<void> initialize() async {
    // Configuration is now hardcoded or set via other means
    // No .env file loading
    _initialized = true;
  }

  /// Get OpenAI API key (from hardcoded config)
  static String get openaiApiKey {
    if (_openaiApiKey != null) return _openaiApiKey!;
    
    // Use hardcoded value from AppConfig instead of .env
    _openaiApiKey = 'YOUR_OPENAI_API_KEY_HERE';
    return _openaiApiKey!;
  }

  /// Get Claude API key (from hardcoded config)
  static String get claudeApiKey {
    if (_claudeApiKey != null) return _claudeApiKey!;
    
    // Use hardcoded value from AppConfig instead of .env
    _claudeApiKey = 'YOUR_CLAUDE_API_KEY_HERE';
    return _claudeApiKey!;
  }

  /// Get Google Vision API key (from hardcoded config)
  static String get googleVisionApiKey {
    if (_googleVisionApiKey != null) return _googleVisionApiKey!;
    
    // Use hardcoded value from AppConfig instead of .env
    _googleVisionApiKey = 'YOUR_GOOGLE_VISION_API_KEY';
    return _googleVisionApiKey!;
  }

  /// Get Your API key (from hardcoded config)
  static String get yourApiKey {
    if (_yourApiKey != null) return _yourApiKey!;
    
    // Use hardcoded value from AppConfig instead of .env
    _yourApiKey = 'YOUR_API_KEY_HERE';
    return _yourApiKey!;
  }

  /// Get API Base URL (from hardcoded config)
  static String get apiBaseUrl {
    if (_apiBaseUrl != null) return _apiBaseUrl!;
    
    // Use hardcoded value from AppConfig instead of .env
    _apiBaseUrl = 'https://api.gemura.rw/v2';
    return _apiBaseUrl!;
  }

  /// Check if API keys are configured
  static bool get isOpenAIConfigured => openaiApiKey.isNotEmpty && 
      openaiApiKey != 'YOUR_OPENAI_API_KEY_HERE';
  
  static bool get isClaudeConfigured => claudeApiKey.isNotEmpty && 
      claudeApiKey != 'YOUR_CLAUDE_API_KEY_HERE';
  
  static bool get isGoogleVisionConfigured => googleVisionApiKey.isNotEmpty && 
      googleVisionApiKey != 'YOUR_GOOGLE_VISION_API_KEY';
      
  static bool get isYourApiConfigured => yourApiKey.isNotEmpty && 
      yourApiKey != 'YOUR_API_KEY_HERE';
}
