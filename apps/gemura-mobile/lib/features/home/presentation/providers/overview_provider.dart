import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/overview.dart';
import '../../../../core/services/overview_service.dart';
import 'user_accounts_provider.dart';

final overviewServiceProvider = Provider<OverviewService>((ref) {
  return OverviewService();
});

final overviewProvider = FutureProvider<Overview>((ref) async {
  print('📊 OverviewProvider: Starting overview fetch');
  
  // Wait for user accounts to be fetched first
  // This ensures a default account is set before fetching overview
  try {
    print('📊 OverviewProvider: Waiting for accounts...');
    final accountsResponse = await ref.watch(userAccountsProvider.future);
    print('📊 OverviewProvider: Accounts loaded: ${accountsResponse.data.accounts.length} accounts');
    
    // Check if we need to set a default account using the response data directly
    final accounts = accountsResponse.data.accounts;
    final hasDefault = accounts.any((acc) => acc.isDefault);
    final userDefaultAccountId = accountsResponse.data.user.defaultAccountId;
    
    print('📊 OverviewProvider: hasDefault=$hasDefault, userDefaultAccountId=$userDefaultAccountId');
    
    // If no default account but we have accounts, set the first one
    if (accounts.isNotEmpty && !hasDefault && userDefaultAccountId == null) {
      print('⏳ OverviewProvider: No default account found. Setting first account as default...');
      final firstAccount = accounts.first;
      print('⏳ OverviewProvider: Switching to account: ${firstAccount.accountId} (${firstAccount.accountName})');
      final accountsNotifier = ref.read(userAccountsNotifierProvider.notifier);
      
      // Directly switch to the first account to set it as default
      final switched = await accountsNotifier.switchAccount(firstAccount.accountId, null);
      if (switched) {
        print('✅ OverviewProvider: Successfully set first account as default');
        // Wait for the backend to update and refetch accounts
        print('⏳ OverviewProvider: Waiting for backend to update...');
        await Future.delayed(const Duration(milliseconds: 1000));
        // Refetch accounts to ensure state is updated
        print('⏳ OverviewProvider: Refetching accounts...');
        await accountsNotifier.fetchUserAccounts();
        await Future.delayed(const Duration(milliseconds: 500));
        print('✅ OverviewProvider: Default account setup complete');
      } else {
        print('⚠️ OverviewProvider: Failed to set default account, but continuing...');
      }
    } else if (accounts.isNotEmpty && hasDefault) {
      print('✅ OverviewProvider: Default account already set');
    } else {
      print('⚠️ OverviewProvider: No accounts available');
    }
  } catch (e, stackTrace) {
    // If accounts fail to load, log but continue (overview will likely fail too)
    print('⚠️ OverviewProvider: Could not wait for accounts: $e');
    print('⚠️ OverviewProvider: Stack trace: $stackTrace');
  }
  
  print('📊 OverviewProvider: Fetching overview data...');
  final overviewService = ref.read(overviewServiceProvider);
  
  // Get all-time data (no date filter)
  // Backend returns all data by default when no date filters are provided
  
  return await overviewService.getOverview(
    dateFrom: null,
    dateTo: null,
  );
});

final filteredOverviewProvider = FutureProvider.family<Overview, Map<String, String>>((ref, dateRange) async {
  final overviewService = ref.read(overviewServiceProvider);
  return await overviewService.getOverview(
    dateFrom: dateRange['dateFrom'],
    dateTo: dateRange['dateTo'],
  );
});

final overviewNotifierProvider = StateNotifierProvider<OverviewNotifier, AsyncValue<Overview>>((ref) {
  final overviewService = ref.read(overviewServiceProvider);
  return OverviewNotifier(overviewService, ref);
});

class OverviewNotifier extends StateNotifier<AsyncValue<Overview>> {
  final OverviewService _overviewService;
  final Ref? _ref;

  OverviewNotifier(this._overviewService, [this._ref]) : super(const AsyncValue.loading()) {
    // Don't auto-load in constructor - let the FutureProvider handle it
    // loadOverview();
  }

  Future<void> loadOverview() async {
    try {
      state = const AsyncValue.loading();
      
      // If we have a ref, wait for accounts first
      if (_ref != null) {
        try {
          final accountsResponse = await _ref.read(userAccountsProvider.future);
          final accounts = accountsResponse.data.accounts;
          final hasDefault = accounts.any((acc) => acc.isDefault);
          final userDefaultAccountId = accountsResponse.data.user.defaultAccountId;
          
          if (accounts.isNotEmpty && !hasDefault && userDefaultAccountId == null) {
            print('⏳ OverviewNotifier: Setting default account...');
            final firstAccount = accounts.first;
            final accountsNotifier = _ref.read(userAccountsNotifierProvider.notifier);
            await accountsNotifier.switchAccount(firstAccount.accountId, null);
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        } catch (e) {
          print('⚠️ OverviewNotifier: Error waiting for accounts: $e');
        }
      }
      
      // Get all-time data (no date filter)
      // Backend returns all data by default when no date filters are provided
      
      final overview = await _overviewService.getOverview(
        dateFrom: null,
        dateTo: null,
      );
      state = AsyncValue.data(overview);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadOverviewWithDateRange({
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      state = const AsyncValue.loading();
      final overview = await _overviewService.getOverview(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      state = AsyncValue.data(overview);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshOverview() async {
    await loadOverview();
  }
}
