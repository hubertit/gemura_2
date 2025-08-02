import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/chat_gpt_service.dart';
import '../../../../core/services/conversation_storage_service.dart';
import '../../../../shared/widgets/markdown_text.dart';

class BotChatScreen extends ConsumerStatefulWidget {
  const BotChatScreen({super.key});

  @override
  ConsumerState<BotChatScreen> createState() => _BotChatScreenState();
}

class _BotChatScreenState extends ConsumerState<BotChatScreen> {
  final List<BotMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    final savedMessages = await ConversationStorageService.loadConversation();
    
    if (savedMessages.isNotEmpty) {
      final loadedMessages = savedMessages.map((msg) => BotMessage(
        id: msg['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        text: msg['text'] ?? '',
        isUser: msg['isUser'] ?? false,
        timestamp: msg['timestamp'] != null 
            ? DateTime.parse(msg['timestamp']) 
            : DateTime.now(),
        messageType: BotMessageType.text,
      )).toList();
      
      setState(() {
        _messages.addAll(loadedMessages);
      });
    } else {
      _messages.add(
        BotMessage(
          id: '1',
          text: 'Hello! 👋 I\'m Karake, your milk collection specialist. I help farmers with suppliers, customers, collections, sales, and pricing. How can I assist you today?',
          isUser: false,
          timestamp: DateTime.now(),
          messageType: BotMessageType.text,
        ),
      );
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _saveConversation() async {
    final messagesForStorage = _messages.map((msg) => {
      'id': msg.id,
      'text': msg.text,
      'isUser': msg.isUser,
      'timestamp': msg.timestamp.toIso8601String(),
    }).toList();
    
    await ConversationStorageService.saveConversation(messagesForStorage);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final capitalizedText = text[0].toUpperCase() + text.substring(1);
    
    _messages.add(
      BotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: capitalizedText,
        isUser: true,
        timestamp: DateTime.now(),
        messageType: BotMessageType.text,
      ),
    );

    _messageController.clear();
    setState(() {});
    _saveConversation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    
    setState(() {
      _isTyping = true;
    });

    _simulateBotResponse(capitalizedText);
  }

  Future<void> _simulateBotResponse(String userMessage) async {
    try {
      // Convert messages to the format expected by ChatGPT service
      final conversationHistory = _messages.map((msg) => {
        'text': msg.text,
        'isUser': msg.isUser,
      }).toList();

      final response = await ChatGptService().generateResponse(userMessage, conversationHistory);
      
      // Calculate typing delay based on response length
      final typingDelay = _calculateTypingDelay(response.length);
      await Future.delayed(Duration(milliseconds: typingDelay));

      if (mounted) {
        setState(() {
          _messages.add(
            BotMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
              messageType: BotMessageType.text,
            ),
          );
          _isTyping = false;
        });
        _saveConversation();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        _focusInput();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            BotMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: "Sorry, there was an error connecting to the service. Please check your internet connection and try again.",
              isUser: false,
              timestamp: DateTime.now(),
              messageType: BotMessageType.text,
            ),
          );
          _isTyping = false;
        });
        _saveConversation();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        _focusInput();
      }
    }
  }

  int _calculateTypingDelay(int responseLength) {
    // Base delay + additional time based on response length
    final baseDelay = AppConfig.typingDelayMinMs;
    final additionalDelay = (responseLength / 10).clamp(0, AppConfig.typingDelayMaxMs - baseDelay);
    return (baseDelay + additionalDelay).round();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _focusInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  void _showCopyMenu(BuildContext context, String text) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Message copied to clipboard'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacing8),
          ],
        ),
      ),
    );
  }

  void _showClearConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Are you sure you want to clear all conversation history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearConversation();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearConversation() async {
    await ConversationStorageService.clearConversation();
    
    setState(() {
      _messages.clear();
    });
    
    _messages.add(
      BotMessage(
        id: '1',
        text: 'Hello! 👋 I\'m Karake, your milk collection specialist. I help farmers with suppliers, customers, collections, sales, and pricing. How can I assist you today?',
        isUser: false,
        timestamp: DateTime.now(),
        messageType: BotMessageType.text,
      ),
    );
    
    _saveConversation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Column(
          children: [
            Text(
              AppConfig.assistantName,
              style: AppTheme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Milk Collection Specialist',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _showClearConversationDialog,
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          _inputFocusNode.unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  final message = _messages[index];
                  return _buildMessageTile(message);
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _inputFocusNode,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(fontSize: 14),
                        maxLength: 500,
                        maxLines: null,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Ask about milk collection...',
                          hintStyle: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
                                                     border: const OutlineInputBorder(
                             borderRadius: BorderRadius.all(Radius.circular(24)),
                             borderSide: BorderSide(width: 1, color: AppTheme.thinBorderColor),
                           ),
                           enabledBorder: const OutlineInputBorder(
                             borderRadius: BorderRadius.all(Radius.circular(24)),
                             borderSide: BorderSide(width: 1, color: AppTheme.thinBorderColor),
                           ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(24)),
                            borderSide: BorderSide(width: 1.2, color: AppTheme.primaryColor),
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceColor,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          counterText: '',
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: IconButton(
                              icon: const Icon(Icons.send),
                              color: AppTheme.primaryColor,
                              onPressed: _isTyping ? null : _sendMessage,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(BotMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showCopyMenu(context, message.text),
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: message.isUser ? 60 : 0,
            right: message.isUser ? 0 : 60,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: message.isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(message.isUser ? 16 : 4),
              bottomRight: Radius.circular(message.isUser ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Text(
                  AppConfig.assistantName,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
              ],
                             message.isUser 
                 ? Text(
                     message.text,
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 14,
                     ),
                   )
                 : MarkdownText(
                     text: message.text,
                     style: const TextStyle(fontSize: 14),
                     textColor: AppTheme.textPrimaryColor,
                   ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: AppTheme.bodySmall.copyWith(
                  color: message.isUser 
                      ? Colors.white.withOpacity(0.7) 
                      : AppTheme.textSecondaryColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4, right: 60),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConfig.assistantName,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              height: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypingDot(0),
                  const SizedBox(width: 2),
                  _buildTypingDot(1),
                  const SizedBox(width: 2),
                  _buildTypingDot(2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.textSecondaryColor.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

class BotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final BotMessageType messageType;

  BotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.messageType,
  });
}

enum BotMessageType {
  text,
  action,
  data,
} 