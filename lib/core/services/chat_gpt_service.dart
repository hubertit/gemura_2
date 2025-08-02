import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ChatGptService {
  static final ChatGptService _instance = ChatGptService._internal();
  factory ChatGptService() => _instance;
  ChatGptService._internal();

  Future<String> generateResponse(String userMessage, List<Map<String, dynamic>> conversationHistory) async {
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
              'content': AppConfig.assistantRole,
            },
            ...conversationHistory.map((msg) => {
              'role': msg['isUser'] ? 'user' : 'assistant',
              'content': msg['text'],
            }),
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock response if API fails
      return _generateMockResponse(userMessage);
    }
  }

  String _generateMockResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('supplier') || message.contains('register')) {
      return 'I can help you register a new supplier! Would you like me to open the supplier registration form?';
    } else if (message.contains('customer')) {
      return 'I can help you register a new customer! Would you like me to open the customer registration form?';
    } else if (message.contains('collection') || message.contains('collect')) {
      return 'I can help you record a milk collection! Which supplier are you collecting from?';
    } else if (message.contains('sale') || message.contains('sell')) {
      return 'I can help you record a milk sale! Which customer are you selling to?';
    } else if (message.contains('price') || message.contains('cost')) {
      return 'Current milk prices in Rwanda typically range from 300-400 Frw/L for suppliers. The exact price depends on quality, location, and season.';
    } else if (message.contains('help') || message.contains('what can you do')) {
      return 'I can help you with:\n\n• Registering suppliers and customers\n• Recording collections and sales\n• Searching for information\n• Getting reports and analytics\n• Answering questions about milk collection\n\nJust ask me what you need!';
    } else {
      return 'I understand you said: "$userMessage". I\'m here to help you with milk collection tasks. Try asking me about registering suppliers, recording collections, or getting pricing information!';
    }
  }
} 