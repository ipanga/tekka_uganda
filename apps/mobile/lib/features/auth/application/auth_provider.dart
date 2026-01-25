import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/repositories/jwt_auth_repository.dart';
import '../data/repositories/user_api_repository.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Auth repository provider - uses JWT-based authentication with Twilio OTP
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final userApiRepository = ref.watch(userApiRepositoryProvider);

  return JwtAuthRepository(
    apiClient: apiClient,
    userApiRepository: userApiRepository,
  );
});

/// Auth state stream provider
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Current user ID provider - convenience provider
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// Check if onboarding is complete
final isOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.isOnboardingComplete();
});

/// Auth notifier for handling auth actions
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// Send OTP to phone number
  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final verificationId = await _repository.sendOtp(phoneNumber);
      state = state.copyWith(
        isLoading: false,
        verificationId: verificationId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Verify OTP
  Future<AppUser> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      throw Exception('No verification ID. Please request OTP first.');
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.verifyOtp(
        verificationId: state.verificationId!,
        otp: otp,
      );
      state = state.copyWith(isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Update profile (onboarding)
  Future<void> updateProfile({
    required String displayName,
    required String location,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateProfile(
        displayName: displayName,
        location: location,
        photoUrl: photoUrl,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth state
class AuthState {
  final bool isLoading;
  final String? error;
  final String? verificationId;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.verificationId,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? verificationId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

/// Auth notifier provider
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Public user provider - for viewing other user profiles
final publicUserProvider =
    FutureProvider.family<AppUser?, String>((ref, userId) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getUserById(userId);
});

/// User stats provider
final userStatsProvider =
    FutureProvider.family<UserStats?, String>((ref, userId) async {
  final userApiRepository = ref.watch(userApiRepositoryProvider);
  try {
    return await userApiRepository.getUserStats(userId);
  } catch (e) {
    return null;
  }
});

/// Current user stats provider
final currentUserStatsProvider = FutureProvider<UserStats?>((ref) async {
  final userApiRepository = ref.watch(userApiRepositoryProvider);
  try {
    return await userApiRepository.getMyStats();
  } catch (e) {
    return null;
  }
});

/// Blocked users provider
final blockedUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  final userApiRepository = ref.watch(userApiRepositoryProvider);
  try {
    return await userApiRepository.getBlockedUsers();
  } catch (e) {
    return [];
  }
});

/// User profile notifier for profile management actions
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserApiRepository _userApiRepository;

  UserProfileNotifier(this._userApiRepository) : super(const UserProfileState());

  /// Update current user's profile
  Future<AppUser> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _userApiRepository.updateMe(
        displayName: displayName,
        bio: bio,
        location: location,
        photoUrl: photoUrl,
      );
      state = state.copyWith(isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _userApiRepository.blockUser(userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _userApiRepository.unblockUser(userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Register FCM token for push notifications
  Future<void> registerFcmToken(String token, {String platform = 'android'}) async {
    try {
      await _userApiRepository.registerFcmToken(token, platform);
    } catch (e) {
      // Silently fail - FCM registration is not critical
    }
  }

  /// Remove FCM token
  Future<void> removeFcmToken(String token) async {
    try {
      await _userApiRepository.removeFcmToken(token);
    } catch (e) {
      // Silently fail
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// User profile state
class UserProfileState {
  final bool isLoading;
  final String? error;

  const UserProfileState({
    this.isLoading = false,
    this.error,
  });

  UserProfileState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// User profile notifier provider
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  final userApiRepository = ref.watch(userApiRepositoryProvider);
  return UserProfileNotifier(userApiRepository);
});
