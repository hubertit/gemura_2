import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

class _BotChatScreenState extends ConsumerState<BotChatScreen> {
  final List<BotMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
                  AppConfig.assistantName,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConversationDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppTheme.textSecondaryColor),
                    SizedBox(width: AppTheme.spacing8),
                    Text('Clear Conversation'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing8),
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius16)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius16)),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius16)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing8,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) {
                        setState(() => _isTyping = value.isNotEmpty);
                      },
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: _isTyping ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: AppTheme.surfaceColor,
                      size: 18,
                    ),
                    onPressed: _isTyping ? _sendMessage : null,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Start a Conversation',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Ask Karake about milk collection,\nsuppliers, customers, and more.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BotMessage message) {
    final isCurrentUser = message.isUser;
    final messageTime = DateFormat('HH:mm').format(message.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
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
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
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
                GestureDetector(
                  onLongPress: () => _showCopyMenu(context, message.text),
                  child: CustomPaint(
                    painter: ChatBubblePainter(
                      isFromCurrentUser: isCurrentUser,
                      color: isCurrentUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isCurrentUser 
                            ? Text(
                                message.text,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.surfaceColor,
                                  fontSize: 14,
                                ),
                              )
                            : MarkdownText(
                                text: message.text,
                                style: const TextStyle(fontSize: 14),
                                textColor: AppTheme.textPrimaryColor,
                              ),
                          const SizedBox(height: AppTheme.spacing2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                messageTime,
                                style: AppTheme.bodySmall.copyWith(
                                  color: isCurrentUser 
                                      ? AppTheme.surfaceColor.withOpacity(0.7)
                                      : AppTheme.textSecondaryColor,
                                  fontSize: 10,
                                ),
                              ),
                              if (isCurrentUser) ...[
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
                ),
              ],
            ),
          ),
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