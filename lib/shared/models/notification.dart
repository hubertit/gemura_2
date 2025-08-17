import 'dart:convert';

class Notification {
  final int id;
  final int userId;
  final int accountId;
  final String title;
  final String message;
  final String type;
  final String category;
  final String? actionUrl;
  final Map<String, dynamic>? actionData;
  final String? expiresAt;
  final String createdAt;
  final String updatedAt;
  final String status;

  Notification({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    this.actionUrl,
    this.actionData,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['user_id'],
      accountId: json['account_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      category: json['category'],
      actionUrl: json['action_url'],
      actionData: json['action_data'] != null 
          ? (json['action_data'] is String 
              ? jsonDecode(json['action_data']) 
              : json['action_data'])
          : null,
      expiresAt: json['expires_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'title': title,
      'message': message,
      'type': type,
      'category': category,
      'action_url': actionUrl,
      'action_data': actionData != null ? jsonEncode(actionData) : null,
      'expires_at': expiresAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'status': status,
    };
  }

  bool get isRead => status == 'read';
  bool get isUnread => status == 'unread';
  bool get isArchived => status == 'archived';
  bool get isDeleted => status == 'deleted';

  Notification copyWith({
    int? id,
    int? userId,
    int? accountId,
    String? title,
    String? message,
    String? type,
    String? category,
    String? actionUrl,
    Map<String, dynamic>? actionData,
    String? expiresAt,
    String? createdAt,
    String? updatedAt,
    String? status,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      actionUrl: actionUrl ?? this.actionUrl,
      actionData: actionData ?? this.actionData,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}

class NotificationsResponse {
  final bool success;
  final String message;
  final NotificationsData data;

  NotificationsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      success: json['code'] == 200,
      message: json['message'] ?? '',
      data: NotificationsData.fromJson(json['data']),
    );
  }
}

class NotificationsData {
  final List<Notification> notifications;
  final int totalCount;
  final int unreadCount;
  final int limit;
  final int offset;

  NotificationsData({
    required this.notifications,
    required this.totalCount,
    required this.unreadCount,
    required this.limit,
    required this.offset,
  });

  factory NotificationsData.fromJson(Map<String, dynamic> json) {
    return NotificationsData(
      notifications: (json['notifications'] as List)
          .map((notification) => Notification.fromJson(notification))
          .toList(),
      totalCount: json['total_count'],
      unreadCount: json['unread_count'],
      limit: json['limit'],
      offset: json['offset'],
    );
  }
}

class NotificationResponse {
  final bool success;
  final String message;
  final Notification? data;

  NotificationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['code'] == 200,
      message: json['message'] ?? '',
      data: json['data'] != null ? Notification.fromJson(json['data']) : null,
    );
  }
}
