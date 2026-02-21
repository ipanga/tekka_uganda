import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/api_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'user_api_repository.dart';

/// Firebase implementation of AuthRepository with API backend integration
///
/// Firebase Auth handles phone authentication (OTP verification).
/// After authentication, the backend API is used for user profile management.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final UserApiRepository _userApiRepository;
  final ApiClient _apiClient;

  int? _resendToken;

  // Cached user from API
  AppUser? _cachedApiUser;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    required UserApiRepository userApiRepository,
    required ApiClient apiClient,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _userApiRepository = userApiRepository,
       _apiClient = apiClient;

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        _cachedApiUser = null;
        return null;
      }

      // Store the Firebase token for API authentication
      final token = await user.getIdToken();
      if (token != null) {
        await _apiClient.setToken(token);
      }

      // Get user profile from API
      try {
        _cachedApiUser = await _userApiRepository.getMe();
        return _cachedApiUser;
      } catch (e) {
        // If API fails, return basic user info from Firebase
        return AppUser(
          uid: user.uid,
          phoneNumber: user.phoneNumber ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
        );
      }
    });
  }

  @override
  AppUser? get currentUser {
    // Return cached API user if available
    if (_cachedApiUser != null) {
      return _cachedApiUser;
    }

    final user = _auth.currentUser;
    if (user == null) return null;

    return AppUser(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification (Android only)
        // We don't auto-sign in, let user enter OTP manually
      },
      verificationFailed: (FirebaseAuthException e) {
        String message;
        switch (e.code) {
          case 'invalid-phone-number':
            message = 'Invalid phone number format';
            break;
          case 'too-many-requests':
            message = 'Too many attempts. Please try again later';
            break;
          case 'quota-exceeded':
            message = 'SMS quota exceeded. Please try again later';
            break;
          default:
            message = e.message ?? 'Failed to send OTP';
        }
        completer.completeError(AuthException(message: message, code: e.code));
      },
      codeSent: (String verificationId, int? resendToken) {
        _resendToken = resendToken;
        completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      forceResendingToken: _resendToken,
    );

    return completer.future;
  }

  @override
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException(message: 'Failed to sign in');
      }

      // Get Firebase ID token and store it for API authentication
      final token = await user.getIdToken();
      if (token != null) {
        await _apiClient.setToken(token);
      }

      // Sync with backend API - this will create user if not exists
      try {
        _cachedApiUser = await _userApiRepository.getMe();
        return _cachedApiUser!;
      } catch (e) {
        // If API call fails, return basic Firebase user info
        // The backend should create the user on first API call with valid token
        return AppUser(
          uid: user.uid,
          phoneNumber: user.phoneNumber ?? '',
          createdAt: DateTime.now(),
          isOnboardingComplete: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Invalid OTP. Please try again';
          break;
        case 'session-expired':
          message = 'OTP expired. Please request a new one';
          break;
        default:
          message = e.message ?? 'Verification failed';
      }
      throw AuthException(message: message, code: e.code);
    }
  }

  @override
  Future<void> updateProfile({
    required String displayName,
    required String location,
    String? photoUrl,
    String? email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'Not authenticated');
    }

    // Update Firebase Auth profile (optional, for local caching)
    await user.updateDisplayName(displayName);
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // Update profile via API and complete onboarding
    _cachedApiUser = await _userApiRepository.completeOnboarding(
      displayName: displayName,
      location: location,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<void> sendOtpViaEmail(String phoneNumber) async {
    // Not supported in Firebase auth flow — only used by JWT auth
    throw const AuthException(message: 'Email OTP fallback not available');
  }

  @override
  Future<void> signOut() async {
    await _apiClient.clearToken();
    _cachedApiUser = null;
    await _auth.signOut();
  }

  @override
  Future<bool> isOnboardingComplete() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check cached user first
    if (_cachedApiUser != null) {
      return _cachedApiUser!.isOnboardingComplete;
    }

    // Fetch from API
    try {
      _cachedApiUser = await _userApiRepository.getMe();
      return _cachedApiUser!.isOnboardingComplete;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AppUser?> getUserById(String userId) async {
    try {
      return await _userApiRepository.getPublicProfile(userId);
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('getUserById($userId) failed: $e');
        return true;
      }());
      return null;
    }
  }

  /// Refresh the Firebase token and update API client
  Future<void> refreshToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken(true);
      if (token != null) {
        await _apiClient.setToken(token);
      }
    }
  }

  @override
  Future<AppUser?> refreshCurrentUser() async {
    try {
      _cachedApiUser = await _userApiRepository.getMe();
      return _cachedApiUser;
    } catch (e) {
      return null;
    }
  }
}
