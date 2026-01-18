import 'package:dio/dio.dart';
import '../../shared/models/wallet.dart';
import 'authenticated_dio_service.dart';

class WalletsService {
  static final WalletsService _instance = WalletsService._internal();
  factory WalletsService() => _instance;
  WalletsService._internal();

  final Dio _dio = AuthenticatedDioService.instance;

  /// Get all wallets for the authenticated user
  Future<List<Wallet>> getWallets() async {
    try {
      final response = await _dio.get(
        '/wallets/get',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          final List<dynamic> walletsData = data['data'] ?? [];
          return walletsData.map((json) => Wallet.fromApiResponse(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get wallets');
        }
      } else {
        throw Exception('Failed to get wallets: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get wallets. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Wallets service not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create a new wallet
  Future<Wallet> createWallet({
    required String name,
    required String type, // 'individual' or 'joint'
    String? description,
    List<String>? jointOwners,
  }) async {
    try {
      final response = await _dio.post(
        '/wallets/create',
        data: {
          'name': name,
          'type': type,
          'description': description,
          'joint_owners': jointOwners,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return Wallet.fromApiResponse(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to create wallet');
        }
      } else {
        throw Exception('Failed to create wallet: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to create wallet. ';
      
      if (e.response?.statusCode == 400) {
        errorMessage = 'Invalid wallet data. Please check your input.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 409) {
        errorMessage = 'Wallet with this name already exists.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get wallet details by wallet code
  Future<Wallet> getWalletDetails(String walletCode) async {
    try {
      final response = await _dio.post(
        '/wallets/details',
        data: {
          'wallet_code': walletCode,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['status'] == 'success') {
          return Wallet.fromApiResponse(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to get wallet details');
        }
      } else {
        throw Exception('Failed to get wallet details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to get wallet details. ';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Wallet not found.';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      } else {
        final backendMsg = e.response?.data?['message'];
        errorMessage += backendMsg ?? 'Please try again.';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
