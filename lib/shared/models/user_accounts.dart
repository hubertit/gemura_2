import 'package:json_annotation/json_annotation.dart';

part 'user_accounts.g.dart';

@JsonSerializable()
class UserAccountsResponse {
  final int code;
  final String status;
  final String message;
  final UserAccountsData data;

  UserAccountsResponse({
    required this.code,
    required this.status,
    required this.message,
    required this.data,
  });

  factory UserAccountsResponse.fromJson(Map<String, dynamic> json) =>
      _$UserAccountsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserAccountsResponseToJson(this);
}

@JsonSerializable()
class UserAccountsData {
  final UserInfo user;
  final List<UserAccount> accounts;
  @JsonKey(name: 'total_accounts')
  final int totalAccounts;

  UserAccountsData({
    required this.user,
    required this.accounts,
    required this.totalAccounts,
  });

  factory UserAccountsData.fromJson(Map<String, dynamic> json) =>
      _$UserAccountsDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserAccountsDataToJson(this);
}

@JsonSerializable()
class UserInfo {
  @JsonKey(name: 'id')
  final int id;
  @JsonKey(name: 'name')
  final String name;
  @JsonKey(name: 'email')
  final String? email;
  @JsonKey(name: 'phone')
  final String phone;
  @JsonKey(name: 'default_account_id')
  final int? defaultAccountId;

  UserInfo({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.defaultAccountId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}

@JsonSerializable()
class UserAccount {
  @JsonKey(name: 'account_id')
  final int accountId;
  @JsonKey(name: 'account_code')
  final String accountCode;
  @JsonKey(name: 'account_name')
  final String accountName;
  @JsonKey(name: 'account_type')
  final String accountType;
  @JsonKey(name: 'account_status')
  final String accountStatus;
  @JsonKey(name: 'account_created_at')
  final String accountCreatedAt;
  @JsonKey(name: 'role')
  final String role;
  @JsonKey(name: 'permissions')
  final AccountPermissions permissions;
  @JsonKey(name: 'user_account_status')
  final String userAccountStatus;
  @JsonKey(name: 'access_granted_at')
  final String accessGrantedAt;
  @JsonKey(name: 'is_default')
  final bool isDefault;

  UserAccount({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.accountStatus,
    required this.accountCreatedAt,
    required this.role,
    required this.permissions,
    required this.userAccountStatus,
    required this.accessGrantedAt,
    required this.isDefault,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) =>
      _$UserAccountFromJson(json);
  Map<String, dynamic> toJson() => _$UserAccountToJson(this);
}

@JsonSerializable()
class AccountPermissions {
  @JsonKey(name: 'can_collect')
  final bool? canCollect;
  @JsonKey(name: 'can_add_supplier')
  final bool? canAddSupplier;
  @JsonKey(name: 'can_view_reports')
  final bool? canViewReports;
  @JsonKey(name: 'can_manage_employees')
  final bool? canManageEmployees;

  AccountPermissions({
    this.canCollect,
    this.canAddSupplier,
    this.canViewReports,
    this.canManageEmployees,
  });

  factory AccountPermissions.fromJson(Map<String, dynamic> json) =>
      _$AccountPermissionsFromJson(json);
  Map<String, dynamic> toJson() => _$AccountPermissionsToJson(this);
}

@JsonSerializable()
class SwitchAccountResponse {
  final int code;
  final String status;
  final String message;
  final SwitchAccountData data;

  SwitchAccountResponse({
    required this.code,
    required this.status,
    required this.message,
    required this.data,
  });

  factory SwitchAccountResponse.fromJson(Map<String, dynamic> json) =>
      _$SwitchAccountResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SwitchAccountResponseToJson(this);
}

@JsonSerializable()
class SwitchAccountData {
  final int userId;
  final String userName;
  final DefaultAccount newDefaultAccount;

  SwitchAccountData({
    required this.userId,
    required this.userName,
    required this.newDefaultAccount,
  });

  factory SwitchAccountData.fromJson(Map<String, dynamic> json) =>
      _$SwitchAccountDataFromJson(json);
  Map<String, dynamic> toJson() => _$SwitchAccountDataToJson(this);
}

@JsonSerializable()
class DefaultAccount {
  final int accountId;
  final String accountCode;
  final String accountName;
  final String role;

  DefaultAccount({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.role,
  });

  factory DefaultAccount.fromJson(Map<String, dynamic> json) =>
      _$DefaultAccountFromJson(json);
  Map<String, dynamic> toJson() => _$DefaultAccountToJson(this);
}
