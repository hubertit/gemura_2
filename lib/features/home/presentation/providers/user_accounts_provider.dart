import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/user_accounts_service.dart';
import '../../../../core/services/authenticated_dio_service.dart';
import '../../../../shared/models/user_accounts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final userAccountsServiceProvider = Provider<UserAccountsService>((ref) {
  return UserAccountsService();
});

final userAccountsProvider = FutureProvider<UserAccountsResponse>((ref) async {
  final service = ref.watch(userAccountsServiceProvider);
  return await service.getUserAccounts();
});

final userAccountsNotifierProvider = StateNotifierProvider<UserAccountsNotifier, AsyncValue<UserAccountsResponse?>>((ref) {
  final service = ref.watch(userAccountsServiceProvider);
  return UserAccountsNotifier(service, ref);
});

class UserAccountsNotifier extends StateNotifier<AsyncValue<UserAccountsResponse?>> {
  final UserAccountsService _service;
  final Ref _ref;
  bool _isSwitching = false;

  UserAccountsNotifier(this._service, this._ref) : super(const AsyncValue.loading());

  bool get isSwitching => _isSwitching;

  Future<void> fetchUserAccounts() async {
    state = const AsyncValue.loading();
    try {
      final response = await _service.getUserAccounts();
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> switchAccount(int accountId) async {
    if (_isSwitching) return false; // Prevent multiple simultaneous switches
    
    _isSwitching = true;
    try {
      print('🔄 Switching to account ID: $accountId');
      
      // Make the switch account API call
      final response = await _service.switchAccount(accountId);
      
      if (response.code == 200) {
        print('✅ Account switch API successful');
        
        // Update accounts for immediate UI feedback
        await fetchUserAccounts();
        
        // Refresh profile in background
        _ref.read(authProvider.notifier).refreshProfile();
        
        print('✅ Account switch completed successfully');
        return true;
      } else {
        print('❌ Account switch API returned code: ${response.code}');
        return false;
      }
    } catch (error) {
      print('❌ Switch account error: $error');
      return false;
    } finally {
      _isSwitching = false;
    }
  }

  UserAccount? getCurrentAccount() {
    final accounts = state.value?.data.accounts;
    if (accounts == null || accounts.isEmpty) return null;
    
    return accounts.firstWhere(
      (account) => account.isDefault,
      orElse: () => accounts.first,
    );
  }

  List<UserAccount> getAccounts() {
    return state.value?.data.accounts ?? [];
  }

  bool get hasMultipleAccounts {
    final accounts = getAccounts();
    return accounts.length > 1;
  }
}
