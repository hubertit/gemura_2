import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class BotChatScreen extends ConsumerStatefulWidget {
  const BotChatScreen({super.key});

  @override
  ConsumerState<BotChatScreen> createState() => _BotChatScreenState();
}

class _BotChatScreenState extends ConsumerState<BotChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<BotMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      BotMessage(
        id: '1',
        text: 'Hello! I\'m your Gemura Assistant. I can help you with:\n\n• Registering suppliers and customers\n• Recording milk collections and sales\n• Searching for information\n• Getting reports and analytics\n• Answering questions about milk collection\n\nHow can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
        messageType: BotMessageType.text,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _messages.add(
      BotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        messageType: BotMessageType.text,
      ),
    );

    _messageController.clear();
    setState(() {});

    // Simulate bot response
    _simulateBotResponse(text);
  }

  void _simulateBotResponse(String userMessage) {
    setState(() {
      _isTyping = true;
    });

    // Simulate realistic typing delay based on message length
    final response = _generateBotResponse(userMessage);
    final typingDelay = Duration(milliseconds: 500 + (response.length * 20).clamp(500, 2000));

    Future.delayed(typingDelay, () {
      _messages.add(
        BotMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          messageType: BotMessageType.text,
        ),
      );

      setState(() {
        _isTyping = false;
      });

      // Scroll to bottom with smooth animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  String _generateBotResponse(String userMessage) {
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
      return 'I understand you said: "$userMessage". I\'m still learning, but I can help you with milk collection tasks. Try asking me about registering suppliers, recording collections, or getting pricing information!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gemura Assistant',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  'AI Assistant',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Add bot chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageTile(_messages[index]);
              },
            ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      border: Border.all(
                        color: AppTheme.thinBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: AppTheme.thinBorderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textHintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.textHintColor.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(BotMessage message) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Message bubble with tail
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppTheme.borderRadius12),
                        topRight: const Radius.circular(AppTheme.borderRadius12),
                        bottomLeft: Radius.circular(isUser ? AppTheme.borderRadius12 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : AppTheme.borderRadius12),
                      ),
                      border: isUser ? null : Border.all(
                        color: AppTheme.thinBorderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: AppTheme.bodyMedium.copyWith(
                            color: isUser ? Colors.white : AppTheme.textPrimaryColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: AppTheme.bodySmall.copyWith(
                            color: isUser ? Colors.white70 : AppTheme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tail
                  Container(
                    margin: EdgeInsets.only(
                      left: isUser ? 0 : 12,
                      right: isUser ? 12 : 0,
                    ),
                    child: CustomPaint(
                      size: const Size(8, 8),
                      painter: MessageTailPainter(
                        isUser: isUser,
                        color: isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        borderColor: isUser ? null : AppTheme.thinBorderColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppTheme.spacing8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Typing bubble with tail
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.borderRadius12),
                        topRight: Radius.circular(AppTheme.borderRadius12),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(AppTheme.borderRadius12),
                      ),
                      border: Border.all(
                        color: AppTheme.thinBorderColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    ),
                  ),
                  // Tail
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: CustomPaint(
                      size: const Size(8, 8),
                      painter: MessageTailPainter(
                        isUser: false,
                        color: AppTheme.surfaceColor,
                        borderColor: AppTheme.thinBorderColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
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

class MessageTailPainter extends CustomPainter {
  final bool isUser;
  final Color color;
  final Color? borderColor;

  MessageTailPainter({
    required this.isUser,
    required this.color,
    this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Paint? borderPaint;
    if (borderColor != null) {
      borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
    }

    final path = Path();
    
    if (isUser) {
      // User message tail (right side)
      path.moveTo(0, 0);
      path.lineTo(size.width, 4);
      path.lineTo(0, size.height);
      path.close();
    } else {
      // Bot message tail (left side)
      path.moveTo(size.width, 0);
      path.lineTo(0, 4);
      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
    
    if (borderPaint != null) {
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 