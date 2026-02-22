class ReferralCode {
  final String userId;
  final String userName;
  final String referralCode;
  final int totalReferrals;
  final int recentReferrals;
  final int totalPoints;
  final String referralUrl;

  const ReferralCode({
    required this.userId,
    required this.userName,
    required this.referralCode,
    required this.totalReferrals,
    required this.recentReferrals,
    required this.totalPoints,
    required this.referralUrl,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name'] ?? '',
      referralCode: json['referral_code'] ?? '',
      totalReferrals: int.tryParse(json['total_referrals']?.toString() ?? '0') ?? 0,
      recentReferrals: int.tryParse(json['recent_referrals']?.toString() ?? '0') ?? 0,
      totalPoints: int.tryParse(json['total_points']?.toString() ?? '0') ?? 0,
      referralUrl: json['referral_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'referral_code': referralCode,
      'total_referrals': totalReferrals,
      'recent_referrals': recentReferrals,
      'total_points': totalPoints,
      'referral_url': referralUrl,
    };
  }
}
