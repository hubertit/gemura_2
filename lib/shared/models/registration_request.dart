class RegistrationRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String? nid;
  final String role;
  final Map<String, bool> permissions;

  RegistrationRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.nid,
    required this.role,
    required this.permissions,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      if (nid != null) 'nid': nid,
      'role': role,
      'permissions': permissions,
    };
  }

  factory RegistrationRequest.fromJson(Map<String, dynamic> json) {
    return RegistrationRequest(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      password: json['password'] as String,
      nid: json['nid'] as String?,
      role: json['role'] as String,
      permissions: Map<String, bool>.from(json['permissions'] as Map),
    );
  }
}
