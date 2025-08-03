import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'claude_vision_service.dart';

class HybridAIService {
  HybridAIService._internal();

  static Future<String> processImageWithHybridAI(File imageFile) async {
    try {
      // First, try Claude Vision for image analysis
      final claudeResponse = await ClaudeVisionService.analyzeImage(imageFile);
      
      // Then, use GPT for conversational response
      final gptResponse = await _generateConversationalResponse(claudeResponse['analysis'] ?? '');
      
      return gptResponse;
    } catch (e) {
      // Fallback to basic response
      return "I can see the image you've shared. How can I help you with this?";
    }
  }

  static Future<String> _generateConversationalResponse(String imageAnalysis) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.chatGptApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant for dairy farmers. Provide friendly, practical advice based on the image analysis.',
            },
            {
              'role': 'user',
              'content': 'Based on this image analysis: $imageAnalysis\n\nPlease provide helpful advice for a dairy farmer.',
            },
          ],
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'I can help you with that!';
      } else {
        return 'I can see the image you\'ve shared. How can I help you with this?';
      }
    } catch (e) {
      return 'I can see the image you\'ve shared. How can I help you with this?';
    }
  }
} 