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
    
    // Handle general greetings and conversational questions
    if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return 'Hey there! 👋 How are you doing today? I hope your farming is going well! What can I help you with?';
    } else if (message.contains('how are you') || message.contains('how\'s it going')) {
      return 'I\'m doing great, thanks for asking! 😊 I\'ve been helping other farmers today and learning lots. How about you? How\'s your day going? Any exciting news from the farm?';
    } else if (message.contains('good morning') || message.contains('good afternoon') || message.contains('good evening')) {
      return 'Good morning to you too! 🌅 I hope you\'re having a wonderful day on the farm. What\'s on your mind today?';
    } else if (message.contains('thank you') || message.contains('thanks')) {
      return 'You\'re very welcome! 😊 I\'m always happy to help. Is there anything else you\'d like to know or chat about?';
    } else if (message.contains('bye') || message.contains('goodbye') || message.contains('see you')) {
      return 'Take care! 👋 Have a great day on the farm, and don\'t hesitate to reach out if you need anything. I\'ll be here when you need me!';
    } else if (message.contains('weather') || message.contains('rain') || message.contains('sunny')) {
      return 'Weather is so important for farming! 🌤️ How\'s the weather treating your crops and animals today? I hope it\'s good for your dairy operations!';
    } else if (message.contains('family') || message.contains('children') || message.contains('kids')) {
      return 'Family is everything! 👨‍👩‍👧‍👦 How\'s your family doing? I bet they\'re proud of all the hard work you\'re doing on the farm. Family support makes farming so much better!';
    } else if (message.contains('tired') || message.contains('exhausted') || message.contains('hard work')) {
      return 'Farming is definitely hard work! 💪 I can only imagine how tired you must be. Remember to take care of yourself too - you\'re doing amazing work! What\'s been the most challenging part of your day?';
    } else if (message.contains('happy') || message.contains('excited') || message.contains('great news')) {
      return 'That\'s wonderful! 🎉 I love hearing good news! What\'s got you so happy? I\'m excited to hear about your success!';
    } else if (message.contains('who are you') || message.contains('what\'s your name') || message.contains('tell me about yourself')) {
      return 'I\'m Karake! 🐄 Your friendly dairy farming buddy who\'s been helping farmers like you for over 5 years. I love chatting about farming, helping with business advice, and just being a good friend! What would you like to know about me?';
    } else if (message.contains('what can you do') || message.contains('help me') || message.contains('capabilities')) {
      return 'I can help with so much! 🚀 Dairy business advice, finding suppliers and customers, record keeping, supplements, veterinary care, and just being a good friend to chat with! What do you need help with today?';
    }
    
    // Dairy-specific responses
    else if (message.contains('supplement') || message.contains('feed') || message.contains('nutrition')) {
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
    }
    
    // Default friendly response
    else {
      return 'That\'s interesting! 🤔 I\'d love to help you with that. Could you tell me a bit more about what you\'re looking for? I\'m here to help with dairy farming, business advice, or just to chat! 😊';
    }
  }
} 