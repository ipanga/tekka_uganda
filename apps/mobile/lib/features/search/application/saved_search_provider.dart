import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/api_client.dart';
import '../../auth/application/auth_provider.dart';
import '../domain/entities/saved_search.dart';

/// Saved search API repository
class SavedSearchApiRepository {
  final ApiClient _apiClient;

  SavedSearchApiRepository(this._apiClient);

  Future<List<SavedSearch>> getSearches() async {
    final response = await _apiClient.get<List<dynamic>>('/saved-searches');
    return response
        .map((e) => SavedSearch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SavedSearch> createSearch({
    required String query,
    String? categoryId,
    String? categoryName,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? condition,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/saved-searches',
      data: {
        'query': query,
        if (categoryId != null) 'categoryId': categoryId,
        if (categoryName != null) 'categoryName': categoryName,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (location != null) 'location': location,
        if (condition != null) 'condition': condition,
        'notificationsEnabled': true,
      },
    );
    return SavedSearch.fromJson(response);
  }

  Future<void> toggleNotifications(String searchId, bool enabled) async {
    await _apiClient.put(
      '/saved-searches/$searchId/notifications',
      data: {'enabled': enabled},
    );
  }

  Future<void> clearNewMatches(String searchId) async {
    await _apiClient.put('/saved-searches/$searchId/clear-matches');
  }

  Future<void> deleteSearch(String searchId) async {
    await _apiClient.delete('/saved-searches/$searchId');
  }

  Future<void> deleteAll() async {
    await _apiClient.delete('/saved-searches');
  }

  Future<bool> isSearchSaved(String query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/saved-searches/check',
      queryParameters: {'query': query},
    );
    return response['isSaved'] as bool? ?? false;
  }

  Future<int> getSearchesWithMatchesCount() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/saved-searches/with-matches/count',
    );
    return response['count'] as int? ?? 0;
  }

  Stream<List<SavedSearch>> watchSearches() {
    return _createPollingStream(
      () => getSearches(),
      interval: const Duration(seconds: 30),
    );
  }

  Stream<T> _createPollingStream<T>(
    Future<T> Function() fetcher, {
    required Duration interval,
  }) {
    late StreamController<T> controller;
    Timer? timer;
    bool isDisposed = false;

    Future<void> poll() async {
      if (isDisposed) return;
      try {
        final data = await fetcher();
        if (!isDisposed) {
          controller.add(data);
        }
      } catch (e) {
        if (!isDisposed) {
          controller.addError(e);
        }
      }
    }

    controller = StreamController<T>(
      onListen: () {
        poll();
        timer = Timer.periodic(interval, (_) => poll());
      },
      onCancel: () {
        isDisposed = true;
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}

/// Saved search repository provider
final savedSearchRepositoryProvider = Provider<SavedSearchApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SavedSearchApiRepository(apiClient);
});

/// Stream of saved searches for current user
final savedSearchesStreamProvider = StreamProvider<List<SavedSearch>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(savedSearchRepositoryProvider);
  return repository.watchSearches();
});

/// Count of saved searches with new matches
final savedSearchesWithMatchesCountProvider = Provider<int>((ref) {
  final searchesAsync = ref.watch(savedSearchesStreamProvider);
  return searchesAsync.maybeWhen(
    data: (searches) => searches.where((s) => s.newMatchCount > 0).length,
    orElse: () => 0,
  );
});

/// State for saved search operations
class SavedSearchState {
  final bool isLoading;
  final String? errorMessage;
  final bool? lastOperationSuccess;

  const SavedSearchState({
    this.isLoading = false,
    this.errorMessage,
    this.lastOperationSuccess,
  });

  SavedSearchState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? lastOperationSuccess,
    bool clearError = false,
  }) {
    return SavedSearchState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastOperationSuccess: lastOperationSuccess ?? this.lastOperationSuccess,
    );
  }
}

/// Notifier for saved search operations
class SavedSearchNotifier extends StateNotifier<SavedSearchState> {
  final SavedSearchApiRepository _repository;
  final String _userId;

  SavedSearchNotifier(this._repository, this._userId)
      : super(const SavedSearchState());

  /// Save a new search
  Future<bool> saveSearch({
    required String query,
    String? categoryId,
    String? categoryName,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? condition,
  }) async {
    if (_userId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please sign in to save searches',
        lastOperationSuccess: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.createSearch(
        query: query,
        categoryId: categoryId,
        categoryName: categoryName,
        minPrice: minPrice,
        maxPrice: maxPrice,
        location: location,
        condition: condition,
      );

      state = state.copyWith(
        isLoading: false,
        lastOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save search: ${e.toString()}',
        lastOperationSuccess: false,
      );
      return false;
    }
  }

  /// Toggle notifications for a saved search
  Future<void> toggleNotifications(String searchId, bool enabled) async {
    if (_userId.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.toggleNotifications(searchId, enabled);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update notifications',
      );
    }
  }

  /// Clear new match count for a saved search
  Future<void> clearNewMatches(String searchId) async {
    if (_userId.isEmpty) return;

    try {
      await _repository.clearNewMatches(searchId);
    } catch (_) {
      // Silently fail
    }
  }

  /// Delete a saved search
  Future<bool> deleteSearch(String searchId) async {
    if (_userId.isEmpty) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.deleteSearch(searchId);

      state = state.copyWith(
        isLoading: false,
        lastOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete search',
        lastOperationSuccess: false,
      );
      return false;
    }
  }

  /// Clear all saved searches
  Future<bool> clearAll() async {
    if (_userId.isEmpty) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.deleteAll();

      state = state.copyWith(
        isLoading: false,
        lastOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to clear searches',
        lastOperationSuccess: false,
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for saved search operations
final savedSearchProvider =
    StateNotifierProvider<SavedSearchNotifier, SavedSearchState>((ref) {
  final user = ref.watch(currentUserProvider);
  final repository = ref.watch(savedSearchRepositoryProvider);
  return SavedSearchNotifier(repository, user?.uid ?? '');
});

/// Check if a search is already saved
final isSearchSavedProvider =
    FutureProvider.family<bool, String>((ref, query) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final repository = ref.watch(savedSearchRepositoryProvider);
  return repository.isSearchSaved(query);
});
