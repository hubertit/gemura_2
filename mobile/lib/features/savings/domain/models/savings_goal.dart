class SavingsGoal {
  final String id;
  final String name;
  final String description;
  final double currentAmount;
  final double targetAmount;
  final String currency;
  final DateTime targetDate;
  final DateTime createdAt;
  final bool isActive;
  final List<String> contributors;
  final String? walletId; // Associated wallet ID

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.currentAmount,
    required this.targetAmount,
    required this.currency,
    required this.targetDate,
    required this.createdAt,
    this.isActive = true,
    this.contributors = const [],
    this.walletId,
  });

  double get progressPercentage => (currentAmount / targetAmount) * 100;
  double get remainingAmount => targetAmount - currentAmount;
  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;
  double get dailyRequiredAmount => daysRemaining > 0 ? remainingAmount / daysRemaining : 0;

  SavingsGoal copyWith({
    String? id,
    String? name,
    String? description,
    double? currentAmount,
    double? targetAmount,
    String? currency,
    DateTime? targetDate,
    DateTime? createdAt,
    bool? isActive,
    List<String>? contributors,
    String? walletId,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currentAmount: currentAmount ?? this.currentAmount,
      targetAmount: targetAmount ?? this.targetAmount,
      currency: currency ?? this.currency,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      contributors: contributors ?? this.contributors,
      walletId: walletId ?? this.walletId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'currentAmount': currentAmount,
      'targetAmount': targetAmount,
      'currency': currency,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'contributors': contributors,
      'walletId': walletId,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      targetDate: DateTime.parse(json['targetDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      contributors: List<String>.from(json['contributors'] ?? []),
      walletId: json['walletId'] as String?,
    );
  }
} 