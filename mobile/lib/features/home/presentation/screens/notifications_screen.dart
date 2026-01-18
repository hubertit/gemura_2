import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../shared/models/notification.dart' as notification_model;
import '../../../../core/providers/localization_provider.dart';
import '../providers/user_accounts_provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizationService = ref.watch(localizationServiceProvider);
    final userInfo = ref.watch(userAccountsProvider);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: localizationService.translate('notifications'),
      ),
      body: userInfo.when(
        data: (user) {
          // Notifications don't use accountId in NestJS backend, pass null
          final notificationsAsync = ref.watch(notificationsNotifierProvider(null));
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsNotifierProvider(null));
            },
            child: notificationsAsync.when(
              data: (response) {
                final notifications = response.data.notifications;
                
                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: AppTheme.textHintColor,
                        ),
                        const SizedBox(height: AppTheme.spacing16),
                        Consumer(
                          builder: (context, ref, child) {
                            final localizationService = ref.watch(localizationServiceProvider);
                            return Text(
                              localizationService.translate('noNotifications'),
                              style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondaryColor),
                            );
                          },
                        ),
                        const SizedBox(height: AppTheme.spacing8),
                        Consumer(
                          builder: (context, ref, child) {
                            final localizationService = ref.watch(localizationServiceProvider);
                            return Text(
                              localizationService.translate('notificationsWillAppearHere'),
                              style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing4,
                  ),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing8),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationCard(
                      notification: notification,
                      accountId: null, // Notifications don't use accountId in NestJS backend
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Consumer(
                      builder: (context, ref, child) {
                        final localizationService = ref.watch(localizationServiceProvider);
                        return Text(
                          localizationService.translate('failedToLoadNotifications'),
                          style: AppTheme.titleMedium.copyWith(color: AppTheme.errorColor),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      error.toString(),
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textHintColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Failed to load user info',
                style: AppTheme.titleMedium.copyWith(color: AppTheme.errorColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final notification_model.Notification notification;
  final int? accountId;

  const _NotificationCard({
    required this.notification,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(notification.id),
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
      onDismissed: (_) {
        ref.read(notificationsNotifierProvider(accountId).notifier)
           .deleteNotification(notification.id, accountId: accountId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead ? AppTheme.backgroundColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
          border: Border.all(
            color: notification.isRead 
                ? AppTheme.thinBorderColor 
                : _getTypeColor(notification.type).withOpacity(0.2),
            width: AppTheme.thinBorderWidth,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppTheme.spacing12),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: notification.isRead 
                  ? AppTheme.textHintColor.withOpacity(0.1)
                  : _getTypeColor(notification.type).withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
            ),
            child: Icon(
              notification.isRead ? Icons.notifications_none : Icons.notifications_active,
              color: notification.isRead ? AppTheme.textSecondaryColor : _getTypeColor(notification.type),
              size: 24,
            ),
          ),
          title: Text(
            notification.title,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
              color: notification.isRead ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacing4),
              Text(
                notification.message,
                style: AppTheme.bodySmall.copyWith(
                  color: notification.isRead ? AppTheme.textHintColor : AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing8,
                      vertical: AppTheme.spacing2,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                    ),
                    child: Text(
                      notification.type.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: _getTypeColor(notification.type),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    _formatDate(notification.createdAt),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textHintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                notification.isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              tooltip: notification.isRead ? 'Mark as unread' : 'Mark as read',
              onPressed: () {
                if (notification.isRead) {
                  ref.read(notificationsNotifierProvider(accountId).notifier)
                     .markAsUnread(notification.id, accountId: accountId);
                } else {
                  ref.read(notificationsNotifierProvider(accountId).notifier)
                     .markAsRead(notification.id, accountId: accountId);
                }
              },
            ),
          ),
          onTap: () {
            if (!notification.isRead) {
              ref.read(notificationsNotifierProvider(accountId).notifier)
                 .markAsRead(notification.id, accountId: accountId);
            }
            
            // Handle action URL if present
            if (notification.actionUrl != null) {
              // TODO: Navigate to the action URL
              print('Navigate to: ${notification.actionUrl}');
            }
          },
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return AppTheme.errorColor;
      case 'info':
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hr ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return 'Unknown date';
    }
  }
} 