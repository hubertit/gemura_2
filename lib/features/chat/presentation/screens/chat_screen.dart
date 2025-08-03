import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:contacts_service/contacts_service.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/attachment_handler_service.dart';
import '../../domain/models/attachment_message.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';
import '../providers/chat_provider.dart';
import '../../../merchant/presentation/screens/wallets_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
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

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chatRoom.id,
      senderId: 'USER-1', // Current user ID
      senderName: 'John Doe', // Current user name
      senderAvatar: 'assets/images/logo.png',
      content: _messageController.text.trim(),
      type: MessageType.text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    ref.read(chatProvider.notifier).addMessage(message);
    _messageController.clear();
    setState(() => _isTyping = false);

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chatRoom.id));

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside the text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                child: widget.chatRoom.groupAvatar != null
                    ? ClipOval(
                        child: Image.asset(
                          widget.chatRoom.groupAvatar!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        widget.chatRoom.name.substring(0, 1).toUpperCase(),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chatRoom.name,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.chatRoom.members.length} members',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _navigateToWalletDetails,
            ),
          ],
        ),
        body: Column(
          children: [
            // Wallet Info Card
            Container(
              margin: const EdgeInsets.all(AppTheme.spacing12),
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                border: Border.all(color: AppTheme.thinBorderColor.withOpacity(0.3)),
              ),
              child: InkWell(
                onTap: () => _navigateToWalletDetails(),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chatRoom.wallet.name,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing2),
                          Text(
                            'Balance: ${NumberFormat.currency(symbol: 'Frw ').format(widget.chatRoom.wallet.balance)}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Messages
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping on the message list
                  FocusScope.of(context).unfocus();
                },
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCurrentUser = message.senderId == 'USER-1'; // Assuming current user is USER-1
                          return _buildMessageBubble(message, isCurrentUser);
                        },
                      ),
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
      ),
    );
  }

  void _navigateToWalletDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletDetailsScreen(wallet: widget.chatRoom.wallet),
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
            'Send a message to start chatting with\nyour group members.',
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

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
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
              child: message.senderAvatar != null
                  ? ClipOval(
                      child: Image.asset(
                        message.senderAvatar!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      message.senderName.substring(0, 1).toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
                      message.senderName,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                CustomPaint(
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
                        if (message.type == MessageType.payment)
                          _buildPaymentMessage(message)
                        else
                          Text(
                            message.content,
                            style: AppTheme.bodySmall.copyWith(
                              color: isCurrentUser ? AppTheme.textPrimaryColor : AppTheme.textPrimaryColor,
                              fontSize: 14,
                            ),
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
                                _getStatusIcon(message.status),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payment,
            color: AppTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Message',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  message.content,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
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
    final files = await AttachmentHandlerService.handleCamera(context);
    if (files != null) {
      _handleAttachments(AttachmentType.image, files);
    }
  }

  Future<void> _openGallery() async {
    Navigator.pop(context);
    final files = await AttachmentHandlerService.handleGallery(context);
    if (files != null) {
      _handleAttachments(AttachmentType.image, files);
    }
  }

  Future<void> _openDocument() async {
    Navigator.pop(context);
    final files = await AttachmentHandlerService.handleDocument(context);
    if (files != null) {
      _handleAttachments(AttachmentType.document, files);
    }
  }

  Future<void> _shareContacts() async {
    Navigator.pop(context);
    final contacts = await AttachmentHandlerService.handleContacts(context);
    if (contacts != null) {
      _handleContacts(contacts);
    }
  }

  void _handleAttachments(AttachmentType type, List<File> files) {
    // Handle attachment processing
    _simulateBotResponseToAttachments(type, files);
  }

  void _handleContacts(List<Contact> contacts) {
    // Handle contact processing
    _simulateBotResponseToContacts(contacts);
  }

  void _simulateBotResponseToAttachments(AttachmentType type, List<File> files) {
    // Simulate bot response for attachments
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chatRoom.id,
      senderId: 'BOT',
      senderName: 'Karake',
      senderAvatar: null,
      content: 'I can see you\'ve shared some ${type.toString().split('.').last} files. How can I help you with these?',
      type: MessageType.text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      attachments: files.map((file) => file.path ?? '').toList(),
    );
    
    // Add message using the chat notifier
    ref.read(chatProvider.notifier).addMessage(message);
  }

  void _simulateBotResponseToContacts(List<Contact> contacts) {
    // Simulate bot response for contacts
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chatRoom.id,
      senderId: 'BOT',
      senderName: 'Karake',
      senderAvatar: null,
      content: 'I can see you\'ve shared ${contacts.length} contact(s). How can I help you with these?',
      type: MessageType.text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      attachments: contacts.map((contact) => contact.displayName ?? 'Unknown Contact').toList(),
    );
    
    // Add message using the chat notifier
    ref.read(chatProvider.notifier).addMessage(message);
  }
} 