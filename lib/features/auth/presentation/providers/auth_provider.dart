import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/models/registration_request.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService = AuthService();
  
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
      final isLoggedIn = SecureStorageService.getLoginState();
      final userData = SecureStorageService.getUserData();
      
      if (userData != null && isLoggedIn) {
        final user = User.fromJson(userData);
        
        // Only load the user if they are truly logged in (not a guest)
        if (!user.id.startsWith('guest_')) {
                  // Try to get fresh profile data from API to ensure we have the latest role and account info
        try {
          final profileResponse = await _authService.getProfile();
                                // print('🔍 DEBUG: Profile API Response: $profileResponse');
          if (profileResponse['data'] != null) {
            final updatedUser = User.fromJson(profileResponse['data']);
                      // print('🔍 DEBUG: Updated User Role: ${updatedUser.role}');
          // print('🔍 DEBUG: Updated User AccountCode: ${updatedUser.accountCode}');
            state = AsyncValue.data(updatedUser);
          } else {
            // print('🔍 DEBUG: No profile data, using cached user');
            state = AsyncValue.data(user);
          }
        } catch (e) {
          // If API call fails, use cached data
          // print('🔍 DEBUG: Profile API failed, using cached user: $e');
          state = AsyncValue.data(user);
        }
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
      
      final response = await _authService.login(emailOrPhone, password);
      
      // Create user from API response
      final userData = response['data']['user'];
      final accountData = response['data']['account'];
      
                            // Debug: Print the actual API response
                      // print('🔍 DEBUG: Login API Response:');
                      // print('🔍 DEBUG: userData: $userData');
                      // print('🔍 DEBUG: accountData: $accountData');
                      // print('🔍 DEBUG: accountData[type]: ${accountData['type']}');
                      // print('🔍 DEBUG: accountData[code]: ${accountData['code']}');
      
      final user = User(
        id: userData['code']?.toString() ?? '1',
        name: userData['name'] ?? 'User',
        email: userData['email'] ?? emailOrPhone,
        password: '',
        role: accountData['type']?.toString() ?? 'owner', // Role is in account.type
        createdAt: DateTime.now(), // API doesn't provide this
        lastLoginAt: DateTime.now(),
        isActive: userData['status'] == 'active',
        about: userData['about']?.toString() ?? '',
        address: userData['address']?.toString() ?? '',
        profilePicture: userData['profile_picture']?.toString() ?? '',
        profileImg: userData['profile_img']?.toString() ?? '',
        profileCover: userData['profile_cover']?.toString() ?? '',
        coverImg: userData['cover_img']?.toString() ?? '',
        phoneNumber: userData['phone']?.toString() ?? '',
        accountCode: accountData['code']?.toString() ?? '',
      );
      
      // User data and token are already saved by AuthService
      
      // Try to get complete profile data to ensure we have the latest role and account info
      try {
        final profileResponse = await _authService.getProfile();
        if (profileResponse['data'] != null) {
          final updatedUser = User.fromJson(profileResponse['data']);
          state = AsyncValue.data(updatedUser);
        } else {
          state = AsyncValue.data(user);
        }
      } catch (e) {
        // If profile fetch fails, use the user data from login
        state = AsyncValue.data(user);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String name,
    String accountName,
    String? email,
    String phoneNumber,
    String password,
    String role,
    String? nid,
  ) async {
    try {
      state = const AsyncValue.loading();
      
      // Create registration request (permissions will be set by API)
      final registrationRequest = RegistrationRequest(
        name: name,
        accountName: accountName,
        email: email,
        phone: phoneNumber,
        password: password,
        nid: nid, // Optional field, can be null
        role: role,
        permissions: {}, // API will set default permissions
      );
      
      await _authService.register(registrationRequest);
      
      // Registration successful, do not log in automatically
      state = const AsyncValue.data(null);
      
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.logout();
      state = const AsyncValue.data(null);
    } catch (e) {
      // Even if logout fails, clear local state
      state = const AsyncValue.data(null);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.forgotPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getUserRole() async {
    final user = state.value;
    return user?.role;
  }

  Future<void> sendResetCode(String email) async {
    try {
      await _authService.forgotPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _authService.forgotPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPasswordWithCode(String email, String code, String newPassword) async {
    try {
      await _authService.resetPassword(code, newPassword);
    } catch (e) {
      rethrow;
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
    String? businessName,
  }) async {
    try {
      print('🔧 AuthProvider: Starting updateUserProfile...');
      print('🔧 AuthProvider: Parameters - name: $name, email: $email, phone: $phoneNumber, address: $address, businessName: $businessName');
      
      final currentUser = state.value;
      if (currentUser == null) {
        print('🔧 AuthProvider: No user logged in');
        throw Exception('No user logged in');
      }
      print('🔧 AuthProvider: Current user: ${currentUser.name}');

      final profileData = <String, dynamic>{};
      if (name != null && name.isNotEmpty) profileData['name'] = name;
      if (about != null && about.isNotEmpty) profileData['about'] = about;
      if (address != null && address.isNotEmpty) profileData['address'] = address;
      if (phoneNumber != null && phoneNumber.isNotEmpty) profileData['phone'] = phoneNumber;
      if (profileImg != null && profileImg.isNotEmpty) profileData['profile_img'] = profileImg;
      if (coverImg != null && coverImg.isNotEmpty) profileData['cover_img'] = coverImg;
      if (email != null && email.isNotEmpty) profileData['email'] = email;
      if (businessName != null && businessName.isNotEmpty) profileData['business_name'] = businessName;

      print('🔧 AuthProvider: Profile data to send: $profileData');

      final response = await _authService.updateProfile(profileData);
      print('🔧 AuthProvider: Service response: $response');
      
      // Update local user data
      if (response['data'] != null) {
        final updatedUser = User.fromJson(response['data']['user'] ?? response['data']);
        print('🔧 AuthProvider: Updated user: ${updatedUser.name}');
        state = AsyncValue.data(updatedUser);
      }
      
      print('🔧 AuthProvider: Profile update completed successfully');
    } catch (e) {
      print('🔧 AuthProvider: Error updating profile: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await SecureStorageService.clearAllCachedData();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> clearAllData() async {
    try {
      await SecureStorageService.clearAllCachedData();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> isUserLoggedIn() async {
    try {
      return SecureStorageService.getLoginState();
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
      final token = SecureStorageService.getAuthToken();
      if (token == null || token.isEmpty) return false;
      
      // Try to get profile to verify token is still valid
      await _authService.getProfile();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      // Force refresh from API, ignore cache
      final profileResponse = await _authService.refreshProfile();
      if (profileResponse['data'] != null) {
        final updatedUser = User.fromJson(profileResponse['data']);
        // Force state update to trigger UI rebuild
        state = AsyncValue.data(updatedUser);
        print('Profile refreshed: ${updatedUser.name} - ${updatedUser.role}');
      }
    } catch (e) {
      // If refresh fails, keep current user data but log the error
      print('Failed to refresh profile: $e');
    }
  }
} 