class OnboardedUser {
  final OnboardedUserData onboardedUser;
  final Onboarder onboarder;
  final String onboardedAt;

  const OnboardedUser({
    required this.onboardedUser,
    required this.onboarder,
    required this.onboardedAt,
  });

  factory OnboardedUser.fromJson(Map<String, dynamic> json) {
    return OnboardedUser(
      onboardedUser: OnboardedUserData.fromJson(json['onboarded_user'] ?? {}),
      onboarder: Onboarder.fromJson(json['onboarder'] ?? {}),
      onboardedAt: json['onboarded_at'] ?? '',
    );
  }
}

class OnboardedUserData {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? location;
  final String token;
  final String createdAt;

  const OnboardedUserData({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.location,
    required this.token,
    required this.createdAt,
  });

  factory OnboardedUserData.fromJson(Map<String, dynamic> json) {
    return OnboardedUserData(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'],
      location: json['location'],
      token: json['token'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Onboarder {
  final String name;
  final int pointsEarned;

  const Onboarder({
    required this.name,
    required this.pointsEarned,
  });

  factory Onboarder.fromJson(Map<String, dynamic> json) {
    return Onboarder(
      name: json['name'] ?? '',
      pointsEarned: int.tryParse(json['points_earned']?.toString() ?? '0') ?? 0,
    );
  }
}
