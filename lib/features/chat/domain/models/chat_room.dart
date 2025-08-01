import '../../../../shared/models/wallet.dart';

class ChatRoom {
  final String id;
  final String name;
  final String description;
  final String walletId;
  final Wallet wallet;
  final List<ChatMember> members;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessageContent;
  final String? lastMessageSender;
  final int unreadCount;
  final bool isActive;
  final String? groupAvatar;

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.walletId,
    required this.wallet,
    required this.members,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessageContent,
    this.lastMessageSender,
    this.unreadCount = 0,
    this.isActive = true,
    this.groupAvatar,
  });

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    String? walletId,
    Wallet? wallet,
    List<ChatMember>? members,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessageContent,
    String? lastMessageSender,
    int? unreadCount,
    bool? isActive,
    String? groupAvatar,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      walletId: walletId ?? this.walletId,
      wallet: wallet ?? this.wallet,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      groupAvatar: groupAvatar ?? this.groupAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'walletId': walletId,
      'wallet': wallet,
      'members': members.map((member) => member.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessageContent': lastMessageContent,
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'groupAvatar': groupAvatar,
    };
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      walletId: json['walletId']?.toString() ?? '',
      wallet: Wallet.fromJson(json['wallet'] ?? {}),
      members: json['members'] != null 
          ? (json['members'] as List)
              .map((member) => ChatMember.fromJson(member))
              .toList()
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt'].toString())
          : null,
      lastMessageContent: json['lastMessageContent']?.toString(),
      lastMessageSender: json['lastMessageSender']?.toString(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      groupAvatar: json['groupAvatar']?.toString(),
    );
  }
}

class ChatMember {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String role; // 'owner', 'admin', 'member'
  final DateTime joinedAt;
  final bool isOnline;
  final DateTime? lastSeenAt;

  ChatMember({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.role,
    required this.joinedAt,
    this.isOnline = false,
    this.lastSeenAt,
  });

  ChatMember copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? role,
    DateTime? joinedAt,
    bool? isOnline,
    DateTime? lastSeenAt,
  }) {
    return ChatMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'isOnline': isOnline,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }

  factory ChatMember.fromJson(Map<String, dynamic> json) {
    return ChatMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      joinedAt: json['joinedAt'] != null 
          ? DateTime.parse(json['joinedAt'].toString())
          : DateTime.now(),
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAt: json['lastSeenAt'] != null 
          ? DateTime.parse(json['lastSeenAt'].toString())
          : null,
    );
  }
} 