import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/chat_gpt_service.dart';

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
        text: 'Hey there! 👋 I\'m Karake, your milk collection specialist here at Gemura. I\'ve been working in the dairy industry for over 5 years, helping farmers and businesses like yours grow their milk collection and sales.\n\nI can help you with everything from registering new suppliers and customers, to tracking your collections and sales, pricing strategies, and even business growth tips! 🐄💪\n\nWhat can I help you with today?',
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

  void _simulateBotResponse(String userMessage) async {
    setState(() {
      _isTyping = true;
    });

    try {
      // Convert messages to format expected by ChatGPT service
      final conversationHistory = _messages.map((msg) => {
        'text': msg.text,
        'isUser': msg.isUser,
      }).toList();

      // Get response from ChatGPT
      final response = await ChatGptService().generateResponse(userMessage, conversationHistory);
      
      // Calculate typing delay based on response length
      final typingDelay = Duration(
        milliseconds: AppConfig.typingDelayMinMs + 
        (response.length * 20).clamp(0, AppConfig.typingDelayMaxMs - AppConfig.typingDelayMinMs)
      );

      // Simulate typing delay
      await Future.delayed(typingDelay);

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
    } catch (e) {
      // Handle error gracefully
      setState(() {
        _isTyping = false;
      });
      
      _messages.add(
        BotMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Sorry, I\'m having trouble connecting right now. Please try again in a moment.',
          isUser: false,
          timestamp: DateTime.now(),
          messageType: BotMessageType.text,
        ),
      );
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
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Karake',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  'Milk Collection Specialist',
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
                      Icons.person,
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
                // Attachment Button
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    onPressed: _showAttachmentOptions,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
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
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
              child: const Icon(
                Icons.person,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
                    child: Text(
                      'Gemura Assistant',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                CustomPaint(
                  painter: ChatBubblePainter(
                    isFromCurrentUser: isUser,
                    color: isUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: AppTheme.bodySmall.copyWith(
                            color: isUser ? AppTheme.surfaceColor : AppTheme.textPrimaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacing2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(message.timestamp),
                              style: AppTheme.bodySmall.copyWith(
                                color: isUser 
                                    ? AppTheme.surfaceColor.withOpacity(0.7)
                                    : AppTheme.textSecondaryColor,
                                fontSize: 10,
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: AppTheme.spacing2),
                              const Icon(
                                Icons.done_all,
                                size: 12,
                                color: Colors.white70,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppTheme.spacing8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
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
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
            child: const Icon(
              Icons.person,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
                  child: Text(
                    AppConfig.assistantName,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
                CustomPaint(
                  painter: ChatBubblePainter(
                    isFromCurrentUser: false,
                    color: AppTheme.surfaceColor,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
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
                ),
              ],
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            
            // Title
            Text(
              'Attach File',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            
            // Attachment options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: _openCamera,
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: _openGallery,
                ),
                _buildAttachmentOption(
                  icon: Icons.description,
                  label: 'Document',
                  onTap: _openDocument,
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  onTap: _shareLocation,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openCamera() {
    Navigator.pop(context);
    // TODO: Implement camera functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera functionality coming soon!'),
        backgroundColor: AppTheme.snackbarInfoColor,
      ),
    );
  }

  void _openGallery() {
    Navigator.pop(context);
    // TODO: Implement gallery picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery picker coming soon!'),
        backgroundColor: AppTheme.snackbarInfoColor,
      ),
    );
  }

  void _openDocument() {
    Navigator.pop(context);
    // TODO: Implement document picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document picker coming soon!'),
        backgroundColor: AppTheme.snackbarInfoColor,
      ),
    );
  }

  void _shareLocation() {
    Navigator.pop(context);
    // TODO: Implement location sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location sharing coming soon!'),
        backgroundColor: AppTheme.snackbarInfoColor,
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

class ChatBubblePainter extends CustomPainter {
  final bool isFromCurrentUser;
  final Color color;

  ChatBubblePainter({required this.isFromCurrentUser, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    if (isFromCurrentUser) {
      // Sent message bubble (right side) with tail
      path.moveTo(12, 0);
      path.lineTo(size.width - 12, 0);
      path.quadraticBezierTo(size.width, 0, size.width, 12);
      path.lineTo(size.width, size.height - 12);
      path.quadraticBezierTo(size.width, size.height, size.width - 12, size.height);
      path.lineTo(size.width - 20, size.height);
      path.lineTo(size.width - 8, size.height + 8);
      path.lineTo(size.width - 12, size.height);
      path.lineTo(12, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - 12);
      path.lineTo(0, 12);
      path.quadraticBezierTo(0, 0, 12, 0);
      path.close();
    } else {
      // Received message bubble (left side) with tail pointing left
      path.moveTo(12, 0);
      path.lineTo(size.width - 12, 0);
      path.quadraticBezierTo(size.width, 0, size.width, 12);
      path.lineTo(size.width, size.height - 12);
      path.quadraticBezierTo(size.width, size.height, size.width - 12, size.height);
      path.lineTo(20, size.height);
      path.lineTo(8, size.height + 8);
      path.lineTo(12, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - 12);
      path.lineTo(0, 12);
      path.quadraticBezierTo(0, 0, 12, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 