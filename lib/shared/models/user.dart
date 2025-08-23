class User {
  final String id;
  final String name;
  final String? email;
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
  final String accountCode;
  
  // KYC Fields
  final String? province;
  final String? district;
  final String? sector;
  final String? cell;
  final String? village;
  final String? idNumber;
  final String? idFrontPhotoUrl;
  final String? idBackPhotoUrl;
  final String? selfiePhotoUrl;
  final String? kycStatus;
  final DateTime? kycVerifiedAt;

  User({
    required this.id,
    required this.name,
    this.email,
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
    this.accountCode = '',
    // KYC Fields
    this.province,
    this.district,
    this.sector,
    this.cell,
    this.village,
    this.idNumber,
    this.idFrontPhotoUrl,
    this.idBackPhotoUrl,
    this.selfiePhotoUrl,
    this.kycStatus,
    this.kycVerifiedAt,
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
      'accountCode': accountCode,
      // KYC Fields
      'province': province,
      'district': district,
      'sector': sector,
      'cell': cell,
      'village': village,
      'id_number': idNumber,
      'id_front_photo_url': idFrontPhotoUrl,
      'id_back_photo_url': idBackPhotoUrl,
      'selfie_photo_url': selfiePhotoUrl,
      'kyc_status': kycStatus,
      'kyc_verified_at': kycVerifiedAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : (json['created_at'] != null 
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now()),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'].toString()) 
          : (json['last_login_at'] != null 
              ? DateTime.parse(json['last_login_at'].toString())
              : null),
      isActive: json['isActive'] as bool? ?? (json['status']?.toString() == 'active'),
      about: json['about']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      profilePicture: json['profilePicture']?.toString() ?? json['profile_picture']?.toString() ?? '',
      profileImg: json['profile_img']?.toString() ?? '',
      profileCover: json['profileCover']?.toString() ?? json['profile_cover']?.toString() ?? '',
      coverImg: json['cover_img']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone']?.toString() ?? '',
      accountCode: json['accountCode']?.toString() ?? json['account_code']?.toString() ?? '',
      // KYC Fields
      province: json['province']?.toString(),
      district: json['district']?.toString(),
      sector: json['sector']?.toString(),
      cell: json['cell']?.toString(),
      village: json['village']?.toString(),
      idNumber: json['id_number']?.toString(),
      idFrontPhotoUrl: json['id_front_photo_url']?.toString(),
      idBackPhotoUrl: json['id_back_photo_url']?.toString(),
      selfiePhotoUrl: json['selfie_photo_url']?.toString(),
      kycStatus: json['kyc_status']?.toString(),
      kycVerifiedAt: json['kyc_verified_at'] != null 
          ? DateTime.parse(json['kyc_verified_at'].toString()) 
          : null,
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
    String? accountCode,
    // KYC Fields
    String? province,
    String? district,
    String? sector,
    String? cell,
    String? village,
    String? idNumber,
    String? idFrontPhotoUrl,
    String? idBackPhotoUrl,
    String? selfiePhotoUrl,
    String? kycStatus,
    DateTime? kycVerifiedAt,
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
      accountCode: accountCode ?? this.accountCode,
      // KYC Fields
      province: province ?? this.province,
      district: district ?? this.district,
      sector: sector ?? this.sector,
      cell: cell ?? this.cell,
      village: village ?? this.village,
      idNumber: idNumber ?? this.idNumber,
      idFrontPhotoUrl: idFrontPhotoUrl ?? this.idFrontPhotoUrl,
      idBackPhotoUrl: idBackPhotoUrl ?? this.idBackPhotoUrl,
      selfiePhotoUrl: selfiePhotoUrl ?? this.selfiePhotoUrl,
      kycStatus: kycStatus ?? this.kycStatus,
      kycVerifiedAt: kycVerifiedAt ?? this.kycVerifiedAt,
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

  /// Calculate profile completion percentage
  double get profileCompletionPercentage {
    int totalFields = 0;
    int completedFields = 0;

    // Basic profile fields
    totalFields += 4; // name, email, phone, address
    if (name.isNotEmpty) completedFields++;
    if (email != null && email!.isNotEmpty) completedFields++;
    if (phoneNumber.isNotEmpty) completedFields++;
    if (address.isNotEmpty) completedFields++;

    // KYC location fields
    totalFields += 5; // province, district, sector, cell, village
    if (province != null && province!.isNotEmpty) completedFields++;
    if (district != null && district!.isNotEmpty) completedFields++;
    if (sector != null && sector!.isNotEmpty) completedFields++;
    if (cell != null && cell!.isNotEmpty) completedFields++;
    if (village != null && village!.isNotEmpty) completedFields++;

    // KYC ID fields
    totalFields += 1; // id_number
    if (idNumber != null && idNumber!.isNotEmpty) completedFields++;

    // KYC photo fields
    totalFields += 3; // id_front, id_back, selfie
    if (idFrontPhotoUrl != null && idFrontPhotoUrl!.isNotEmpty) completedFields++;
    if (idBackPhotoUrl != null && idBackPhotoUrl!.isNotEmpty) completedFields++;
    if (selfiePhotoUrl != null && selfiePhotoUrl!.isNotEmpty) completedFields++;

    return totalFields > 0 ? (completedFields / totalFields) * 100 : 0.0;
  }

  /// Get profile completion status
  String get profileCompletionStatus {
    final percentage = profileCompletionPercentage;
    if (percentage >= 90) return 'Complete';
    if (percentage >= 70) return 'Almost Complete';
    if (percentage >= 50) return 'Partially Complete';
    if (percentage >= 30) return 'Basic';
    return 'Incomplete';
  }

  /// Check if KYC is complete
  bool get isKycComplete {
    return kycStatus == 'verified';
  }

  /// Check if KYC is pending
  bool get isKycPending {
    return kycStatus == 'pending';
  }

  /// Check if KYC is rejected
  bool get isKycRejected {
    return kycStatus == 'rejected';
  }
} 