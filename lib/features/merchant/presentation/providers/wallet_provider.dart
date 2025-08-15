import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/wallet_service.dart';
import '../../../../shared/models/wallet.dart';

// Wallet service provider
final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

// Wallets state provider
final walletsProvider = StateNotifierProvider<WalletsNotifier, AsyncValue<List<Wallet>>>((ref) {
  final walletService = ref.watch(walletServiceProvider);
  return WalletsNotifier(walletService);
});

// Selected wallet provider
final selectedWalletProvider = StateProvider<Wallet?>((ref) => null);

class WalletsNotifier extends StateNotifier<AsyncValue<List<Wallet>>> {
  final WalletService _walletService;

  WalletsNotifier(this._walletService) : super(const AsyncValue.loading()) {
    loadWallets();
  }

  /// Load wallets from API or cache
  Future<void> loadWallets() async {
    try {
      state = const AsyncValue.loading();
      final wallets = await _walletService.getUserWallets();
      state = AsyncValue.data(wallets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh wallets from API
  Future<void> refreshWallets() async {
    try {
      state = const AsyncValue.loading();
      final wallets = await _walletService.refreshWallets();
      state = AsyncValue.data(wallets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Create a new wallet
  Future<void> createWallet(Map<String, dynamic> walletData) async {
    try {
      final newWallet = await _walletService.createWallet(walletData);
      final currentWallets = state.value ?? [];
      state = AsyncValue.data([...currentWallets, newWallet]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update a wallet
  Future<void> updateWallet(String walletId, Map<String, dynamic> walletData) async {
    try {
      final updatedWallet = await _walletService.updateWallet(walletId, walletData);
      final currentWallets = state.value ?? [];
      final updatedWallets = currentWallets.map((wallet) {
        return wallet.id == walletId ? updatedWallet : wallet;
      }).toList();
      state = AsyncValue.data(updatedWallets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete a wallet
  Future<void> deleteWallet(String walletId) async {
    try {
      await _walletService.deleteWallet(walletId);
      final currentWallets = state.value ?? [];
      final updatedWallets = currentWallets.where((wallet) => wallet.id != walletId).toList();
      state = AsyncValue.data(updatedWallets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Get wallet by ID
  Wallet? getWalletById(String walletId) {
    final wallets = state.value;
    if (wallets == null) return null;
    try {
      return wallets.firstWhere((wallet) => wallet.id == walletId);
    } catch (e) {
      return null;
    }
  }

  /// Get default wallet
  Wallet? getDefaultWallet() {
    final wallets = state.value;
    if (wallets == null) return null;
    try {
      return wallets.firstWhere((wallet) => wallet.isDefault);
    } catch (e) {
      return wallets.isNotEmpty ? wallets.first : null;
    }
  }

  /// Get active wallets
  List<Wallet> getActiveWallets() {
    final wallets = state.value;
    if (wallets == null) return [];
    return wallets.where((wallet) => wallet.status == 'active').toList();
  }

  /// Get individual wallets
  List<Wallet> getIndividualWallets() {
    final wallets = state.value;
    if (wallets == null) return [];
    return wallets.where((wallet) => wallet.type == 'individual').toList();
  }

  /// Get joint wallets
  List<Wallet> getJointWallets() {
    final wallets = state.value;
    if (wallets == null) return [];
    return wallets.where((wallet) => wallet.type == 'joint').toList();
  }
}
