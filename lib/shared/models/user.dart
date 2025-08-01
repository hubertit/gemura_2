class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String about;
  final String profilePicture;
  final String profileCover;
  final String phoneNumber;
  final String address;
  final String profileImg;
  final String coverImg;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.about = '',
    this.address = '',
    this.profilePicture = '',
    this.profileImg = '',
    this.profileCover = '',
    this.coverImg = '',
    this.phoneNumber = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'about': about,
      'address': address,
      'profilePicture': profilePicture,
      'profileImg': profileImg,
      'profileCover': profileCover,
      'coverImg': coverImg,
      'phoneNumber': phoneNumber,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'].toString()) 
          : null,
      isActive: json['isActive'] as bool? ?? true,
      about: json['about']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      profilePicture: json['profilePicture']?.toString() ?? '',
      profileImg: json['profile_img']?.toString() ?? '',
      profileCover: json['profileCover']?.toString() ?? '',
      coverImg: json['cover_img']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone']?.toString() ?? '',
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? about,
    String? address,
    String? profilePicture,
    String? profileImg,
    String? profileCover,
    String? coverImg,
    String? phoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      about: about ?? this.about,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      profileImg: profileImg ?? this.profileImg,
      profileCover: profileCover ?? this.profileCover,
      coverImg: coverImg ?? this.coverImg,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 