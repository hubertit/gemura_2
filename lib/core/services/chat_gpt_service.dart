import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'conversation_storage_service.dart';

class ChatGptService {
  static final ChatGptService _instance = ChatGptService._internal();
  factory ChatGptService() => _instance;
  ChatGptService._internal();

  Future<String> generateResponse(String userMessage, List<Map<String, dynamic>> conversationHistory) async {
    try {
      // Get conversation context from storage
      final conversationSummary = await ConversationStorageService.getConversationSummary();
      final isRecent = await ConversationStorageService.isRecentConversation();
      
      // Create context-aware system message
      String systemMessage = AppConfig.assistantRole;
      if (isRecent && conversationSummary.isNotEmpty) {
        systemMessage += '\n\nPrevious conversation context:\n$conversationSummary';
      }
      
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
              'content': systemMessage,
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
    
    // More specific and helpful responses
    if (message.contains('supplement') || message.contains('feed') || message.contains('nutrition')) {
      if (message.contains('nyagatare')) {
        return 'For supplements in Nyagatare, I recommend checking with local agricultural stores like Nyagatare Farmers Cooperative or contacting the district agricultural office. You can also try suppliers like Inyange Industries or Uzima Feeds who have branches in the Eastern Province. Would you like me to help you find specific contact details? 📞';
      }
      return 'For cow supplements, I can help you find suppliers in your area. What district are you in? I can recommend local agricultural stores and feed suppliers. 🐄';
    } else if (message.contains('supplier') || message.contains('register')) {
      return 'Perfect! Let\'s get that supplier registered! 📝 What info do you have about them? Name, location, contact details? 🏡';
    } else if (message.contains('customer')) {
      return 'Great! New customers mean more business! 🎉 What details do you have? Name, phone, location? 📞';
    } else if (message.contains('collection') || message.contains('collect')) {
      return 'Awesome! Let\'s record that collection! 📊 Which supplier and how much milk? Quality looks good? 🥛';
    } else if (message.contains('sale') || message.contains('sell')) {
      return 'Nice! Time to make some sales! 💰 Which customer are you selling to? How much milk? 📈';
    } else if (message.contains('price') || message.contains('cost')) {
      return 'Current prices are 300-400 Frw/L depending on quality and your location. What area are you in? 💰';
    } else if (message.contains('help') || message.contains('what can you do')) {
      return 'I help with everything dairy! Suppliers, customers, collections, sales, pricing, supplements, veterinary services, and farming advice. What do you need help with? 😊';
    } else if (message.contains('who are you') || message.contains('what\'s your name')) {
      return 'I\'m Karake! Your dairy farming buddy who helps with milk collection, suppliers, customers, supplements, veterinary care, and getting the best deals! 🐄 How can I help you today?';
    } else if (message.contains('hello') || message.contains('hi') || message.contains('nice to meet')) {
      return 'Hey! Great to meet you too! How\'s the farming going? What can I help you with today? 🌾';
    } else if (message.contains('milk') || message.contains('dairy')) {
      return 'Milk business is the best business! 🥛 What do you need help with? Collections, sales, supplements, or finding new customers?';
    } else if (message.contains('farm') || message.contains('farmer')) {
      return 'Farmers are the backbone of our country! 🌾 How can I help make your dairy business even better?';
    } else if (message.contains('quality') || message.contains('test')) {
      return 'Quality is everything in dairy! 🧪 What specific quality concerns do you have? I can help with testing and standards.';
    } else if (message.contains('money') || message.contains('profit')) {
      return 'Let\'s make sure you\'re getting the best prices! 💰 What\'s your current situation? I can help optimize your profits.';
    } else if (message.contains('veterinary') || message.contains('vet') || message.contains('health')) {
      return 'Animal health is crucial! I can help you find veterinary services, vaccination schedules, and health monitoring tips. What specific health concerns do you have? 🏥';
    } else if (message.contains('feed') || message.contains('feeding')) {
      return 'Proper feeding is key to good milk production! I can help with feed recommendations, suppliers, and feeding schedules. What do you need? 🌱';
    } else if (message.contains('breed') || message.contains('cow type')) {
      return 'Different breeds have different strengths! I can help you understand Holstein, Jersey, and local breeds for your farming goals. What breed are you working with? 🐄';
    } else if (message.contains('storage') || message.contains('preserve')) {
      return 'Milk storage is critical for quality! I can help with cooling systems, storage containers, and preservation techniques. What storage challenges are you facing? ❄️';
    } else {
      // More varied and helpful responses
      final responses = [
        'How can I help with your dairy business today? 🐄',
        'What\'s new on the farm? Need help with collections, sales, or animal care? 🌾',
        'Ready to help with suppliers, customers, collections, supplements, or veterinary care. What\'s on your mind? 📊',
        'Another great day for dairy farming! What do you need help with? 🥛',
        'Farmers like you make our country strong! How can I assist today? 💪',
        'I\'m here to help with all aspects of dairy farming - from feed to finance! What\'s your question? 🌱',
      ];
      return responses[DateTime.now().millisecond % responses.length];
    }
  }
} 