import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/wallet.dart';
import '../../../../core/services/wallets_service.dart';

final walletsServiceProvider = Provider<WalletsService>((ref) {
  return WalletsService();
});

final walletsProvider = FutureProvider<List<Wallet>>((ref) async {
  final walletsService = ref.read(walletsServiceProvider);
  return await walletsService.getWallets();
});

final walletsNotifierProvider = StateNotifierProvider<WalletsNotifier, AsyncValue<List<Wallet>>>((ref) {
  final walletsService = ref.read(walletsServiceProvider);
  return WalletsNotifier(walletsService);
});

class WalletsNotifier extends StateNotifier<AsyncValue<List<Wallet>>> {
  final WalletsService _walletsService;

  WalletsNotifier(this._walletsService) : super(const AsyncValue.loading()) {
    loadWallets();
  }

  Future<void> loadWallets() async {
    try {
      state = const AsyncValue.loading();
      final wallets = await _walletsService.getWallets();
      state = AsyncValue.data(wallets);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshWallets() async {
    await loadWallets();
  }

  Future<void> createWallet({
    required String name,
    required String type,
    String? description,
    List<String>? jointOwners,
  }) async {
    try {
      final newWallet = await _walletsService.createWallet(
        name: name,
        type: type,
        description: description,
        jointOwners: jointOwners,
      );
      
      // Add the new wallet to the current list
      state.whenData((wallets) {
        final updatedWallets = [...wallets, newWallet];
        state = AsyncValue.data(updatedWallets);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> getWalletDetails(String walletCode) async {
    try {
      final walletDetails = await _walletsService.getWalletDetails(walletCode);
      
      // Update the wallet in the current list
      state.whenData((wallets) {
        final updatedWallets = wallets.map((wallet) {
          if (wallet.walletCode == walletCode) {
            return wallet.copyWith(
              balance: walletDetails.balance,
              status: walletDetails.status,
              // Add other fields as needed
            );
          }
          return wallet;
        }).toList();
        state = AsyncValue.data(updatedWallets);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
