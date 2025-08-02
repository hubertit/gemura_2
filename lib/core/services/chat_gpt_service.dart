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
    
    // More natural, conversational responses that don't limit the conversation
    if (message.contains('supplier') || message.contains('register')) {
      return 'Hey there! 👋 I\'d be happy to help you register a new supplier! This is one of my favorite parts of the job - helping farmers build their networks. What information do you have about the supplier? I can walk you through the whole process step by step!';
    } else if (message.contains('customer')) {
      return 'Great! Adding new customers is always exciting - it means your business is growing! 🎉 I can help you register them in our system. Do you have their contact details ready? I\'ll make sure we capture everything we need to set up a smooth working relationship.';
    } else if (message.contains('collection') || message.contains('collect')) {
      return 'Perfect! Recording collections is super important for tracking your business growth. 📊 I can help you log this collection properly. Which supplier are you collecting from today? And how much milk are we talking about?';
    } else if (message.contains('sale') || message.contains('sell')) {
      return 'Awesome! Sales are the lifeblood of any business! 💪 I\'m here to help you record this sale properly. Which customer are you selling to? This will help me guide you through the right process.';
    } else if (message.contains('price') || message.contains('cost')) {
      return 'Great question about pricing! 💰 From my experience working with farmers across Rwanda, current milk prices typically range from 300-400 Frw/L, but it really depends on quality, location, and season. What area are you working in? I can give you more specific advice!';
    } else if (message.contains('help') || message.contains('what can you do')) {
      return 'Hey! 😊 I\'m your milk collection specialist, and I\'m here to help you grow your business! I can assist with everything from registering suppliers and customers, to tracking your collections and sales, pricing strategies, quality control, and even business growth tips. What\'s on your mind today?';
    } else {
      // More natural, open-ended response that encourages conversation
      return 'Hey there! 👋 Thanks for reaching out! I\'m here to help you with anything related to your milk collection business. Whether you want to chat about suppliers, customers, pricing, collections, sales, or just general business advice - I\'m your person! What\'s on your mind today?';
    }
  }
} 