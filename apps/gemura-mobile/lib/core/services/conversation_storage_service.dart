import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationStorageService {
  static const String _conversationKey = 'karake_conversation_history';
  static const String _lastInteractionKey = 'karake_last_interaction';
  
  // Save conversation history
  static Future<void> saveConversation(List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = jsonEncode(messages);
      await prefs.setString(_conversationKey, messagesJson);
      await prefs.setString(_lastInteractionKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Error saving conversation
    }
  }
  
  // Load conversation history
  static Future<List<Map<String, dynamic>>> loadConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(_conversationKey);
      
      if (messagesJson != null) {
        final List<dynamic> messagesList = jsonDecode(messagesJson);
        return messagesList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Error loading conversation
    }
    
    return [];
  }
  
  // Clear conversation history
  static Future<void> clearConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conversationKey);
      await prefs.remove(_lastInteractionKey);
    } catch (e) {
      // Error clearing conversation
    }
  }
  
  // Get last interaction time
  static Future<DateTime?> getLastInteraction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastInteractionString = prefs.getString(_lastInteractionKey);
      
      if (lastInteractionString != null) {
        return DateTime.parse(lastInteractionString);
      }
    } catch (e) {
      // Error getting last interaction
    }
    
    return null;
  }
  
  // Check if conversation is recent (within last 24 hours)
  static Future<bool> isRecentConversation() async {
    final lastInteraction = await getLastInteraction();
    if (lastInteraction == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastInteraction);
    return difference.inHours < 24;
  }
  
  // Get conversation summary for context
  static Future<String> getConversationSummary() async {
    final messages = await loadConversation();
    if (messages.isEmpty) return '';
    
    // Get last 5 messages for context
    final recentMessages = messages.length > 5 
        ? messages.sublist(messages.length - 5) 
        : messages;
    final summary = recentMessages.map((msg) => 
      '${msg['isUser'] ? 'User' : 'Karake'}: ${msg['text']}'
    ).join('\n');
    
    return summary;
  }
} 