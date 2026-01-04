class ReferralStats {
  final UserInfo userInfo;
  final Statistics statistics;
  final List<RecentReferral> recentReferrals;
  final List<PointsHistory> pointsHistory;

  const ReferralStats({
    required this.userInfo,
    required this.statistics,
    required this.recentReferrals,
    required this.pointsHistory,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      userInfo: UserInfo.fromJson(json['user_info'] ?? {}),
      statistics: Statistics.fromJson(json['statistics'] ?? {}),
      recentReferrals: (json['recent_referrals'] as List<dynamic>?)
          ?.map((item) => RecentReferral.fromJson(item))
          .toList() ?? [],
      pointsHistory: (json['points_history'] as List<dynamic>?)
          ?.map((item) => PointsHistory.fromJson(item))
          .toList() ?? [],
    );
  }
}

class UserInfo {
  final String name;
  final String referralCode;
  final int totalPoints;
  final int availablePoints;

  const UserInfo({
    required this.name,
    required this.referralCode,
    required this.totalPoints,
    required this.availablePoints,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      name: json['name'] ?? '',
      referralCode: json['referral_code'] ?? '',
      totalPoints: int.tryParse(json['total_points']?.toString() ?? '0') ?? 0,
      availablePoints: int.tryParse(json['available_points']?.toString() ?? '0') ?? 0,
    );
  }
}

class Statistics {
  final int totalReferrals;
  final int recentWeek;
  final int recentMonth;
  final int recentQuarter;

  const Statistics({
    required this.totalReferrals,
    required this.recentWeek,
    required this.recentMonth,
    required this.recentQuarter,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalReferrals: int.tryParse(json['total_referrals']?.toString() ?? '0') ?? 0,
      recentWeek: int.tryParse(json['recent_week']?.toString() ?? '0') ?? 0,
      recentMonth: int.tryParse(json['recent_month']?.toString() ?? '0') ?? 0,
      recentQuarter: int.tryParse(json['recent_quarter']?.toString() ?? '0') ?? 0,
    );
  }
}

class RecentReferral {
  final String id;
  final String name;
  final String phone;
  final String createdAt;

  const RecentReferral({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  factory RecentReferral.fromJson(Map<String, dynamic> json) {
    return RecentReferral(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class PointsHistory {
  final int points;
  final String source;
  final String description;
  final String earnedAt;

  const PointsHistory({
    required this.points,
    required this.source,
    required this.description,
    required this.earnedAt,
  });

  factory PointsHistory.fromJson(Map<String, dynamic> json) {
    return PointsHistory(
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      source: json['source'] ?? '',
      description: json['description'] ?? '',
      earnedAt: json['earned_at'] ?? '',
    );
  }
}
