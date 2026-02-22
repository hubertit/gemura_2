import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String? email;
  final String password;
  final String role;
  final String accountType; // New field for account type
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String? about;
  final String? profilePicture;
  final String? profileCover;
  final String? phoneNumber;
  final String? address;
  final String? profileImg;
  final String? coverImg;
  final String? accountCode;
  final String? accountName;
  
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
    required this.accountType, // New required field
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.about,
    this.address,
    this.profilePicture,
    this.profileImg,
    this.profileCover,
    this.coverImg,
    this.phoneNumber,
    this.accountCode,
    this.accountName,
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
      if (email != null) 'email': email,
      'password': password,
      'role': role,
      'account_type': accountType, // New field
      'created_at': createdAt.toIso8601String(),
      if (lastLoginAt != null) 'last_login_at': lastLoginAt!.toIso8601String(),
      'is_active': isActive,
      if (about != null) 'about': about,
      if (address != null) 'address': address,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (profileImg != null) 'profile_img': profileImg,
      if (profileCover != null) 'profile_cover': profileCover,
      if (coverImg != null) 'cover_img': coverImg,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (accountCode != null) 'account_code': accountCode,
      if (accountName != null) 'account_name': accountName,
      // KYC Fields
      if (province != null) 'province': province,
      if (district != null) 'district': district,
      if (sector != null) 'sector': sector,
      if (cell != null) 'cell': cell,
      if (village != null) 'village': village,
      if (idNumber != null) 'id_number': idNumber,
      if (idFrontPhotoUrl != null) 'id_front_photo_url': idFrontPhotoUrl,
      if (idBackPhotoUrl != null) 'id_back_photo_url': idBackPhotoUrl,
      if (selfiePhotoUrl != null) 'selfie_photo_url': selfiePhotoUrl,
      if (kycStatus != null) 'kyc_status': kycStatus,
      if (kycVerifiedAt != null) 'kyc_verified_at': kycVerifiedAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    print('🔧 User.fromJson: Starting to parse JSON: $json');
    
    // Helper function to safely parse DateTime
    DateTime? _parseDateTime(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        print('🔧 User.fromJson: Failed to parse DateTime: $value, error: $e');
        return null;
      }
    }

    // Helper function to safely convert to string or null
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    try {
      print('🔧 User.fromJson: Parsing individual fields...');
      
      final user = User(
        id: json['id']?.toString() ?? json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: _toStringOrNull(json['email']),
        password: json['password']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        accountType: json['account_type']?.toString() ?? 'mcc', // New field with default
        createdAt: _parseDateTime(json['createdAt']) ?? 
                   _parseDateTime(json['created_at']) ?? 
                   DateTime.now(),
        lastLoginAt: _parseDateTime(json['lastLoginAt']) ?? 
                     _parseDateTime(json['last_login_at']),
        isActive: json['isActive'] as bool? ?? (json['status']?.toString() == 'active'),
        about: _toStringOrNull(json['about']),
        address: _toStringOrNull(json['address']),
        profilePicture: _toStringOrNull(json['profilePicture']) ?? _toStringOrNull(json['profile_picture']),
        profileImg: _toStringOrNull(json['profile_img']),
        profileCover: _toStringOrNull(json['profileCover']) ?? _toStringOrNull(json['profile_cover']),
        coverImg: _toStringOrNull(json['cover_img']),
        phoneNumber: _toStringOrNull(json['phoneNumber']) ?? _toStringOrNull(json['phone']),
        accountCode: _toStringOrNull(json['accountCode']) ?? _toStringOrNull(json['account_code']),
        accountName: _toStringOrNull(json['accountName']) ?? _toStringOrNull(json['account_name']),
        // KYC Fields
        province: _toStringOrNull(json['province']),
        district: _toStringOrNull(json['district']),
        sector: _toStringOrNull(json['sector']),
        cell: _toStringOrNull(json['cell']),
        village: _toStringOrNull(json['village']),
        idNumber: _toStringOrNull(json['idNumber']) ?? _toStringOrNull(json['id_number']),
        idFrontPhotoUrl: _toStringOrNull(json['idFrontPhotoUrl']) ?? _toStringOrNull(json['id_front_photo_url']),
        idBackPhotoUrl: _toStringOrNull(json['idBackPhotoUrl']) ?? _toStringOrNull(json['id_back_photo_url']),
        selfiePhotoUrl: _toStringOrNull(json['selfiePhotoUrl']) ?? _toStringOrNull(json['selfie_photo_url']),
        kycStatus: _toStringOrNull(json['kycStatus']) ?? _toStringOrNull(json['kyc_status']),
        kycVerifiedAt: _parseDateTime(json['kycVerifiedAt']) ?? _parseDateTime(json['kyc_verified_at']),
      );
      
      print('🔧 User.fromJson: Successfully created user object');
      return user;
    } catch (e, stack) {
      print('🔧 User.fromJson: Error creating user object: $e');
      print('🔧 User.fromJson: Stack trace: $stack');
      rethrow;
    }
  }

  // Account type constants
  static const String accountTypeMCC = 'mcc';
  static const String accountTypeAgent = 'agent';
  static const String accountTypeCollector = 'collector';
  static const String accountTypeVeterinarian = 'veterinarian';
  static const String accountTypeSupplier = 'supplier';
  static const String accountTypeCustomer = 'customer';
  static const String accountTypeFarmer = 'farmer';
  static const String accountTypeOwner = 'owner';

  // Helper method to get display name for account type
  static String getAccountTypeDisplayName(String accountType) {
    switch (accountType.toLowerCase()) {
      case accountTypeMCC:
        return 'MCC (Milk Collection Center)';
      case accountTypeAgent:
        return 'Agent';
      case accountTypeCollector:
        return 'Collector (Abacunda)';
      case accountTypeVeterinarian:
        return 'Veterinarian';
      case accountTypeSupplier:
        return 'Supplier';
      case accountTypeCustomer:
        return 'Customer';
      case accountTypeFarmer:
        return 'Farmer';
      case accountTypeOwner:
        return 'Owner';
      default:
        return accountType;
    }
  }

  // Helper method to get color for account type badge
  static Color getAccountTypeColor(String accountType) {
    switch (accountType.toLowerCase()) {
      case accountTypeMCC:
        return Colors.blue;
      case accountTypeAgent:
        return Colors.green;
      case accountTypeCollector:
        return Colors.orange;
      case accountTypeVeterinarian:
        return Colors.purple;
      case accountTypeSupplier:
        return Colors.teal;
      case accountTypeCustomer:
        return Colors.indigo;
      case accountTypeFarmer:
        return Colors.brown;
      case accountTypeOwner:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? accountType,
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
    String? accountName,
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
      accountType: accountType ?? this.accountType,
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
      accountName: accountName ?? this.accountName,
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
    if (phoneNumber != null && phoneNumber!.isNotEmpty) completedFields++;
    if (address != null && address!.isNotEmpty) completedFields++;

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