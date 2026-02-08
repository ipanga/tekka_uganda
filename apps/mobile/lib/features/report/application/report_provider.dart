import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../auth/application/auth_provider.dart';
import '../data/repositories/report_api_repository.dart';
import '../domain/entities/report.dart';
import '../domain/repositories/report_repository.dart';

/// Report repository provider - uses API backend
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final userApiRepository = ref.watch(userApiRepositoryProvider);
  return ReportApiRepository(apiClient, userApiRepository);
});

/// Check if current user has reported another user
final hasReportedProvider = FutureProvider.family<bool, String>((
  ref,
  reportedUserId,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final repository = ref.watch(reportRepositoryProvider);
  return repository.hasReported(user.uid, reportedUserId);
});

/// Check if a user is blocked
final isBlockedProvider = FutureProvider.family<bool, String>((
  ref,
  otherUserId,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final repository = ref.watch(reportRepositoryProvider);
  return repository.isBlocked(user.uid, otherUserId);
});

/// Get blocked user IDs list (from Firebase/Report system)
final blockedUserIdsProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(reportRepositoryProvider);
  return repository.getBlockedUsers(user.uid);
});

/// Report actions state
class ReportActionsState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const ReportActionsState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  ReportActionsState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return ReportActionsState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

/// Report actions notifier
class ReportActionsNotifier extends StateNotifier<ReportActionsState> {
  final ReportRepository _repository;
  final String _userId;
  final String _userName;

  ReportActionsNotifier(this._repository, this._userId, this._userName)
    : super(const ReportActionsState());

  Future<Report?> submitReport(CreateReportRequest request) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final report = await _repository.createReport(
        request,
        _userId,
        _userName,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return report;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> blockUser(String blockedUserId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.blockUser(_userId, blockedUserId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.unblockUser(_userId, blockedUserId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const ReportActionsState();
  }
}

/// Report actions provider
final reportActionsProvider =
    StateNotifierProvider.autoDispose<
      ReportActionsNotifier,
      ReportActionsState
    >((ref) {
      final user = ref.watch(currentUserProvider);
      final repository = ref.watch(reportRepositoryProvider);

      return ReportActionsNotifier(
        repository,
        user?.uid ?? '',
        user?.displayName ?? 'User',
      );
    });
