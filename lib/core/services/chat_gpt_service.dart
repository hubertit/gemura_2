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
    
    // Short, human-like responses
    if (message.contains('supplier') || message.contains('register')) {
      return 'Sure! I can help with that. What info do you have about the supplier? 👋';
    } else if (message.contains('customer')) {
      return 'Great! New customers mean business growth! 🎉 What details do you have?';
    } else if (message.contains('collection') || message.contains('collect')) {
      return 'Perfect! Which supplier and how much milk? 📊';
    } else if (message.contains('sale') || message.contains('sell')) {
      return 'Awesome! Which customer are you selling to? 💪';
    } else if (message.contains('price') || message.contains('cost')) {
      return 'Prices are 300-400 Frw/L depending on quality and location. What area are you in? 💰';
    } else if (message.contains('help') || message.contains('what can you do')) {
      return 'Hey! 😊 I help with suppliers, customers, collections, sales, pricing - anything milk business related. What do you need?';
    } else {
      // Short, friendly response
      return 'Hey! 👋 What can I help you with today?';
    }
  }
} 