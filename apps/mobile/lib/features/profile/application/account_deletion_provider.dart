import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/api_client.dart';
import '../../auth/application/auth_provider.dart';

/// Account deletion state
enum AccountDeletionState {
  initial,
  confirming,
  deleting,
  deleted,
  error,
  scheduledForDeletion,
}

/// Account deletion status
class AccountDeletionStatus {
  final AccountDeletionState state;
  final String? errorMessage;
  final DateTime? scheduledDeletionDate;
  final bool requiresReauth;

  const AccountDeletionStatus({
    this.state = AccountDeletionState.initial,
    this.errorMessage,
    this.scheduledDeletionDate,
    this.requiresReauth = false,
  });

  AccountDeletionStatus copyWith({
    AccountDeletionState? state,
    String? errorMessage,
    DateTime? scheduledDeletionDate,
    bool? requiresReauth,
  }) {
    return AccountDeletionStatus(
      state: state ?? this.state,
      errorMessage: errorMessage,
      scheduledDeletionDate:
          scheduledDeletionDate ?? this.scheduledDeletionDate,
      requiresReauth: requiresReauth ?? this.requiresReauth,
    );
  }

  bool get isScheduled => state == AccountDeletionState.scheduledForDeletion;

  int get daysUntilDeletion {
    if (scheduledDeletionDate == null) return 0;
    return scheduledDeletionDate!.difference(DateTime.now()).inDays;
  }
}

/// Account deletion API repository
class AccountDeletionApiRepository {
  final ApiClient _apiClient;

  AccountDeletionApiRepository(this._apiClient);

  Future<Map<String, dynamic>> getScheduledDeletion() async {
    return _apiClient.get<Map<String, dynamic>>('/users/me/deletion');
  }

  Future<Map<String, dynamic>> scheduleAccountDeletion({
    required String reason,
    int gracePeriodDays = 7,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/users/me/deletion',
      data: {'reason': reason, 'gracePeriodDays': gracePeriodDays},
    );
  }

  Future<void> cancelScheduledDeletion() async {
    await _apiClient.delete('/users/me/deletion');
  }

  Future<void> deleteAccountImmediately() async {
    await _apiClient.delete('/users/me');
  }
}

/// Account deletion repository provider
final accountDeletionRepositoryProvider =
    Provider<AccountDeletionApiRepository>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return AccountDeletionApiRepository(apiClient);
    });

/// Account deletion notifier
class AccountDeletionNotifier extends StateNotifier<AccountDeletionStatus> {
  final Ref _ref;
  final AccountDeletionApiRepository _repository;

  AccountDeletionNotifier(this._ref, this._repository)
    : super(const AccountDeletionStatus()) {
    _checkScheduledDeletion();
  }

  Future<void> _checkScheduledDeletion() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final response = await _repository.getScheduledDeletion();

      if (response['isScheduled'] == true) {
        final scheduledDate = DateTime.parse(
          response['scheduledDate'] as String,
        );

        state = state.copyWith(
          state: AccountDeletionState.scheduledForDeletion,
          scheduledDeletionDate: scheduledDate,
        );
      }
    } catch (e) {
      // Ignore errors on initial check
    }
  }

  /// Schedule account for deletion (with grace period)
  Future<bool> scheduleAccountDeletion({
    required String reason,
    int gracePeriodDays = 7,
  }) async {
    state = state.copyWith(state: AccountDeletionState.confirming);

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        state = state.copyWith(
          state: AccountDeletionState.error,
          errorMessage: 'Not authenticated',
        );
        return false;
      }

      final response = await _repository.scheduleAccountDeletion(
        reason: reason,
        gracePeriodDays: gracePeriodDays,
      );

      final scheduledDate = DateTime.parse(response['scheduledDate'] as String);

      state = state.copyWith(
        state: AccountDeletionState.scheduledForDeletion,
        scheduledDeletionDate: scheduledDate,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        state: AccountDeletionState.error,
        errorMessage: 'Failed to schedule deletion. Please try again.',
      );
      return false;
    }
  }

  /// Cancel scheduled account deletion
  Future<bool> cancelScheduledDeletion() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return false;

      await _repository.cancelScheduledDeletion();

      state = const AccountDeletionStatus();
      return true;
    } catch (e) {
      state = state.copyWith(
        state: AccountDeletionState.error,
        errorMessage: 'Failed to cancel deletion. Please try again.',
      );
      return false;
    }
  }

  /// Immediately delete account (no grace period)
  Future<bool> deleteAccountImmediately() async {
    state = state.copyWith(state: AccountDeletionState.deleting);

    try {
      final user = _ref.read(currentUserProvider);

      if (user == null) {
        state = state.copyWith(
          state: AccountDeletionState.error,
          errorMessage: 'Not authenticated',
        );
        return false;
      }

      // 1. Delete all user data via API
      await _repository.deleteAccountImmediately();

      // 2. Sign out (clears JWT tokens and local state)
      try {
        await _ref.read(authNotifierProvider.notifier).signOut();
      } catch (_) {
        // Sign out best-effort — account is already deleted on backend
      }

      state = state.copyWith(state: AccountDeletionState.deleted);
      return true;
    } catch (e) {
      state = state.copyWith(
        state: AccountDeletionState.error,
        errorMessage: 'Failed to delete account. Please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const AccountDeletionStatus();
  }
}

/// Account deletion provider
final accountDeletionProvider =
    StateNotifierProvider<AccountDeletionNotifier, AccountDeletionStatus>((
      ref,
    ) {
      final repository = ref.watch(accountDeletionRepositoryProvider);
      return AccountDeletionNotifier(ref, repository);
    });

/// Check if account is scheduled for deletion
final isAccountScheduledForDeletionProvider = Provider<bool>((ref) {
  final status = ref.watch(accountDeletionProvider);
  return status.isScheduled;
});

/// Deletion reasons for analytics
enum DeletionReason {
  notUsingAnymore,
  privacyConcerns,
  foundBetterAlternative,
  tooManyNotifications,
  badExperience,
  other,
}

extension DeletionReasonExtension on DeletionReason {
  String get displayName {
    switch (this) {
      case DeletionReason.notUsingAnymore:
        return "I'm not using the app anymore";
      case DeletionReason.privacyConcerns:
        return 'Privacy concerns';
      case DeletionReason.foundBetterAlternative:
        return 'Found a better alternative';
      case DeletionReason.tooManyNotifications:
        return 'Too many notifications';
      case DeletionReason.badExperience:
        return 'Bad experience with the app';
      case DeletionReason.other:
        return 'Other reason';
    }
  }
}
