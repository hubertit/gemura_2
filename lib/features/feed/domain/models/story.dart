import 'package:json_annotation/json_annotation.dart';

part 'story.g.dart';

@JsonSerializable()
class Story {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isViewed;
  final bool isVerified;

  const Story({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
    this.isVerified = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
  Map<String, dynamic> toJson() => _$StoryToJson(this);

  Story copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? imageUrl,
    String? videoUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isViewed,
    bool? isVerified,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isViewed: isViewed ?? this.isViewed,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
