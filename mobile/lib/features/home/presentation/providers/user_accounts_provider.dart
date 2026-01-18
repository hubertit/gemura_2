import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/user_accounts_service.dart';
import '../../../../shared/models/user_accounts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../merchant/presentation/providers/wallets_provider.dart';
import '../providers/overview_provider.dart';
import '../../../collection/presentation/providers/collections_provider.dart';
import '../../../suppliers/presentation/providers/suppliers_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../../loans/presentation/providers/loans_provider.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../../../../core/providers/notification_provider.dart';

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

  void _setSwitching(bool value) {
    _isSwitching = value;
    // Force a rebuild by updating the state
    final currentState = state;
    state = currentState;
  }

  Future<void> fetchUserAccounts() async {
    state = const AsyncValue.loading();
    try {
      final response = await _service.getUserAccounts();
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> switchAccount(String accountId, BuildContext? context) async {
    if (_isSwitching) return false; // Prevent multiple simultaneous switches
    
    _setSwitching(true);
    print('🔧 UserAccountsProvider: Switching state set to true');
    try {
      print('🔄 Switching to account ID: $accountId');
      
      // Make the switch account API call
      final response = await _service.switchAccount(accountId);
      
      if (response.code == 200) {
        print('✅ Account switch API successful');
        
        // Update accounts for immediate UI feedback
        await fetchUserAccounts();
        _ref.invalidate(userAccountsProvider); // Also invalidate the FutureProvider used by UI
        
        // Add a small delay to ensure account switch is processed
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Refresh profile to get updated user data with new account context
        print('🔄 Refreshing profile with new account context');
        await _ref.read(authProvider.notifier).refreshProfile();
        
        // Force refresh accounts again to ensure UI updates with new default account
        print('🔄 Force refreshing accounts to update UI');
        await fetchUserAccounts();
        _ref.invalidate(userAccountsProvider);
        
        // Debug: Check the updated accounts data
        final updatedAccounts = state.value?.data.accounts ?? [];
        final defaultAccount = updatedAccounts.where((acc) => acc.isDefault).firstOrNull;
        print('🔍 Updated accounts count: ${updatedAccounts.length}');
        print('🔍 Default account: ${defaultAccount?.accountName} (ID: ${defaultAccount?.accountId})');
        
        // Add a small delay to ensure UI updates are processed
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Refresh all data providers to get updated data for the new account
        print('🔄 Refreshing all data providers for new account context');
        
        // Refresh wallets data
        try {
          await _ref.read(walletsNotifierProvider.notifier).refreshWallets();
          _ref.invalidate(walletsProvider); // Also invalidate the FutureProvider
          print('✅ Wallets refreshed');
        } catch (e) {
          print('⚠️ Failed to refresh wallets: $e');
        }
        
        // Refresh overview/stats data
        try {
          await _ref.read(overviewNotifierProvider.notifier).refreshOverview();
          _ref.invalidate(overviewProvider); // Also invalidate the FutureProvider used by UI
          print('✅ Overview refreshed');
        } catch (e) {
          print('⚠️ Failed to refresh overview: $e');
        }
        
        // Refresh collections data
        try {
          await _ref.read(collectionsNotifierProvider.notifier).refreshCollections();
          _ref.invalidate(collectionsProvider); // Also invalidate the FutureProvider
          print('✅ Collections refreshed');
        } catch (e) {
          print('⚠️ Failed to refresh collections: $e');
        }
        
        // Refresh suppliers data
        try {
          await _ref.read(suppliersNotifierProvider.notifier).refreshSuppliers();
          _ref.invalidate(suppliersProvider); // Also invalidate the FutureProvider
          print('✅ Suppliers refreshed');
        } catch (e) {
          print('⚠️ Failed to refresh suppliers: $e');
        }
        
        // Refresh customers data
        try {
          await _ref.read(customersNotifierProvider.notifier).refreshCustomers();
          _ref.invalidate(customersProvider); // Also invalidate the FutureProvider
          print('✅ Customers refreshed');
        } catch (e) {
          print('⚠️ Failed to refresh customers: $e');
        }
        
        // Refresh loans data (using invalidate since no refresh method)
        try {
          _ref.invalidate(loansProvider);
          print('✅ Loans invalidated');
        } catch (e) {
          print('⚠️ Failed to invalidate loans: $e');
        }
        
        // Refresh savings data (using invalidate since no refresh method)
        try {
          _ref.invalidate(savingsProvider);
          print('✅ Savings invalidated');
        } catch (e) {
          print('⚠️ Failed to invalidate savings: $e');
        }
        
        // Refresh notifications data
        try {
          final currentUser = _ref.read(authProvider).value;
          if (currentUser != null) {
            final userId = int.tryParse(currentUser.id);
            if (userId != null) {
              await _ref.read(notificationsNotifierProvider(userId).notifier).refreshNotifications();
              print('✅ Notifications refreshed');
            }
          }
        } catch (e) {
          print('⚠️ Failed to refresh notifications: $e');
        }
        
        // Reset switching state after all data refreshes are complete
        _setSwitching(false);
        print('🔧 UserAccountsProvider: Switching state reset to false after profile refresh');
        
        // Show success message
        print('✅ Account switch completed successfully');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Switched to ${response.data.account.name}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        
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
      // Only reset if we haven't already reset it after successful completion
      if (_isSwitching) {
        _setSwitching(false);
        print('🔧 UserAccountsProvider: Switching state reset to false in finally block');
      }
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
