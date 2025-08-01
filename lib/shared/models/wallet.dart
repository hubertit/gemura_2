class Wallet {
  final String id;
  final String name;
  final double balance;
  final String currency;
  final String type; // 'individual' or 'joint'
  final String status; // 'active', 'inactive'
  final DateTime createdAt;
  final List<String> owners;
  final bool isDefault;
  final String? description;
  final double? targetAmount;
  final DateTime? targetDate;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.owners,
    this.isDefault = false,
    this.description,
    this.targetAmount,
    this.targetDate,
  });

  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    String? currency,
    String? type,
    String? status,
    DateTime? createdAt,
    List<String>? owners,
    bool? isDefault,
    String? description,
    double? targetAmount,
    DateTime? targetDate,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      owners: owners ?? this.owners,
      isDefault: isDefault ?? this.isDefault,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'currency': currency,
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'owners': owners,
      'isDefault': isDefault,
      'description': description,
      'targetAmount': targetAmount,
      'targetDate': targetDate?.toIso8601String(),
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      owners: json['owners'] != null 
          ? List<String>.from(json['owners'])
          : [],
      isDefault: json['isDefault'] as bool? ?? false,
      description: json['description']?.toString(),
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      targetDate: json['targetDate'] != null 
          ? DateTime.parse(json['targetDate'].toString())
          : null,
    );
  }
} 