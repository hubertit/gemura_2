import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../shared/models/notification.dart';
import 'authenticated_dio_service.dart';
import 'secure_storage_service.dart';

class NotificationService {
  final Dio _dio = AuthenticatedDioService.instance;

  // Get notifications with optional filtering
  Future<NotificationsResponse> getNotifications({
    int? accountId,
    String? status,
    String? type,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      print('🔔 NotificationService: Fetching notifications for accountId: $accountId');
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/notifications/get.php',
        data: {
          'token': token,
          'account_id': accountId,
          'status': status,
          'type': type,
          'category': category,
          'limit': limit,
          'offset': offset,
        },
      );

      print('🔔 NotificationService: Response received: ${response.data}');
      return NotificationsResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('🔔 NotificationService: Error fetching notifications: ${e.message}');
      throw _handleDioError(e);
    }
  }

  // Create a new notification
  Future<NotificationResponse> createNotification({
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
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/notifications/create.php',
        data: {
          'token': token,
          'title': title,
          'message': message,
          'type': type,
          'category': category,
          'action_url': actionUrl,
          'action_data': actionData,
          'expires_at': expiresAt,
          'user_id': userId,
          'account_id': accountId,
        },
      );

      return NotificationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Update notification status
  Future<NotificationResponse> updateNotification({
    required int notificationId,
    String? status,
    int? accountId,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/notifications/update.php',
        data: {
          'token': token,
          'notification_id': notificationId,
          'status': status,
          'account_id': accountId,
        },
      );

      return NotificationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Mark notification as read
  Future<NotificationResponse> markAsRead({
    required int notificationId,
    int? accountId,
  }) async {
    return updateNotification(
      notificationId: notificationId,
      status: 'read',
      accountId: accountId,
    );
  }

  // Mark notification as unread
  Future<NotificationResponse> markAsUnread({
    required int notificationId,
    int? accountId,
  }) async {
    return updateNotification(
      notificationId: notificationId,
      status: 'unread',
      accountId: accountId,
    );
  }

  // Archive notification
  Future<NotificationResponse> archiveNotification({
    required int notificationId,
    int? accountId,
  }) async {
    return updateNotification(
      notificationId: notificationId,
      status: 'archived',
      accountId: accountId,
    );
  }

  // Delete notification (soft delete)
  Future<NotificationResponse> deleteNotification({
    required int notificationId,
    int? accountId,
  }) async {
    try {
      final token = SecureStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/notifications/delete.php',
        data: {
          'token': token,
          'notification_id': notificationId,
          'account_id': accountId,
        },
      );

      return NotificationResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get unread count
  Future<int> getUnreadCount({int? accountId}) async {
    try {
      final response = await getNotifications(
        accountId: accountId,
        status: 'unread',
        limit: 1,
      );
      return response.data.unreadCount;
    } catch (e) {
      return 0;
    }
  }

  // Create business notifications
  Future<NotificationResponse> createCollectionNotification({
    required String supplierName,
    required double quantity,
    int? accountId,
  }) async {
    return createNotification(
      title: 'New Collection Recorded',
      message: 'Successfully recorded ${quantity}L milk collection from supplier $supplierName',
      type: 'success',
      category: 'business',
      actionUrl: '/collections',
      actionData: {
        'supplier_name': supplierName,
        'quantity': quantity,
      },
      accountId: accountId,
    );
  }

  Future<NotificationResponse> createSaleNotification({
    required String customerName,
    required double quantity,
    required double amount,
    int? accountId,
  }) async {
    return createNotification(
      title: 'Payment Received',
      message: 'Received payment of ${amount.toStringAsFixed(0)} Frw from customer $customerName',
      type: 'success',
      category: 'financial',
      actionUrl: '/sales',
      actionData: {
        'customer_name': customerName,
        'quantity': quantity,
        'amount': amount,
      },
      accountId: accountId,
    );
  }

  Future<NotificationResponse> createLowStockAlert({
    required double current,
    required double average,
    int? accountId,
  }) async {
    return createNotification(
      title: 'Low Stock Alert',
      message: 'Milk collection is below average for this week',
      type: 'warning',
      category: 'alert',
      actionUrl: '/overview',
      actionData: {
        'metric': 'collections',
        'current': current,
        'average': average,
      },
      accountId: accountId,
    );
  }

  Future<NotificationResponse> createPaymentOverdueNotification({
    required String customerName,
    required double amount,
    required int daysOverdue,
    int? accountId,
  }) async {
    return createNotification(
      title: 'Payment Overdue',
      message: 'Payment of ${amount.toStringAsFixed(0)} Frw is overdue from customer $customerName',
      type: 'error',
      category: 'financial',
      actionUrl: '/sales',
      actionData: {
        'customer_name': customerName,
        'amount': amount,
        'days_overdue': daysOverdue,
      },
      accountId: accountId,
    );
  }

  Exception _handleDioError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      return Exception(data['message'] ?? 'An error occurred');
    }
    return Exception('Network error: ${e.message}');
  }
}
