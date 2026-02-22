class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final List<String>? attachments;
  final String? replyToMessageId;
  final String? replyToMessageContent;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
    this.attachments,
    this.replyToMessageId,
    this.replyToMessageContent,
  });

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    List<String>? attachments,
    String? replyToMessageId,
    String? replyToMessageContent,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessageContent: replyToMessageContent ?? this.replyToMessageContent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'attachments': attachments,
      'replyToMessageId': replyToMessageId,
      'replyToMessageContent': replyToMessageContent,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderAvatar: json['senderAvatar']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments'])
          : null,
      replyToMessageId: json['replyToMessageId']?.toString(),
      replyToMessageContent: json['replyToMessageContent']?.toString(),
    );
  }
}

enum MessageType {
  text,
  image,
  file,
  payment,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
} 