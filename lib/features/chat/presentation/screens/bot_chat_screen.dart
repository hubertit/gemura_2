import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/chat_gpt_service.dart';
import '../../../../core/services/conversation_storage_service.dart';
import '../../../../core/services/attachment_service.dart';
import '../../../../core/services/attachment_processor_service.dart';
import '../../../../core/services/attachment_handler_service.dart';
import '../../../../shared/widgets/markdown_text.dart';
import '../../domain/models/attachment_message.dart';
import 'contact_selection_screen.dart';
import 'package:contacts_service/contacts_service.dart';

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

class _BotChatScreenState extends ConsumerState<BotChatScreen> with SingleTickerProviderStateMixin {
  final List<BotMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isAttaching = false;
  late AnimationController _typingController;
  late Animation<double> _dot1, _dot2, _dot3;

  @override
  void initState() {
    super.initState();
    _initializeTypingAnimation();
    _loadConversation();
  }

  void _initializeTypingAnimation() {
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _dot1 = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _typingController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOut)),
    );
    _dot2 = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _typingController, curve: const Interval(0.2, 0.8, curve: Curves.easeInOut)),
    );
    _dot3 = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _typingController, curve: const Interval(0.4, 1.0, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
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
          text: 'Hey there! 👋 I\'m Karake, your dairy farming buddy! 🐄 I help farmers with milk collection, suppliers, customers, supplements, veterinary care, and getting the best prices. What\'s on your mind today? 🌾',
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
    _typingController.repeat();

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
        _typingController.stop();
        _saveConversation();
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            BotMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: "Oops! Looks like there's a connection issue. Please check your internet and try again. I'm here to help with your dairy business! 🌾",
              isUser: false,
              timestamp: DateTime.now(),
              messageType: BotMessageType.text,
            ),
          );
          _isTyping = false;
        });
        _typingController.stop();
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



  Future<void> _clearConversation() async {
    await ConversationStorageService.clearConversation();
    
    setState(() {
      _messages.clear();
    });
    
    _messages.add(
      BotMessage(
        id: '1',
        text: 'Hey there! 👋 I\'m Karake, your dairy farming buddy! 🐄 I help farmers like you with milk collection, finding suppliers, managing customers, and getting the best prices. What\'s on your mind today? 🌾',
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
        actions: const [],
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
          

          
          // Message Input
          Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
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
                    icon: _isAttaching 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          )
                        : const Icon(
                            Icons.attach_file,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                    onPressed: _isAttaching ? null : _showAttachmentOptions,
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
                        hintText: 'Type a message',
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
            'Let\'s Chat! 🐄',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Ask me about milk collection, suppliers,\ncustomers, pricing, supplements, veterinary care, and dairy farming tips! 🌾',
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
                      color: isCurrentUser ? AppTheme.sentMessageColor : AppTheme.surfaceColor,
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
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (message.attachments != null && message.attachments!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: AppTheme.spacing8),
                                      child: _buildMessageAttachments(message.attachments!),
                                    ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MarkdownText(
                                    text: message.text,
                                    style: const TextStyle(fontSize: 14),
                                    textColor: AppTheme.textPrimaryColor,
                                  ),
                                  if (message.attachments != null && message.attachments!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: AppTheme.spacing8),
                                      child: _buildMessageAttachments(message.attachments!),
                                    ),
                                ],
                              ),
                          const SizedBox(height: AppTheme.spacing2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                messageTime,
                                style: AppTheme.bodySmall.copyWith(
                                  color: isCurrentUser 
                                      ? AppTheme.textSecondaryColor
                                      : AppTheme.textSecondaryColor,
                                  fontSize: 10,
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: AppTheme.spacing2),
                                Icon(
                                  Icons.done_all,
                                  size: 12,
                                  color: AppTheme.textSecondaryColor,
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
                    child: SizedBox(
                      width: 36,
                      height: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _typingController,
                            builder: (context, child) => Padding(
                              padding: EdgeInsets.only(bottom: _dot1.value),
                              child: _buildAnimatedDot(),
                            ),
                          ),
                          const SizedBox(width: 3),
                          AnimatedBuilder(
                            animation: _typingController,
                            builder: (context, child) => Padding(
                              padding: EdgeInsets.only(bottom: _dot2.value),
                              child: _buildAnimatedDot(),
                            ),
                          ),
                          const SizedBox(width: 3),
                          AnimatedBuilder(
                            animation: _typingController,
                            builder: (context, child) => Padding(
                              padding: EdgeInsets.only(bottom: _dot3.value),
                              child: _buildAnimatedDot(),
                            ),
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

  Widget _buildAnimatedDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
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
                  icon: Icons.contacts,
                  label: 'Contacts',
                  onTap: _shareContacts,
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

  Future<void> _openCamera() async {
    Navigator.pop(context);
    setState(() => _isAttaching = true);
    
    try {
      final files = await AttachmentHandlerService.handleCamera(context);
      if (files != null) {
        _addAttachmentMessage(AttachmentType.image, files);
      }
    } catch (e) {
      print('Camera error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: ${e.toString()}'),
          backgroundColor: AppTheme.snackbarErrorColor,
        ),
      );
    } finally {
      setState(() => _isAttaching = false);
    }
  }

  Future<void> _openGallery() async {
    Navigator.pop(context);
    setState(() => _isAttaching = true);
    
    try {
      final files = await AttachmentHandlerService.handleGallery(context);
      if (files != null) {
        _addAttachmentMessage(AttachmentType.image, files);
      }
    } catch (e) {
      print('Gallery error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gallery error: ${e.toString()}'),
          backgroundColor: AppTheme.snackbarErrorColor,
        ),
      );
    } finally {
      setState(() => _isAttaching = false);
    }
  }

  Future<void> _openDocument() async {
    Navigator.pop(context);
    setState(() => _isAttaching = true);
    
    try {
      final files = await AttachmentHandlerService.handleDocument(context);
      if (files != null) {
        _addAttachmentMessage(AttachmentType.document, files);
      }
    } catch (e) {
      _showPermissionError('Document Picker', e.toString());
    } finally {
      setState(() => _isAttaching = false);
    }
  }

  Future<void> _shareContacts() async {
    Navigator.pop(context);
    
    try {
      final contacts = await AttachmentHandlerService.handleContacts(context);
      if (contacts != null) {
        _addContactAttachments(contacts);
      }
    } catch (e) {
      print('Contacts error: $e');
    }
  }

  void _addAttachmentMessage(AttachmentType type, List<File> files) {
    final attachments = files.map((file) => Attachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: file.path.split('/').last,
      path: file.path,
      type: type,
      size: file.lengthSync(),
    )).toList();

    // Create bot message with attachments
    final botMessage = BotMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _getAttachmentText(type, files.length),
      isUser: true,
      timestamp: DateTime.now(),
      messageType: BotMessageType.text,
      attachments: attachments,
    );

    setState(() {
      _messages.add(botMessage);
    });
    
    _saveConversation();
    _scrollToBottom();
    
    // Simulate bot response to attachments
    _simulateBotResponseToAttachments(type, files);
  }

  void _addContactAttachments(List<Contact> contacts) {
    final attachments = contacts.map((contact) => Attachment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: contact.displayName ?? 'Unknown Contact',
      path: contact.phones?.isNotEmpty == true ? contact.phones!.first.value ?? '' : '',
      type: AttachmentType.contact,
      size: 0,
      metadata: {
        'displayName': contact.displayName ?? '',
        'phones': contact.phones?.map((p) => p.value).toList() ?? [],
        'emails': contact.emails?.map((e) => e.value).toList() ?? [],
      },
    )).toList();

    // Create bot message with contact attachments
    final botMessage = BotMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _getContactAttachmentText(contacts.length),
      isUser: true,
      timestamp: DateTime.now(),
      messageType: BotMessageType.text,
      attachments: attachments,
    );

    setState(() {
      _messages.add(botMessage);
    });
    
    _saveConversation();
    _scrollToBottom();
    
    // Simulate bot response to contacts
    _simulateBotResponseToContacts(contacts);
  }





  String _getAttachmentText(AttachmentType type, int count) {
    switch (type) {
      case AttachmentType.image:
        return count == 1 ? '📷 Photo' : '📷 $count Photos';
      case AttachmentType.document:
        return count == 1 ? '📄 Document' : '📄 $count Documents';
      case AttachmentType.contact:
        return count == 1 ? '👥 Contact' : '👥 $count Contacts';
    }
  }

  String _getContactAttachmentText(int count) {
    return count == 1 ? '👥 Contact' : '👥 $count Contacts';
  }

  Future<void> _simulateBotResponseToAttachments(AttachmentType type, List<File> files) async {
    setState(() {
      _isTyping = true;
    });
    _typingController.repeat();

    // Calculate typing delay
    final typingDelay = _calculateTypingDelay(100);
    await Future.delayed(Duration(milliseconds: typingDelay));

    if (mounted) {
      try {
        // Convert files to attachments for processing
        final attachments = files.map((file) => Attachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: file.path.split('/').last,
          path: file.path,
          type: type,
          size: file.lengthSync(),
        )).toList();
        
        // Process attachments to extract information
        final processedInfo = await AttachmentProcessorService.processAttachments(attachments);
        
        // Generate contextual bot response
        final response = AttachmentProcessorService.generateBotResponse(processedInfo, attachments);

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
        _typingController.stop();
        _saveConversation();
        _scrollToBottom();
      } catch (e) {
        // Fallback response if processing fails
        String fallbackResponse = '';
        switch (type) {
          case AttachmentType.image:
            fallbackResponse = files.length == 1 
                ? "Great! I can see the photo you shared. This looks like it could be related to your dairy operations. How can I help you with this? 📸"
                : "I can see you've shared ${files.length} photos. These appear to be related to your dairy business. What would you like me to help you with regarding these images? 📸";
            break;
          case AttachmentType.document:
            fallbackResponse = files.length == 1
                ? "I can see you've shared a document. This looks like it might be related to your dairy business records. How can I assist you with this document? 📄"
                : "I can see you've shared ${files.length} documents. These appear to be dairy business related. What would you like me to help you with regarding these documents? 📄";
            break;
          case AttachmentType.contact:
            fallbackResponse = "I can see you've shared contact information. This could be useful for your dairy business network. How can I help you with these contacts? 👥";
            break;
        }

        setState(() {
          _messages.add(
            BotMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: fallbackResponse,
              isUser: false,
              timestamp: DateTime.now(),
              messageType: BotMessageType.text,
            ),
          );
          _isTyping = false;
        });
        _typingController.stop();
        _saveConversation();
        _scrollToBottom();
      }
    }
  }

  Future<void> _simulateBotResponseToContacts(List<Contact> contacts) async {
    setState(() {
      _isTyping = true;
    });
    _typingController.repeat();

    // Calculate typing delay
    final typingDelay = _calculateTypingDelay(100);
    await Future.delayed(Duration(milliseconds: typingDelay));

    if (mounted) {
      try {
        // Convert contacts to attachments for processing
        final attachments = contacts.map((contact) => Attachment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: contact.displayName ?? 'Unknown Contact',
          path: contact.phones?.isNotEmpty == true ? contact.phones!.first.value ?? '' : '',
          type: AttachmentType.contact,
          size: 0,
          metadata: {
            'displayName': contact.displayName ?? '',
            'phones': contact.phones?.map((p) => p.value).toList() ?? [],
            'emails': contact.emails?.map((e) => e.value).toList() ?? [],
          },
        )).toList();
        
        // Process attachments to extract information
        final processedInfo = await AttachmentProcessorService.processAttachments(attachments);
        
        // Generate contextual bot response
        final response = AttachmentProcessorService.generateBotResponse(processedInfo, attachments);

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
        _typingController.stop();
        _saveConversation();
        _scrollToBottom();
      } catch (e) {
        // Fallback response if processing fails
        final contactNames = contacts.take(3).map((c) => c.displayName ?? 'Unknown').join(', ');
        final fallbackResponse = contacts.length == 1
            ? "I can see you've shared contact information for $contactNames. This could be useful for your dairy business network. How can I help you with this contact?"
            : "I can see you've shared ${contacts.length} contacts including $contactNames. This looks like your dairy business network. How can I help you with these contacts?";

        setState(() {
          _messages.add(
            BotMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: fallbackResponse,
              isUser: false,
              timestamp: DateTime.now(),
              messageType: BotMessageType.text,
            ),
          );
          _isTyping = false;
        });
        _typingController.stop();
        _saveConversation();
        _scrollToBottom();
      }
    }
  }

  Widget _buildMessageAttachments(List<Attachment> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attachments.map((attachment) {
        switch (attachment.type) {
          case AttachmentType.image:
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacing4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                child: Image.file(
                  File(attachment.path),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            );
          case AttachmentType.document:
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacing4),
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Row(
                children: [
                  Icon(
                    AttachmentService.getFileIcon(attachment.fileExtension),
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.name,
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${attachment.fileExtension.toUpperCase()} • ${attachment.readableSize}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          case AttachmentType.contact:
            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacing4),
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.name,
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (attachment.metadata?['phones'] != null && attachment.metadata!['phones'].isNotEmpty)
                          Text(
                            attachment.metadata!['phones'].first.toString(),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
        }
      }).toList(),
    );
  }

  void _showPermissionError(String feature, String error) {
    // Check if permission is permanently denied (used for UI logic)
    final isPermanentlyDenied = error.contains('permanently denied');
    
    // Show dialog for permanently denied permissions
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              'Enable $feature Access',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$feature permission is required to use this feature.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to enable:',
                    style: AppTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    '1. Tap "Open Settings"\n2. Find "Privacy & Security"\n3. Tap "$feature"\n4. Enable for Gemura',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AttachmentService.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
            ),
            child: Text(
              'Open Settings',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
  final List<Attachment>? attachments;

  BotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.messageType,
    this.attachments,
  });
}

enum BotMessageType {
  text,
  action,
  data,
} 