import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';

/// Email verification state
enum EmailVerificationState {
  initial,
  sendingCode,
  codeSent,
  verifying,
  verified,
  error,
}

/// Email verification status
class EmailVerificationStatus {
  final EmailVerificationState state;
  final String? email;
  final String? errorMessage;
  final DateTime? codeSentAt;

  const EmailVerificationStatus({
    this.state = EmailVerificationState.initial,
    this.email,
    this.errorMessage,
    this.codeSentAt,
  });

  EmailVerificationStatus copyWith({
    EmailVerificationState? state,
    String? email,
    String? errorMessage,
    DateTime? codeSentAt,
  }) {
    return EmailVerificationStatus(
      state: state ?? this.state,
      email: email ?? this.email,
      errorMessage: errorMessage,
      codeSentAt: codeSentAt ?? this.codeSentAt,
    );
  }

  bool get canResendCode {
    if (codeSentAt == null) return true;
    return DateTime.now().difference(codeSentAt!).inSeconds >= 60;
  }

  int get secondsUntilResend {
    if (codeSentAt == null) return 0;
    final elapsed = DateTime.now().difference(codeSentAt!).inSeconds;
    return (60 - elapsed).clamp(0, 60);
  }
}

/// Email verification notifier
class EmailVerificationNotifier extends StateNotifier<EmailVerificationStatus> {
  final Ref _ref;
  String? _pendingEmail;

  EmailVerificationNotifier(this._ref) : super(const EmailVerificationStatus());

  /// Send verification code to email
  Future<void> sendVerificationCode(String email) async {
    state = state.copyWith(
      state: EmailVerificationState.sendingCode,
      email: email,
    );

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        state = state.copyWith(
          state: EmailVerificationState.error,
          errorMessage: 'Not authenticated',
        );
        return;
      }

      final repository = _ref.read(userApiRepositoryProvider);
      await repository.sendEmailVerificationCode(email);

      _pendingEmail = email;
      state = state.copyWith(
        state: EmailVerificationState.codeSent,
        codeSentAt: DateTime.now(),
      );
    } catch (e) {
      final errorMessage = e is AppException
          ? e.message
          : 'Failed to send verification code. Please try again.';
      state = state.copyWith(
        state: EmailVerificationState.error,
        errorMessage: errorMessage,
      );
    }
  }

  /// Verify the code entered by user
  Future<bool> verifyCode(String code) async {
    state = state.copyWith(state: EmailVerificationState.verifying);

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        state = state.copyWith(
          state: EmailVerificationState.error,
          errorMessage: 'Not authenticated',
        );
        return false;
      }

      final repository = _ref.read(userApiRepositoryProvider);
      final response = await repository.verifyEmailCode(code);

      state = state.copyWith(
        state: EmailVerificationState.verified,
        email: response['email'] as String?,
      );

      // Refresh user data from API so emailVerified status is up-to-date
      final authRepository = _ref.read(authRepositoryProvider);
      await authRepository.refreshCurrentUser();

      return true;
    } catch (e) {
      final errorMessage = e is AppException
          ? e.message
          : 'Verification failed. Please try again.';
      state = state.copyWith(
        state: EmailVerificationState.error,
        errorMessage: errorMessage,
      );
      return false;
    }
  }

  /// Resend verification code
  Future<void> resendCode() async {
    if (!state.canResendCode) return;
    if (_pendingEmail != null) {
      await sendVerificationCode(_pendingEmail!);
    }
  }

  /// Reset state
  void reset() {
    _pendingEmail = null;
    state = const EmailVerificationStatus();
  }
}

/// Email verification provider
final emailVerificationProvider =
    StateNotifierProvider<EmailVerificationNotifier, EmailVerificationStatus>(
      (ref) => EmailVerificationNotifier(ref),
    );

/// Provider to check if current user has verified email
final hasVerifiedEmailProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.emailVerified ?? false;
});

/// Provider to get current user's email
final userEmailProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.email;
});

/// Remove email from account
final removeEmailProvider = Provider((ref) {
  return () async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repository = ref.read(userApiRepositoryProvider);
    await repository.removeEmail();

    ref.invalidate(currentUserProvider);
  };
});
