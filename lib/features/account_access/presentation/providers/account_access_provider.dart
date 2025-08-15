import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/account_access.dart';
import '../../../../shared/models/user.dart';

class AccountAccessNotifier extends StateNotifier<AsyncValue<List<AccountAccess>>> {
  AccountAccessNotifier() : super(const AsyncValue.loading());

  // Get all accounts user has access to
  Future<List<SharedAccount>> getUserAccounts(String userId) async {
    // TODO: Implement API call to get user's accessible accounts
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data for now
    return [
      SharedAccount(
        id: '1',
        originalOwnerId: userId,
        accountName: 'My Farm',
        accountType: 'primary',
        status: 'active',
        createdAt: DateTime.now(),
        accessList: [
          AccountAccess(
            id: '1',
            accountOwnerId: userId,
            grantedUserId: userId,
            role: AccountAccess.roleOwner,
            permissions: {
              'view': true,
              'edit': true,
              'delete': true,
              'share': true,
              'manage_users': true,
            },
            grantedAt: DateTime.now(),
          ),
        ],
      ),
    ];
  }

  // Grant access to another user
  Future<bool> grantAccess({
    required String accountId,
    required String targetUserId,
    required String role,
    required Map<String, dynamic> permissions,
    DateTime? expiresAt,
  }) async {
    try {
      // TODO: Implement API call to grant access
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock success
      return true;
    } catch (e) {
      return false;
    }
  }

  // Revoke access
  Future<bool> revokeAccess(String accessId) async {
    try {
      // TODO: Implement API call to revoke access
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock success
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update access permissions
  Future<bool> updateAccess({
    required String accessId,
    required String role,
    required Map<String, dynamic> permissions,
  }) async {
    try {
      // TODO: Implement API call to update access
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock success
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get users who have access to an account
  Future<List<User>> getAccountUsers(String accountId) async {
    // TODO: Implement API call to get account users
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data
    return [
      User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        password: '',
        role: 'user',
        createdAt: DateTime.now(),
        phoneNumber: '+250123456789',
      ),
    ];
  }
}

final accountAccessProvider = StateNotifierProvider<AccountAccessNotifier, AsyncValue<List<AccountAccess>>>(
  (ref) => AccountAccessNotifier(),
);

// Provider for current user's accessible accounts
final userAccountsProvider = FutureProvider.family<List<SharedAccount>, String>(
  (ref, userId) async {
    final notifier = ref.read(accountAccessProvider.notifier);
    return await notifier.getUserAccounts(userId);
  },
);

// Provider for account users
final accountUsersProvider = FutureProvider.family<List<User>, String>(
  (ref, accountId) async {
    final notifier = ref.read(accountAccessProvider.notifier);
    return await notifier.getAccountUsers(accountId);
  },
);
