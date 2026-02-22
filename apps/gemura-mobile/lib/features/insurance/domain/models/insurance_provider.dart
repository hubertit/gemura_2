class InsuranceProvider {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final String website;
  final String phone;
  final String email;
  final String address;
  final List<String> supportedTypes;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InsuranceProvider({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.website,
    required this.phone,
    required this.email,
    required this.address,
    required this.supportedTypes,
    required this.rating,
    required this.reviewCount,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  String get displayRating => rating.toStringAsFixed(1);
  String get displayReviewCount => '$reviewCount reviews';

  InsuranceProvider copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? website,
    String? phone,
    String? email,
    String? address,
    List<String>? supportedTypes,
    double? rating,
    int? reviewCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InsuranceProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      supportedTypes: supportedTypes ?? this.supportedTypes,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'website': website,
      'phone': phone,
      'email': email,
      'address': address,
      'supportedTypes': supportedTypes,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory InsuranceProvider.fromJson(Map<String, dynamic> json) {
    return InsuranceProvider(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      logoUrl: json['logoUrl'],
      website: json['website'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      supportedTypes: List<String>.from(json['supportedTypes']),
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }
} 