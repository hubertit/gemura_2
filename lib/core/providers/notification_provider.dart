import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../../shared/models/notification.dart';
import '../../features/home/presentation/providers/user_accounts_provider.dart';

// Service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Notifications provider
final notificationsProvider = FutureProvider.family<NotificationsResponse, int?>((ref, accountId) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getNotifications(accountId: accountId);
});

// Unread count provider
final unreadCountProvider = FutureProvider.family<int, int?>((ref, accountId) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getUnreadCount(accountId: accountId);
});

// Notification state notifier
class NotificationsNotifier extends StateNotifier<AsyncValue<NotificationsResponse>> {
  final NotificationService _service;
  final Ref _ref;

  NotificationsNotifier(this._service, this._ref) : super(const AsyncValue.loading());

  Future<void> loadNotifications({int? accountId}) async {
    print('🔔 NotificationsNotifier: Loading notifications for accountId: $accountId');
    state = const AsyncValue.loading();
    try {
      final response = await _service.getNotifications(accountId: accountId);
      print('🔔 NotificationsNotifier: Notifications loaded successfully');
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      print('🔔 NotificationsNotifier: Error loading notifications: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshNotifications({int? accountId}) async {
    try {
      final response = await _service.getNotifications(accountId: accountId);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAsRead(int notificationId, {int? accountId}) async {
    try {
      await _service.markAsRead(notificationId: notificationId, accountId: accountId);
      // Refresh notifications after marking as read
      await refreshNotifications(accountId: accountId);
      // Invalidate unread count
      _ref.invalidate(unreadCountProvider(accountId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAsUnread(int notificationId, {int? accountId}) async {
    try {
      await _service.markAsUnread(notificationId: notificationId, accountId: accountId);
      await refreshNotifications(accountId: accountId);
      _ref.invalidate(unreadCountProvider(accountId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> archiveNotification(int notificationId, {int? accountId}) async {
    try {
      await _service.archiveNotification(notificationId: notificationId, accountId: accountId);
      await refreshNotifications(accountId: accountId);
      _ref.invalidate(unreadCountProvider(accountId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteNotification(int notificationId, {int? accountId}) async {
    try {
      await _service.deleteNotification(notificationId: notificationId, accountId: accountId);
      await refreshNotifications(accountId: accountId);
      _ref.invalidate(unreadCountProvider(accountId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createNotification({
    required String title,
    required String message,
    String type = 'info',
    String category = 'general',
    String? actionUrl,
    Map<String, dynamic>? actionData,
    String? expiresAt,
    int? userId,
    int? accountId,
  }) async {
    try {
      await _service.createNotification(
        title: title,
        message: message,
        type: type,
        category: category,
        actionUrl: actionUrl,
        actionData: actionData,
        expiresAt: expiresAt,
        userId: userId,
        accountId: accountId,
      );
      // Refresh notifications after creating
      await refreshNotifications(accountId: accountId);
      _ref.invalidate(unreadCountProvider(accountId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Business notification helpers
  Future<void> createCollectionNotification({
    required String supplierName,
    required double quantity,
    int? accountId,
  }) async {
    try {
      await _service.createCollectionNotification(
        supplierName: supplierName,
        quantity: quantity,
        accountId: accountId,
      );
      await refreshNotifications(accountId: accountId);
      _ref.invalidate(unreadCountProvider(accountId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createSaleNotification({
    required String customerName,
    required double quantity,
    required double amount,
    int? accountId,
  }) async {
    try {
      await _service.createSaleNotification(
        customerName: customerName,
        quantity: quantity,
        amount: amount,
        accountId: accountId,
      );
      await refreshNotifications(accountId: accountId);
      _ref.invalidate(unreadCountProvider(accountId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createLowStockAlert({
    required double current,
    required double average,
    int? accountId,
  }) async {
    try {
      await _service.createLowStockAlert(
        current: current,
        average: average,
        accountId: accountId,
      );
      await refreshNotifications(accountId: accountId);
      _ref.invalidate(unreadCountProvider(accountId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createPaymentOverdueNotification({
    required String customerName,
    required double amount,
    required int daysOverdue,
    int? accountId,
  }) async {
    try {
      await _service.createPaymentOverdueNotification(
        customerName: customerName,
        amount: amount,
        daysOverdue: daysOverdue,
        accountId: accountId,
      );
      await refreshNotifications(accountId: accountId);
      _ref.invalidate(unreadCountProvider(accountId));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Notifications notifier provider
final notificationsNotifierProvider = StateNotifierProvider.family<NotificationsNotifier, AsyncValue<NotificationsResponse>, int?>((ref, accountId) {
  final service = ref.read(notificationServiceProvider);
  final notifier = NotificationsNotifier(service, ref);
  // Load notifications when the provider is created
  if (accountId != null) {
    notifier.loadNotifications(accountId: accountId);
  }
  return notifier;
});

// Filtered notifications provider
final filteredNotificationsProvider = Provider.family<List<Notification>, ({int? accountId, String? status, String? type, String? category})>((ref, params) {
  final notificationsAsync = ref.watch(notificationsNotifierProvider(params.accountId));
  
  return notificationsAsync.when(
    data: (response) {
      List<Notification> notifications = response.data.notifications;
      
      if (params.status != null) {
        notifications = notifications.where((n) => n.status == params.status).toList();
      }
      
      if (params.type != null) {
        notifications = notifications.where((n) => n.type == params.type).toList();
      }
      
      if (params.category != null) {
        notifications = notifications.where((n) => n.category == params.category).toList();
      }
      
      return notifications;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Unread notifications provider
final unreadNotificationsProvider = Provider.family<List<Notification>, int?>((ref, accountId) {
  return ref.watch(filteredNotificationsProvider((
    accountId: accountId,
    status: 'unread',
    type: null,
    category: null,
  )));
});

// Read notifications provider
final readNotificationsProvider = Provider.family<List<Notification>, int?>((ref, accountId) {
  return ref.watch(filteredNotificationsProvider((
    accountId: accountId,
    status: 'read',
    type: null,
    category: null,
  )));
});
