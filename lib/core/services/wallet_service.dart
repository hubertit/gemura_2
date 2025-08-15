import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../shared/models/wallet.dart';
import 'secure_storage_service.dart';
import 'authenticated_dio_service.dart';

class WalletService {
  final Dio _authenticatedDio;

  WalletService() : _authenticatedDio = AuthenticatedDioService.instance;

  /// Get user's wallets from API
  Future<List<Wallet>> getUserWallets() async {
    try {
      final response = await _authenticatedDio.get(
        '/wallets',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data is List) {
          final wallets = data.map((json) => Wallet.fromJson(json)).toList();
          
          // Cache wallets
          await SecureStorageService.saveWallets(wallets);
          
          return wallets;
        }
      }

      // Return empty list if no wallets found
      return [];
    } on DioException catch (e) {
      // If API call fails, try to get cached wallets
      final cachedWallets = await SecureStorageService.getWallets();
      if (cachedWallets.isNotEmpty) {
        return cachedWallets;
      }
      
      throw _handleDioError(e);
    } catch (e) {
      // If any other error, try to get cached wallets
      final cachedWallets = await SecureStorageService.getWallets();
      if (cachedWallets.isNotEmpty) {
        return cachedWallets;
      }
      
      throw Exception('Failed to load wallets: $e');
    }
  }

  /// Create a new wallet
  Future<Wallet> createWallet(Map<String, dynamic> walletData) async {
    try {
      final response = await _authenticatedDio.post(
        '/wallets',
        data: walletData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data != null) {
          final wallet = Wallet.fromJson(data);
          
          // Update cached wallets
          final currentWallets = await SecureStorageService.getWallets();
          currentWallets.add(wallet);
          await SecureStorageService.saveWallets(currentWallets);
          
          return wallet;
        }
      }

      throw Exception('Failed to create wallet');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  /// Update wallet
  Future<Wallet> updateWallet(String walletId, Map<String, dynamic> walletData) async {
    try {
      final response = await _authenticatedDio.put(
        '/wallets/$walletId',
        data: walletData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          final updatedWallet = Wallet.fromJson(data);
          
          // Update cached wallets
          final currentWallets = await SecureStorageService.getWallets();
          final index = currentWallets.indexWhere((w) => w.id == walletId);
          if (index != -1) {
            currentWallets[index] = updatedWallet;
            await SecureStorageService.saveWallets(currentWallets);
          }
          
          return updatedWallet;
        }
      }

      throw Exception('Failed to update wallet');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to update wallet: $e');
    }
  }

  /// Delete wallet
  Future<void> deleteWallet(String walletId) async {
    try {
      final response = await _authenticatedDio.delete(
        '/wallets/$walletId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from cached wallets
        final currentWallets = await SecureStorageService.getWallets();
        currentWallets.removeWhere((w) => w.id == walletId);
        await SecureStorageService.saveWallets(currentWallets);
      } else {
        throw Exception('Failed to delete wallet');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to delete wallet: $e');
    }
  }

  /// Get wallet by ID
  Future<Wallet?> getWalletById(String walletId) async {
    try {
      final response = await _authenticatedDio.get(
        '/wallets/$walletId',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return Wallet.fromJson(data);
        }
      }

      return null;
    } on DioException catch (e) {
      // If API call fails, try to get from cached wallets
      final cachedWallets = await SecureStorageService.getWallets();
      return cachedWallets.firstWhere(
        (w) => w.id == walletId,
        orElse: () => throw Exception('Wallet not found'),
      );
    } catch (e) {
      throw Exception('Failed to get wallet: $e');
    }
  }

  /// Refresh wallets from API
  Future<List<Wallet>> refreshWallets() async {
    try {
      // Clear cached wallets first
      await SecureStorageService.saveWallets([]);
      
      // Fetch fresh data from API
      return await getUserWallets();
    } catch (e) {
      throw Exception('Failed to refresh wallets: $e');
    }
  }

  /// Handle Dio errors
  Exception _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final backendMsg = e.response?.data?['message'] ?? e.message;
    
    switch (statusCode) {
      case 400:
        return Exception(backendMsg ?? 'Invalid request. Please check your input.');
      case 401:
        return Exception('Unauthorized. Please login again.');
      case 403:
        return Exception('Access denied. You don\'t have permission to perform this action.');
      case 404:
        return Exception('Wallet not found.');
      case 422:
        return Exception('Invalid data format. Please check your input.');
      case 500:
        return Exception('Server error. Please try again later.');
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          return Exception('Connection timeout. Please check your internet connection.');
        } else if (e.type == DioExceptionType.connectionError) {
          return Exception('No internet connection. Please check your network.');
        } else {
          return Exception(backendMsg ?? 'An error occurred. Please try again.');
        }
    }
  }
}
