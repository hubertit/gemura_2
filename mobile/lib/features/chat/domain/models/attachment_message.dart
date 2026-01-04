

enum AttachmentType {
  image,
  document,
  contact,
}

class AttachmentMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final AttachmentType type;
  final String? caption;
  final DateTime timestamp;
  final List<Attachment> attachments;

  AttachmentMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    this.caption,
    required this.timestamp,
    required this.attachments,
  });

  AttachmentMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    AttachmentType? type,
    String? caption,
    DateTime? timestamp,
    List<Attachment>? attachments,
  }) {
    return AttachmentMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      caption: caption ?? this.caption,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type.toString(),
      'caption': caption,
      'timestamp': timestamp.toIso8601String(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  factory AttachmentMessage.fromJson(Map<String, dynamic> json) {
    return AttachmentMessage(
      id: json['id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderAvatar: json['senderAvatar']?.toString(),
      type: AttachmentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AttachmentType.image,
      ),
      caption: json['caption']?.toString(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      attachments: json['attachments'] != null 
          ? (json['attachments'] as List)
              .map((a) => Attachment.fromJson(a))
              .toList()
          : [],
    );
  }
}

class Attachment {
  final String id;
  final String name;
  final String path;
  final AttachmentType type;
  final int size;
  final String? thumbnailPath;
  final Map<String, dynamic>? metadata;

  Attachment({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    this.thumbnailPath,
    this.metadata,
  });

  Attachment copyWith({
    String? id,
    String? name,
    String? path,
    AttachmentType? type,
    int? size,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
  }) {
    return Attachment(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type.toString(),
      'size': size,
      'thumbnailPath': thumbnailPath,
      'metadata': metadata,
    };
  }

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      type: AttachmentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AttachmentType.image,
      ),
      size: json['size'] as int? ?? 0,
      thumbnailPath: json['thumbnailPath']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Helper methods
  bool get isImage => type == AttachmentType.image;
  bool get isDocument => type == AttachmentType.document;
  bool get isContact => type == AttachmentType.contact;
  
  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
} 