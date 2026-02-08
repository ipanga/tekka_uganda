import 'dart:async';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/api_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'user_api_repository.dart';

/// JWT-based authentication repository using SMS OTP via backend API
///
/// This replaces Firebase Auth with custom JWT authentication.
/// OTP is sent via SMS through the backend API.
class JwtAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final UserApiRepository _userApiRepository;

  // Cached user
  AppUser? _cachedUser;

  // Store phone number for OTP verification
  String? _pendingPhoneNumber;

  // Stream controller for auth state changes
  final _authStateController = StreamController<AppUser?>.broadcast();

  JwtAuthRepository({
    required ApiClient apiClient,
    required UserApiRepository userApiRepository,
  })  : _apiClient = apiClient,
        _userApiRepository = userApiRepository {
    // Check initial auth state
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    final token = await _apiClient.getToken();
    if (token != null) {
      // Try to get current user from API
      try {
        _cachedUser = await _userApiRepository.getMe();
        _authStateController.add(_cachedUser);
      } catch (e) {
        // Token might be expired, try to refresh
        final refreshed = await _tryRefreshToken();
        if (!refreshed) {
          await _apiClient.clearToken();
          await _apiClient.clearRefreshToken();
          _authStateController.add(null);
        }
      }
    } else {
      _authStateController.add(null);
    }
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _apiClient.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _apiClient.postWithoutAuth<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response['accessToken'] as String;
      final newRefreshToken = response['refreshToken'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      await _apiClient.setToken(newAccessToken);
      await _apiClient.setRefreshToken(newRefreshToken);

      _cachedUser = AppUser.fromJson(userData);
      _authStateController.add(_cachedUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Future<String> sendOtp(String phoneNumber) async {
    try {
      // Format phone number for Uganda if needed
      String formattedPhone = phoneNumber.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+256${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+256$formattedPhone';
      }

      await _apiClient.postWithoutAuth<Map<String, dynamic>>(
        '/auth/send-otp',
        data: {'phone': formattedPhone},
      );

      // Store phone number for verification step
      _pendingPhoneNumber = formattedPhone;

      // Return phone number as "verification ID" for compatibility
      return formattedPhone;
    } catch (e) {
      if (e is ApiException) {
        throw AuthException(message: e.message, code: e.code);
      }
      throw AuthException(message: 'Failed to send OTP: $e');
    }
  }

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      // Use stored phone number or verificationId (which is the phone number)
      final phoneNumber = _pendingPhoneNumber ?? verificationId;

      final response = await _apiClient.postWithoutAuth<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'phone': phoneNumber,
          'code': otp,
        },
      );

      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      // Store tokens
      await _apiClient.setToken(accessToken);
      await _apiClient.setRefreshToken(refreshToken);

      // Parse and cache user
      _cachedUser = AppUser.fromJson(userData);
      _authStateController.add(_cachedUser);

      // Clear pending phone number
      _pendingPhoneNumber = null;

      return _cachedUser!;
    } catch (e) {
      if (e is ApiException) {
        String message;
        switch (e.code) {
          case 'UNAUTHORIZED':
            message = 'Invalid OTP. Please try again';
            break;
          case 'BAD_REQUEST':
            message = 'Invalid request. Please try again';
            break;
          default:
            message = e.message;
        }
        throw AuthException(message: message, code: e.code);
      }
      throw AuthException(message: 'Verification failed: $e');
    }
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    required String location,
    String? photoUrl,
  }) async {
    try {
      _cachedUser = await _userApiRepository.completeOnboarding(
        displayName: displayName,
        location: location,
        photoUrl: photoUrl,
      );
      _authStateController.add(_cachedUser);
    } catch (e) {
      if (e is ApiException) {
        throw AuthException(message: e.message, code: e.code);
      }
      throw AuthException(message: 'Failed to update profile: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _apiClient.clearToken();
    await _apiClient.clearRefreshToken();
    _cachedUser = null;
    _authStateController.add(null);
  }

  @override
  Future<bool> isOnboardingComplete() async {
    if (_cachedUser != null) {
      return _cachedUser!.isOnboardingComplete;
    }

    // Check if we have a token
    final token = await _apiClient.getToken();
    if (token == null) return false;

    // Fetch from API
    try {
      _cachedUser = await _userApiRepository.getMe();
      _authStateController.add(_cachedUser);
      return _cachedUser!.isOnboardingComplete;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AppUser?> getUserById(String userId) async {
    try {
      return await _userApiRepository.getPublicProfile(userId);
    } catch (e) {
      return null;
    }
  }

  /// Refresh the access token
  Future<void> refreshToken() async {
    await _tryRefreshToken();
  }

  /// Get current user from API (force refresh)
  Future<AppUser?> refreshCurrentUser() async {
    try {
      _cachedUser = await _userApiRepository.getMe();
      _authStateController.add(_cachedUser);
      return _cachedUser;
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
