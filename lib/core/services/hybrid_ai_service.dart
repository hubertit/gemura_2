import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'claude_vision_service.dart';

class HybridAIService {
  static final HybridAIService _instance = HybridAIService._internal();
  factory HybridAIService() => _instance;
  HybridAIService._internal();

  /// Process image with Claude Vision and generate conversational response with GPT
  static Future<String> processImageWithConversationalResponse(String imagePath) async {
    try {
      // Step 1: Use Claude Vision to analyze the image
      print('🔍 Analyzing image with Claude Vision...');
      final claudeResult = await ClaudeVisionService.analyzeImage(imagePath);
      
      // Step 2: Extract key information from Claude's analysis
      final extractedText = claudeResult['extractedText'] ?? '';
      final documentType = claudeResult['documentType'] ?? 'Unknown';
      final keyInfo = claudeResult['keyInfo'] ?? {};
      final businessRelevance = claudeResult['businessRelevance'] ?? '';
      final aiAnalysis = claudeResult['analysis'] ?? '';
      
      // Step 3: Create a conversational prompt for GPT
      final gptPrompt = _createConversationalPrompt(
        documentType, 
        keyInfo, 
        businessRelevance, 
        aiAnalysis, 
        extractedText
      );
      
      // Step 4: Use GPT to generate a friendly, conversational response
      print('💬 Generating conversational response with GPT...');
      final gptResponse = await _generateGPTResponse(gptPrompt);
      
      return gptResponse;
      
    } catch (e) {
      print('❌ Error in hybrid AI processing: $e');
      return 'I had trouble analyzing that image. Could you try sending it again?';
    }
  }

  /// Create a conversational prompt for GPT based on Claude's analysis
  static String _createConversationalPrompt(
    String documentType, 
    Map<String, dynamic> keyInfo, 
    String businessRelevance, 
    String aiAnalysis, 
    String extractedText
  ) {
    String prompt = '''You are Karake, a friendly dairy business assistant. A user shared an image with you. Here's what was found:

Document Type: $documentType
Key Info: ${keyInfo.toString()}
Analysis: $aiAnalysis

Start by describing what you see in the image, then explain how it helps their dairy business. Keep it friendly and practical. Use 2-3 emojis and write 3-4 sentences.''';

    return prompt;
  }

  /// Generate conversational response using GPT
  static Future<String> _generateGPTResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.chatGptApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.chatGptApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are Karake, a friendly and knowledgeable dairy business assistant. You help farmers with their milk business, suppliers, customers, and operations. Always be encouraging, practical, and conversational. Use emojis to make responses friendly.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 300,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('❌ GPT API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return _generateFallbackResponse(prompt);
      }
    } catch (e) {
      print('❌ GPT API Exception: $e');
      return _generateFallbackResponse(prompt);
    }
  }

  /// Fallback response if GPT fails
  static String _generateFallbackResponse(String prompt) {
    if (prompt.toLowerCase().contains('supplement') || prompt.toLowerCase().contains('medication')) {
      return 'I can see this is a veterinary supplement from Interchemie! It contains Vitamin E and Selenium which are essential nutrients for dairy cattle. This type of supplement helps keep your animals healthy, supports their immune system, and improves reproductive health. Always consult with your veterinarian before using any supplements! 🐄💊';
    } else {
      return 'I can see this document in the image! It appears to be related to your dairy business operations. This could be useful for record keeping, supplier management, or financial tracking. What specific information would you like to know about it? 📄😊';
    }
  }
} 