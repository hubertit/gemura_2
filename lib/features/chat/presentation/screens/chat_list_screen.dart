import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

import '../providers/chat_provider.dart';
import '../../domain/models/chat_room.dart';
import 'chat_screen.dart';
import 'create_list_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final allChats = ref.watch(activeChatsProvider);
    
    // Filter chats based on selected category
    final chats = _getFilteredChats(allChats, _selectedCategory);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Group Chats'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showNewChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Categories
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                                  _buildCategoryChip('All', _selectedCategory == 'All'),
                const SizedBox(width: AppTheme.spacing8),
                _buildCategoryChip('Dairy', _selectedCategory == 'Dairy'),
                const SizedBox(width: AppTheme.spacing8),
                _buildCategoryChip('Milk', _selectedCategory == 'Milk'),
                const SizedBox(width: AppTheme.spacing8),
                _buildCategoryChip('Cattle', _selectedCategory == 'Cattle'),
                const SizedBox(width: AppTheme.spacing8),
                _buildCategoryChip('Training', _selectedCategory == 'Training'),
                  const SizedBox(width: AppTheme.spacing8),
                  // Plus Button (now scrolls with others)
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateListScreen(),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          
          // Stats Card
          Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing4),
      padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.thinBorderColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    '${chats.length} groups • ${_getUnreadCount(chats)} unread',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Chat List
          Expanded(
            child: chats.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
                    itemCount: chats.length + 1, // +1 for bot chat
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildBotChatTile(context);
                      }
                      final chat = chats[index - 1];
                      return _buildChatTile(context, ref, chat);
                    },
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
            'No Group Chats',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Group chats are created for joint wallets',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, WidgetRef ref, ChatRoom chat) {
    final isUnread = chat.unreadCount > 0;
    final lastMessageTime = chat.lastMessageAt != null
        ? DateFormat('HH:mm').format(chat.lastMessageAt!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing4),
                  decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.thinBorderColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
        leading: Stack(
          children: [
                        CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
              child: chat.groupAvatar != null
                  ? ClipOval(
                      child: Image.asset(
                        chat.groupAvatar!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      chat.name.substring(0, 1).toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing2,
                    vertical: AppTheme.spacing2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Text(
                    chat.unreadCount.toString(),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.surfaceColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
                        title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.name,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            if (lastMessageTime.isNotEmpty)
              Text(
                lastMessageTime,
                style: AppTheme.bodySmall.copyWith(
                  color: isUnread ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        subtitle: chat.lastMessageContent != null
            ? Row(
                children: [
                  if (chat.lastMessageSender != null)
                    Text(
                      '${chat.lastMessageSender}: ',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      chat.lastMessageContent!,
                      style: AppTheme.bodySmall.copyWith(
                        color: isUnread ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
                            : Text(
                    '${chat.wallet.name} • ${chat.members.length} members',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
        onTap: () {
          ref.read(chatProvider.notifier).markChatAsRead(chat.id);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatRoom: chat),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBotChatTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
        leading: Container(
          width: 48,
          height: 48,
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
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.smart_toy,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Text(
              'Gemura Assistant',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacing4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Your AI assistant for milk collection',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Powered by AI • Always online',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          ),
          child: Icon(
            Icons.chat_bubble_outline,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        onTap: () {
          // TODO: Navigate to bot chat screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bot chat coming soon!'),
              backgroundColor: AppTheme.snackbarInfoColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: isSelected ? AppTheme.surfaceColor : AppTheme.primaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  List<ChatRoom> _getFilteredChats(List<ChatRoom> allChats, String category) {
    if (category == 'All') {
      return allChats;
    }
    
    return allChats.where((chat) {
      final chatName = chat.name.toLowerCase();
      final walletName = chat.wallet.name.toLowerCase();
      
      switch (category) {
        case 'Dairy':
          return chatName.contains('dairy') || walletName.contains('dairy');
        case 'Milk':
          return chatName.contains('milk') || walletName.contains('milk');
        case 'Cattle':
          return chatName.contains('cattle') || walletName.contains('cattle') ||
                 chatName.contains('feed') || walletName.contains('feed') ||
                 chatName.contains('health') || walletName.contains('health');
        case 'Training':
          return chatName.contains('training') || walletName.contains('training');
        default:
          return false;
      }
    }).toList();
  }

  int _getUnreadCount(List<ChatRoom> chats) {
    return chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  }

  void _showNewChatOptions() {
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
              'New Chat',
              style: AppTheme.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Options
            _buildNewChatOption(
              icon: Icons.group,
              title: 'New Group',
              subtitle: 'Create a group chat',
              onTap: _createNewGroup,
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildNewChatOption(
              icon: Icons.person_add,
              title: 'New Contact',
              subtitle: 'Add a new contact',
              onTap: _addNewContact,
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildNewChatOption(
              icon: Icons.qr_code_scanner,
              title: 'Scan QR Code',
              subtitle: 'Scan to join a chat',
              onTap: _scanQRCode,
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildNewChatOption(
              icon: Icons.share,
              title: 'Invite Friends',
              subtitle: 'Share app with friends',
              onTap: _inviteFriends,
            ),
            const SizedBox(height: AppTheme.spacing20),
          ],
        ),
      ),
    );
  }

  Widget _buildNewChatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewGroup() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New group functionality coming soon!'),
        backgroundColor: AppTheme.snackbarInfoColor,
      ),
    );
  }

  void _addNewContact() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new contact functionality coming soon!'),
        backgroundColor: AppTheme.snackbarInfoColor,
      ),
    );
  }

  void _scanQRCode() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR code scanning functionality coming soon!'),
        backgroundColor: AppTheme.snackbarInfoColor,
      ),
    );
  }

  void _inviteFriends() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite friends functionality coming soon!'),
        backgroundColor: AppTheme.snackbarInfoColor,
      ),
    );
  }
} 