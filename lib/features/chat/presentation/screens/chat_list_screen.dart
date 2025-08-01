import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

import '../providers/chat_provider.dart';
import '../../domain/models/chat_room.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(activeChatsProvider);
    final chatStats = ref.watch(chatStatsProvider);

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
            onPressed: () {
              // TODO: Implement menu options
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                    '${chatStats['totalChats']} groups • ${chatStats['totalUnreadMessages']} unread',
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
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
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
} 