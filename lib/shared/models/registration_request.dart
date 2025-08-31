class RegistrationRequest {
  final String name;
  final String accountName;
  final String? email;
  final String phone;
  final String password;
  final String? nid;
  final String role;
  final String accountType; // New field for account type
  final Map<String, bool> permissions;
  final bool isAgentCandidate;

  RegistrationRequest({
    required this.name,
    required this.accountName,
    this.email,
    required this.phone,
    required this.password,
    this.nid,
    required this.role,
    required this.accountType, // New required field
    required this.permissions,
    this.isAgentCandidate = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'account_name': accountName,
      if (email != null) 'email': email,
      'phone': phone,
      'password': password,
      if (nid != null) 'nid': nid,
      'role': role,
      'account_type': accountType, // New field
      if (permissions.isNotEmpty) 'permissions': permissions,
      'is_agent_candidate': isAgentCandidate,
    };
  }

  factory RegistrationRequest.fromJson(Map<String, dynamic> json) {
    return RegistrationRequest(
      name: json['name'] as String,
      accountName: json['account_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      password: json['password'] as String,
      nid: json['nid'] as String?,
      role: json['role'] as String,
      accountType: json['account_type'] as String? ?? 'mcc', // New field with default
      permissions: Map<String, bool>.from(json['permissions'] as Map),
      isAgentCandidate: json['is_agent_candidate'] as bool? ?? false,
    );
  }
}
