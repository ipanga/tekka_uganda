import '../entities/app_user.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Stream of auth state changes
  Stream<AppUser?> get authStateChanges;

  /// Get current user
  AppUser? get currentUser;

  /// Send OTP to phone number
  /// Returns verification ID on success
  Future<String> sendOtp(String phoneNumber);

  /// Verify OTP and sign in
  /// Returns user on success
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String otp,
  });

  /// Update user profile after onboarding
  Future<void> updateProfile({
    required String displayName,
    required String location,
    String? photoUrl,
    String? email,
  });

  /// Re-send the current OTP via email (fallback when SMS fails)
  Future<void> sendOtpViaEmail(String phoneNumber);

  /// Sign out current user
  Future<void> signOut();

  /// Check if user has completed onboarding
  Future<bool> isOnboardingComplete();

  /// Refresh current user data from the API
  Future<AppUser?> refreshCurrentUser();

  /// Get user by ID (public profile)
  Future<AppUser?> getUserById(String userId);
}
