import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/services/api_client.dart';
import '../../auth/application/auth_provider.dart';
import '../../auth/data/repositories/user_api_repository.dart';
import '../domain/entities/price_alert.dart';

/// Price alert API repository
class PriceAlertApiRepository {
  final ApiClient _apiClient;

  PriceAlertApiRepository(this._apiClient);

  Future<List<PriceAlert>> getAlerts({int limit = 50}) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/price-alerts',
      queryParameters: {'limit': limit},
    );
    return response
        .map((e) => PriceAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/price-alerts/unread-count',
    );
    return response['unreadCount'] as int? ?? 0;
  }

  Future<void> markAsRead(String alertId) async {
    await _apiClient.put('/price-alerts/$alertId/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.put('/price-alerts/read-all');
  }

  Future<void> deleteAlert(String alertId) async {
    await _apiClient.delete('/price-alerts/$alertId');
  }

  Future<void> deleteAll() async {
    await _apiClient.delete('/price-alerts');
  }

  Stream<List<PriceAlert>> watchAlerts({int limit = 50}) {
    return _createPollingStream(
      () => getAlerts(limit: limit),
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

/// Price alert repository provider
final priceAlertRepositoryProvider = Provider<PriceAlertApiRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PriceAlertApiRepository(apiClient);
});

/// Stream of price alerts for current user
final priceAlertsStreamProvider = StreamProvider<List<PriceAlert>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repository = ref.watch(priceAlertRepositoryProvider);
  return repository.watchAlerts();
});

/// Count of unread price alerts
final unreadPriceAlertsCountProvider = Provider<int>((ref) {
  final alertsAsync = ref.watch(priceAlertsStreamProvider);
  return alertsAsync.maybeWhen(
    data: (alerts) => alerts.where((a) => !a.isRead && !a.isExpired).length,
    orElse: () => 0,
  );
});

/// State for price alert operations
class PriceAlertState {
  final bool isLoading;
  final String? errorMessage;
  final bool priceAlertsEnabled;

  const PriceAlertState({
    this.isLoading = false,
    this.errorMessage,
    this.priceAlertsEnabled = true,
  });

  PriceAlertState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? priceAlertsEnabled,
    bool clearError = false,
  }) {
    return PriceAlertState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      priceAlertsEnabled: priceAlertsEnabled ?? this.priceAlertsEnabled,
    );
  }
}

/// Notifier for price alert operations
class PriceAlertNotifier extends StateNotifier<PriceAlertState> {
  final PriceAlertApiRepository _repository;
  final UserApiRepository _userApiRepository;

  PriceAlertNotifier(this._repository, this._userApiRepository)
      : super(const PriceAlertState());

  /// Toggle price alerts on/off
  Future<void> togglePriceAlerts(bool enabled) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _userApiRepository.updateSettings(priceAlertsEnabled: enabled);
      state = state.copyWith(
        isLoading: false,
        priceAlertsEnabled: enabled,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update settings',
      );
    }
  }

  /// Mark a price alert as read
  Future<void> markAsRead(String alertId) async {
    try {
      await _repository.markAsRead(alertId);
    } catch (_) {
      // Silently fail
    }
  }

  /// Mark all price alerts as read
  Future<void> markAllAsRead() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.markAllAsRead();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to mark all as read',
      );
    }
  }

  /// Delete a price alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _repository.deleteAlert(alertId);
    } catch (_) {
      // Silently fail
    }
  }

  /// Clear all price alerts
  Future<void> clearAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.deleteAll();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to clear alerts',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for price alert operations
final priceAlertProvider =
    StateNotifierProvider<PriceAlertNotifier, PriceAlertState>((ref) {
  final repository = ref.watch(priceAlertRepositoryProvider);
  final userApiRepository = ref.watch(userApiRepositoryProvider);
  return PriceAlertNotifier(repository, userApiRepository);
});
