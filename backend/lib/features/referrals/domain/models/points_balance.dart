class PointsBalance {
  final UserInfo userInfo;
  final List<PointsBreakdown> pointsBreakdown;
  final List<RecentActivity> recentActivities;

  const PointsBalance({
    required this.userInfo,
    required this.pointsBreakdown,
    required this.recentActivities,
  });

  factory PointsBalance.fromJson(Map<String, dynamic> json) {
    return PointsBalance(
      userInfo: UserInfo.fromJson(json['user_info'] ?? {}),
      pointsBreakdown: (json['points_breakdown'] as List<dynamic>?)
          ?.map((item) => PointsBreakdown.fromJson(item))
          .toList() ?? [],
      recentActivities: (json['recent_activities'] as List<dynamic>?)
          ?.map((item) => RecentActivity.fromJson(item))
          .toList() ?? [],
    );
  }
}

class UserInfo {
  final String name;
  final int totalPoints;
  final int availablePoints;
  final int referralCount;
  final int onboardedCount;
  final int leaderboardPosition;

  const UserInfo({
    required this.name,
    required this.totalPoints,
    required this.availablePoints,
    required this.referralCount,
    required this.onboardedCount,
    required this.leaderboardPosition,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      name: json['name'] ?? '',
      totalPoints: int.tryParse(json['total_points']?.toString() ?? '0') ?? 0,
      availablePoints: int.tryParse(json['available_points']?.toString() ?? '0') ?? 0,
      referralCount: int.tryParse(json['referral_count']?.toString() ?? '0') ?? 0,
      onboardedCount: int.tryParse(json['onboarded_count']?.toString() ?? '0') ?? 0,
      leaderboardPosition: int.tryParse(json['leaderboard_position']?.toString() ?? '0') ?? 0,
    );
  }
}

class PointsBreakdown {
  final String source;
  final int points;
  final int activities;

  const PointsBreakdown({
    required this.source,
    required this.points,
    required this.activities,
  });

  factory PointsBreakdown.fromJson(Map<String, dynamic> json) {
    return PointsBreakdown(
      source: json['source'] ?? '',
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      activities: int.tryParse(json['activities']?.toString() ?? '0') ?? 0,
    );
  }
}

class RecentActivity {
  final int points;
  final String source;
  final String description;
  final String date;

  const RecentActivity({
    required this.points,
    required this.source,
    required this.description,
    required this.date,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      source: json['source'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
    );
  }
}
