class Employee {
  final String accessId;
  final String userId;
  final String code;
  final String name;
  final String phone;
  final String? email;
  final String? nid;
  final String? address;
  final String role;
  final List<String> permissions;
  final String status;
  final String userStatus;
  final DateTime createdAt;
  final DateTime userCreatedAt;

  Employee({
    required this.accessId,
    required this.userId,
    required this.code,
    required this.name,
    required this.phone,
    this.email,
    this.nid,
    this.address,
    required this.role,
    required this.permissions,
    required this.status,
    required this.userStatus,
    required this.createdAt,
    required this.userCreatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    List<String> permissions = [];
    if (json['permissions'] != null) {
      if (json['permissions'] is List) {
        permissions = List<String>.from(json['permissions']);
      } else if (json['permissions'] is Map) {
        // Handle case where permissions is a Map with boolean values
        Map<String, dynamic> permMap = Map<String, dynamic>.from(json['permissions']);
        permissions = permMap.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();
      }
    }

    // Backend returns nested structure: { id, user: { id, name, email, phone, account_type }, role, permissions, status, created_at }
    // Handle both nested structure (from backend) and flat structure (for compatibility)
    final userData = json['user'] as Map<String, dynamic>?;
    final accessId = json['id']?.toString() ?? json['access_id']?.toString() ?? '';
    final userId = userData?['id']?.toString() ?? json['user_id']?.toString() ?? '';
    final name = userData?['name']?.toString() ?? json['name']?.toString() ?? '';
    final phone = userData?['phone']?.toString() ?? json['phone']?.toString() ?? '';
    final email = userData?['email']?.toString() ?? json['email']?.toString();
    final accountType = userData?['account_type']?.toString() ?? '';
    
    // Use account_type as code if code is not available, or use first 8 chars of user_id as fallback
    final code = json['code']?.toString() ?? 
                 (accountType.isNotEmpty ? accountType : (userId.length >= 8 ? userId.substring(0, 8) : userId));

    return Employee(
      accessId: accessId,
      userId: userId,
      code: code,
      name: name,
      phone: phone,
      email: email,
      nid: json['nid']?.toString(),
      address: json['address']?.toString(),
      role: json['role']?.toString() ?? '',
      permissions: permissions,
      status: json['status']?.toString() ?? '',
      userStatus: userData?['status']?.toString() ?? json['user_status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      userCreatedAt: userData?['created_at'] != null
          ? DateTime.parse(userData!['created_at'].toString())
          : json['user_created_at'] != null
              ? DateTime.parse(json['user_created_at'].toString())
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_id': accessId,
      'user_id': userId,
      'code': code,
      'name': name,
      'phone': phone,
      'email': email,
      'nid': nid,
      'address': address,
      'role': role,
      'permissions': permissions,
      'status': status,
      'user_status': userStatus,
      'created_at': createdAt.toIso8601String(),
      'user_created_at': userCreatedAt.toIso8601String(),
    };
  }

  Employee copyWith({
    String? accessId,
    String? userId,
    String? code,
    String? name,
    String? phone,
    String? email,
    String? nid,
    String? address,
    String? role,
    List<String>? permissions,
    String? status,
    String? userStatus,
    DateTime? createdAt,
    DateTime? userCreatedAt,
  }) {
    return Employee(
      accessId: accessId ?? this.accessId,
      userId: userId ?? this.userId,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nid: nid ?? this.nid,
      address: address ?? this.address,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      userStatus: userStatus ?? this.userStatus,
      createdAt: createdAt ?? this.createdAt,
      userCreatedAt: userCreatedAt ?? this.userCreatedAt,
    );
  }
}
