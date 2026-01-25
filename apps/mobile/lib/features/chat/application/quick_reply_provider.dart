import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/api_client.dart';
import '../../auth/application/auth_provider.dart';
import '../domain/entities/quick_reply_template.dart';

/// Quick reply API repository
class QuickReplyApiRepository {
  final ApiClient _apiClient;

  QuickReplyApiRepository(this._apiClient);

  Future<List<QuickReplyTemplate>> getTemplates() async {
    final response = await _apiClient.get<List<dynamic>>('/quick-replies');
    return response
        .map((e) => QuickReplyTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuickReplyTemplate> createTemplate({
    required String text,
    String? category,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/quick-replies',
      data: {
        'text': text,
        if (category != null) 'category': category,
        'isDefault': false,
      },
    );
    return QuickReplyTemplate.fromJson(response);
  }

  Future<void> updateTemplate(String id, String text, {String? category}) async {
    await _apiClient.put(
      '/quick-replies/$id',
      data: {
        'text': text,
        if (category != null) 'category': category,
      },
    );
  }

  Future<void> deleteTemplate(String id) async {
    await _apiClient.delete('/quick-replies/$id');
  }

  Future<void> recordUsage(String id) async {
    await _apiClient.put('/quick-replies/$id/usage');
  }

  Future<void> initializeDefaults() async {
    await _apiClient.post('/quick-replies/initialize');
  }

  Future<void> resetToDefaults() async {
    await _apiClient.post('/quick-replies/reset');
  }

  Stream<List<QuickReplyTemplate>> watchTemplates() {
    return _createPollingStream(
      () => getTemplates(),
      interval: const Duration(seconds: 60),
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

/// Quick reply repository provider
final quickReplyRepositoryProvider = Provider<QuickReplyApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuickReplyApiRepository(apiClient);
});

/// Stream of quick reply templates for current user
final quickReplyTemplatesStreamProvider =
    StreamProvider<List<QuickReplyTemplate>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    // Return default templates for unauthenticated users
    return Stream.value(getDefaultTemplates());
  }

  final repository = ref.watch(quickReplyRepositoryProvider);
  return repository.watchTemplates();
});

/// State for quick reply operations
class QuickReplyState {
  final bool isLoading;
  final String? errorMessage;
  final bool? lastOperationSuccess;

  const QuickReplyState({
    this.isLoading = false,
    this.errorMessage,
    this.lastOperationSuccess,
  });

  QuickReplyState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? lastOperationSuccess,
    bool clearError = false,
  }) {
    return QuickReplyState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastOperationSuccess: lastOperationSuccess ?? this.lastOperationSuccess,
    );
  }
}

/// Notifier for quick reply template operations
class QuickReplyNotifier extends StateNotifier<QuickReplyState> {
  final QuickReplyApiRepository _repository;
  final String _userId;

  QuickReplyNotifier(this._repository, this._userId)
      : super(const QuickReplyState());

  /// Initialize templates with defaults if user has none
  Future<void> initializeDefaults() async {
    if (_userId.isEmpty) return;

    try {
      await _repository.initializeDefaults();
    } catch (_) {
      // Silently fail - defaults will still be available from server
    }
  }

  /// Add a new custom template
  Future<bool> addTemplate(String text, {String? category}) async {
    if (_userId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please sign in to save templates',
        lastOperationSuccess: false,
      );
      return false;
    }

    if (text.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Template text cannot be empty',
        lastOperationSuccess: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.createTemplate(
        text: text.trim(),
        category: category ?? 'custom',
      );

      state = state.copyWith(
        isLoading: false,
        lastOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add template',
        lastOperationSuccess: false,
      );
      return false;
    }
  }

  /// Update a template
  Future<bool> updateTemplate(String id, String text, {String? category}) async {
    if (_userId.isEmpty) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.updateTemplate(id, text.trim(), category: category);

      state = state.copyWith(
        isLoading: false,
        lastOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update template',
        lastOperationSuccess: false,
      );
      return false;
    }
  }

  /// Delete a template
  Future<bool> deleteTemplate(String id) async {
    if (_userId.isEmpty) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.deleteTemplate(id);

      state = state.copyWith(
        isLoading: false,
        lastOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete template',
        lastOperationSuccess: false,
      );
      return false;
    }
  }

  /// Record usage of a template (increases usage count)
  Future<void> recordUsage(String id) async {
    if (_userId.isEmpty) return;

    try {
      await _repository.recordUsage(id);
    } catch (_) {
      // Silently fail
    }
  }

  /// Reset to default templates
  Future<bool> resetToDefaults() async {
    if (_userId.isEmpty) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.resetToDefaults();

      state = state.copyWith(
        isLoading: false,
        lastOperationSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to reset templates',
        lastOperationSuccess: false,
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for quick reply operations
final quickReplyProvider =
    StateNotifierProvider<QuickReplyNotifier, QuickReplyState>((ref) {
  final user = ref.watch(currentUserProvider);
  final repository = ref.watch(quickReplyRepositoryProvider);
  return QuickReplyNotifier(repository, user?.uid ?? '');
});
