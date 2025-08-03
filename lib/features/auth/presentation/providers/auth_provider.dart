import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:async';

import '../../../../core/config/app_config.dart';
import '../../../../shared/models/user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
    _startTokenVerificationTimer();
  }

  Timer? _tokenVerificationTimer;

  void _startTokenVerificationTimer() {
    _tokenVerificationTimer?.cancel();
    _tokenVerificationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final isValid = await verifyToken();
      if (!isValid) {
        await signOut();
      }
    });
  }

  @override
  void dispose() {
    _tokenVerificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConfig.userFullDataKey);
      final isLoggedIn = prefs.getBool(AppConfig.isLoggedInKey) ?? false;
      
      if (userJson != null && isLoggedIn) {
        final userData = json.decode(userJson);
        final user = User.fromJson(userData);
        
        // Only load the user if they are truly logged in (not a guest)
        if (!user.id.startsWith('guest_')) {
          state = AsyncValue.data(user);
        } else {
          state = const AsyncValue.data(null);
        }
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInWithEmailAndPassword(String emailOrPhone, String password) async {
    try {
      state = const AsyncValue.loading();
      
      // Accept any credentials and return a dummy user
      await Future.delayed(const Duration(milliseconds: 500));
      
      final user = User(
        id: '1',
        name: 'Demo User',
        email: emailOrPhone.contains('@') ? emailOrPhone : 'demo@example.com',
        password: '',
        role: 'user',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
        about: '',
        address: '',
        profilePicture: '',
        profileImg: '',
        profileCover: '',
        coverImg: '',
        phoneNumber: emailOrPhone.contains('@') ? '' : emailOrPhone,
      );
      
      // Save user data and login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.userFullDataKey, json.encode(user.toJson()));
      await prefs.setBool(AppConfig.isLoggedInKey, true);
      
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String name,
    String email,
    String phoneNumber,
    String password,
    String role,
  ) async {
    try {
      state = const AsyncValue.loading();
      final dio = AppConfig.dioInstance();
      final payload = {
        'name': name,
        'email': email,
        'phone': phoneNumber,
        'password': password,
        'role': role,
      };
      final response = await dio.post(
        '${AppConfig.authEndpoint}/register',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful, do not log in automatically
      state = const AsyncValue.data(null);
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message ?? 'Registration failed';
      state = AsyncValue.error(errorMsg, StackTrace.current);
      rethrow;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConfig.isLoggedInKey, false);
      await prefs.remove(AppConfig.userFullDataKey);
      await prefs.remove(AppConfig.authTokenKey);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> resetPassword(String email) async {
    // No-op for demo
  }

  Future<String?> getUserRole() async {
    final user = state.value;
    return user?.role;
  }

  Future<void> sendResetCode(String email) async {
    // Simulate sending a code
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      final dio = AppConfig.dioInstance();
      final response = await dio.post(
        '${AppConfig.authEndpoint}/request_reset',
        data: {'email': email},
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to request password reset');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message ?? 'Failed to request password reset';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> resetPasswordWithCode(String email, String code, String newPassword) async {
    try {
      final dio = AppConfig.dioInstance();
      final response = await dio.post(
        '${AppConfig.authEndpoint}/reset_password',
        data: {
          'email': email,
          'reset_code': code,
          'new_password': newPassword,
        },
      );
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to reset password');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message ?? 'Failed to reset password';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? email,
    String? password,
    String? about,
    String? profilePicture,
    String? profileCover,
    String? phoneNumber,
    String? address,
    String? profileImg,
    String? coverImg,
  }) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) throw Exception('No user logged in');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.authTokenKey);
      if (token == null || token.isEmpty) throw Exception('No auth token');

      final dio = AppConfig.dioInstance();
      final formData = FormData();
      formData.fields.add(MapEntry('token', token));
      if (name != null && name.isNotEmpty) formData.fields.add(MapEntry('name', name));
      if (about != null && about.isNotEmpty) formData.fields.add(MapEntry('about', about));
      if (address != null && address.isNotEmpty) formData.fields.add(MapEntry('address', address));
      if (phoneNumber != null && phoneNumber.isNotEmpty) formData.fields.add(MapEntry('phone', phoneNumber));
      // Attach profile image file if it's a local file path
      if (profileImg != null && profileImg.isNotEmpty && !profileImg.startsWith('http')) {
        formData.files.add(MapEntry('profile_img', await MultipartFile.fromFile(profileImg, filename: profileImg.split('/').last)));
      }
      // Attach cover image file if it's a local file path
      if (coverImg != null && coverImg.isNotEmpty && !coverImg.startsWith('http')) {
        formData.files.add(MapEntry('cover_img', await MultipartFile.fromFile(coverImg, filename: coverImg.split('/').last)));
      }

      final response = await dio.post(AppConfig.profileUpdateEndpoint, data: formData);
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        // Update local user data
        final updatedUser = currentUser.copyWith(
          name: name ?? currentUser.name,
          about: about ?? currentUser.about,
          address: address ?? currentUser.address,
          phoneNumber: phoneNumber ?? currentUser.phoneNumber,
          profileImg: profileImg ?? currentUser.profileImg,
          coverImg: coverImg ?? currentUser.coverImg,
        );
        await prefs.setString(AppConfig.userFullDataKey, json.encode(updatedUser.toJson()));
        state = AsyncValue.data(updatedUser);
      } else {
        throw Exception(response.data['message'] ?? 'Profile update failed');
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.userFullDataKey);
      await prefs.setBool(AppConfig.isLoggedInKey, false);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConfig.isLoggedInKey) ?? false;
      return isLoggedIn;
    } catch (e) {
      return false;
    }
  }

  bool isGuestUser(User? user) {
    return user == null || user.id.startsWith('guest_');
  }

  Future<void> checkAuthState() async {
    // Implementation of checkAuthState method
  }

  Future<bool> verifyToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.authTokenKey);
      if (token == null || token.isEmpty) return false;
      final dio = AppConfig.dioInstance();
      final response = await dio.post(
        '${AppConfig.authEndpoint}/verify_token',
        data: {'token': token},
      );
      if (response.statusCode == 200 && response.data != null) {
        // You can check for a specific field in response.data if needed
        return true;
      } else {
        return false;
      }
    } on DioException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
} 