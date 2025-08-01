import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.read = false,
  });
}

final notificationsProvider = StateNotifierProvider<_NotificationsNotifier, List<NotificationItem>>((ref) {
  return _NotificationsNotifier();
});

class _NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  _NotificationsNotifier() : super(_mockNotifications);

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) NotificationItem(
          id: n.id,
          title: n.title,
          body: n.body,
          date: n.date,
          read: true,
        ) else n
    ];
  }

  void markAsUnread(String id) {
    state = [
      for (final n in state)
        if (n.id == id) NotificationItem(
          id: n.id,
          title: n.title,
          body: n.body,
          date: n.date,
          read: false,
        ) else n
    ];
  }

  void delete(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final List<NotificationItem> _mockNotifications = [
  NotificationItem(
    id: '1',
    title: 'Welcome to Gemura!',
    body: 'Thank you for joining. Manage your finances with ease.',
    date: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  NotificationItem(
    id: '2',
    title: 'Transaction Complete',
    body: 'Your recent transaction was successful.',
    date: DateTime.now().subtract(const Duration(days: 1)),
    read: true,
  ),
  NotificationItem(
    id: '3',
    title: 'Security Alert',
    body: 'A new device was used to sign in to your account.',
    date: DateTime.now().subtract(const Duration(hours: 3)),
  ),
];

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimaryColor),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppTheme.textHintColor,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text(
                    'No notifications yet',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'Your notifications will appear here.',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing8,
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing12),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                    ),
                    child: const Icon(Icons.delete, color: AppTheme.errorColor),
                  ),
                  onDismissed: (_) => ref.read(notificationsProvider.notifier).delete(n.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: n.read ? AppTheme.backgroundColor : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      border: Border.all(
                        color: n.read ? AppTheme.thinBorderColor : AppTheme.primaryColor.withOpacity(0.2),
                        width: AppTheme.thinBorderWidth,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(AppTheme.spacing12),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: n.read 
                              ? AppTheme.textHintColor.withOpacity(0.1)
                              : AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                        child: Icon(
                          n.read ? Icons.notifications_none : Icons.notifications_active,
                          color: n.read ? AppTheme.textSecondaryColor : AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: n.read ? FontWeight.w400 : FontWeight.w600,
                          color: n.read ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            n.body,
                            style: AppTheme.bodySmall.copyWith(
                              color: n.read ? AppTheme.textHintColor : AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            _formatDate(n.date),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textHintColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            n.read ? Icons.mark_email_unread : Icons.mark_email_read,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          tooltip: n.read ? 'Mark as unread' : 'Mark as read',
                          onPressed: () {
                            if (n.read) {
                              ref.read(notificationsProvider.notifier).markAsUnread(n.id);
                            } else {
                              ref.read(notificationsProvider.notifier).markAsRead(n.id);
                            }
                          },
                        ),
                      ),
                      onTap: () {
                        if (!n.read) {
                          ref.read(notificationsProvider.notifier).markAsRead(n.id);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours} hr ago';
  } else {
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }
} 