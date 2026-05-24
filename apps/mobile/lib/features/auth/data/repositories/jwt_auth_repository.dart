import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/api_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'user_api_repository.dart';

/// Outcome of a refresh-token attempt. We can't use a single boolean because
/// "the server rejected the refresh token" (real logout) and "we couldn't
/// reach the server" (transient — keep the session) are two very different
/// situations that the caller has to react to differently.
enum _RefreshOutcome {
  /// New tokens issued — caller can resume the session.
  success,

  /// Backend explicitly rejected the refresh token (HTTP 401). Wipe state.
  invalid,

  /// We couldn't verify the token (timeout, 5xx, no connection, etc.).
  /// Leave tokens in storage so the next attempt can recover.
  transient,
}

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
  }) : _apiClient = apiClient,
       _userApiRepository = userApiRepository {
    // Wire session expiry callback. ApiClient now only fires this when the
    // backend genuinely rejects the refresh token (HTTP 401 from
    // /auth/refresh) or when there's no refresh token at all. Transient
    // failures don't trigger this path, so a fire here is a real logout —
    // we drop the cached user blob so we don't hydrate a stale session on
    // the next cold start.
    _apiClient.onSessionExpired = () {
      _cachedUser = null;
      _apiClient.clearCachedUser();
      _authStateController.add(null);
    };
    // Check initial auth state
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    final token = await _apiClient.getToken();
    if (token == null) {
      _authStateController.add(null);
      return;
    }

    // Have a token — try to validate it by fetching the user. The auth
    // interceptor in ApiClient handles 401 → refresh automatically, so
    // getMe() succeeds when either the access token is good or refresh
    // produced a new one. Any exception here means we couldn't confirm
    // the session, which splits into two cases:
    //
    //   * UNAUTHORIZED — access token bad AND refresh either also bad
    //     (real logout) or unverifiable. We do a second explicit refresh
    //     attempt to discriminate; if it returns `invalid`, we sign out.
    //
    //   * Anything else (TIMEOUT, NO_CONNECTION, SERVER_ERROR, ...) —
    //     transient. Keep the tokens in storage and hydrate the user from
    //     the on-disk cache so the app boots into the signed-in state.
    //     A future request will retry and either succeed or surface a
    //     real auth failure.
    try {
      final user = await _userApiRepository.getMe();
      _cachedUser = user;
      _authStateController.add(_cachedUser);
      // Refresh the on-disk cache so the next cold start can hydrate
      // from a recent snapshot when /me is unreachable.
      await _persistCachedUser(user);
      return;
    } on ApiException catch (e) {
      if (e.code == 'UNAUTHORIZED') {
        final outcome = await _tryRefreshToken();
        switch (outcome) {
          case _RefreshOutcome.success:
            // _tryRefreshToken already populated _cachedUser + emitted.
            return;
          case _RefreshOutcome.invalid:
            await _apiClient.clearToken();
            await _apiClient.clearRefreshToken();
            await _apiClient.clearCachedUser();
            _authStateController.add(null);
            return;
          case _RefreshOutcome.transient:
            // Fall through to cached-user hydration below.
            break;
        }
      }
      // Transient API failure (timeout / 5xx / no-connection / refresh
      // couldn't reach the server). Don't wipe — keep the user signed in
      // off the disk cache.
      await _hydrateFromCachedUser();
    } catch (e) {
      // Non-ApiException (e.g. JSON parse failure, secure-storage glitch).
      // Treat as transient: never sign the user out on a client-side bug.
      debugPrint('JwtAuthRepository: unexpected getMe() failure: $e');
      await _hydrateFromCachedUser();
    }
  }

  Future<_RefreshOutcome> _tryRefreshToken() async {
    final refreshToken = await _apiClient.getRefreshToken();
    if (refreshToken == null) return _RefreshOutcome.invalid;

    try {
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
      await _persistCachedUser(_cachedUser!);
      _authStateController.add(_cachedUser);
      return _RefreshOutcome.success;
    } on ApiException catch (e) {
      // 401 from /auth/refresh = the refresh token is genuinely invalid
      // (revoked, expired, or never existed on the server). Anything else
      // (TIMEOUT, NO_CONNECTION, SERVER_ERROR, ...) means we couldn't tell
      // — assume transient and let the session ride.
      if (e.code == 'UNAUTHORIZED') return _RefreshOutcome.invalid;
      return _RefreshOutcome.transient;
    } catch (e) {
      debugPrint('JwtAuthRepository: refresh unexpected failure: $e');
      return _RefreshOutcome.transient;
    }
  }

  Future<void> _hydrateFromCachedUser() async {
    final cachedJson = await _apiClient.getCachedUser();
    if (cachedJson == null) {
      // No on-disk snapshot to fall back to. Emit null so the router can
      // settle on the public-browsing state instead of staying in the
      // AsyncLoading stripe forever. A background revalidate (e.g. the
      // AppLockWrapper resume hook in PR #2) will retry.
      _authStateController.add(null);
      return;
    }
    try {
      final map = jsonDecode(cachedJson) as Map<String, dynamic>;
      _cachedUser = AppUser.fromJson(map);
      _authStateController.add(_cachedUser);
    } catch (e) {
      debugPrint('JwtAuthRepository: cached user blob unreadable: $e');
      await _apiClient.clearCachedUser();
      _authStateController.add(null);
    }
  }

  Future<void> _persistCachedUser(AppUser user) async {
    try {
      await _apiClient.setCachedUser(jsonEncode(user.toJson()));
    } catch (e) {
      // Cache miss-on-write isn't fatal — next successful getMe() will retry.
      debugPrint('JwtAuthRepository: failed to persist cached user: $e');
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _cachedUser;

  // Email fallback info from last sendOtp response
  bool _hasEmail = false;
  String? _emailHint;

  /// Whether the user has an email on file (from last sendOtp response)
  bool get hasEmail => _hasEmail;

  /// Masked email hint (from last sendOtp response)
  String? get emailHint => _emailHint;

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

      final response = await _apiClient.postWithoutAuth<Map<String, dynamic>>(
        '/auth/send-otp',
        data: {'phone': formattedPhone},
      );

      // Capture email fallback info
      _hasEmail = response['hasEmail'] == true;
      _emailHint = response['emailHint'] as String?;

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
        data: {'phone': phoneNumber, 'code': otp},
      );

      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      // Store tokens
      await _apiClient.setToken(accessToken);
      await _apiClient.setRefreshToken(refreshToken);

      // Parse and cache user
      _cachedUser = AppUser.fromJson(userData);
      await _persistCachedUser(_cachedUser!);
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
    String? email,
  }) async {
    try {
      _cachedUser = await _userApiRepository.completeOnboarding(
        displayName: displayName,
        location: location,
        photoUrl: photoUrl,
        email: email,
      );
      await _persistCachedUser(_cachedUser!);
      _authStateController.add(_cachedUser);
    } catch (e) {
      if (e is ApiException) {
        throw AuthException(message: e.message, code: e.code);
      }
      throw AuthException(message: 'Failed to update profile: $e');
    }
  }

  @override
  Future<void> sendOtpViaEmail(String phoneNumber) async {
    try {
      String formattedPhone = phoneNumber.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+256${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+256$formattedPhone';
      }

      await _apiClient.postWithoutAuth<Map<String, dynamic>>(
        '/auth/send-otp-email',
        data: {'phone': formattedPhone},
      );
    } catch (e) {
      if (e is ApiException) {
        throw AuthException(message: e.message, code: e.code);
      }
      throw AuthException(message: 'Failed to send OTP via email: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _apiClient.clearToken();
    await _apiClient.clearRefreshToken();
    await _apiClient.clearCachedUser();
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
      await _persistCachedUser(_cachedUser!);
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
      debugPrint('getUserById($userId) failed: $e');
      return null;
    }
  }

  /// Refresh the access token
  Future<void> refreshToken() async {
    await _tryRefreshToken();
  }

  /// Get current user from API (force refresh). Used by the
  /// long-inactivity resume hook to proactively revalidate the session
  /// after the app comes back from background. Transient failures here
  /// must not wipe the cached user — that's why this returns the *current*
  /// cached user rather than null on failure, and only calls the wire on
  /// the success path.
  @override
  Future<AppUser?> refreshCurrentUser() async {
    try {
      final user = await _userApiRepository.getMe();
      _cachedUser = user;
      await _persistCachedUser(user);
      _authStateController.add(_cachedUser);
      return _cachedUser;
    } catch (e) {
      debugPrint('JwtAuthRepository.refreshCurrentUser failed: $e');
      return _cachedUser;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
