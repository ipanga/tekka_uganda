import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../data/repositories/meetup_api_repository.dart';
import '../domain/entities/meetup_location.dart';
import '../domain/repositories/meetup_repository.dart';

/// Meetup repository provider - uses API backend
final meetupRepositoryProvider = Provider<MeetupRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MeetupApiRepository(apiClient);
});

/// Safe meetup locations provider
final safeLocationsProvider = FutureProvider<List<MeetupLocation>>((ref) async {
  final repository = ref.watch(meetupRepositoryProvider);
  return repository.getSafeLocations();
});

/// Locations by area provider
final locationsByAreaProvider =
    FutureProvider.family<List<MeetupLocation>, String>((ref, area) async {
      final repository = ref.watch(meetupRepositoryProvider);
      return repository.getLocationsByArea(area);
    });

/// Single location provider
final meetupLocationProvider = FutureProvider.family<MeetupLocation?, String>((
  ref,
  locationId,
) async {
  final repository = ref.watch(meetupRepositoryProvider);
  return repository.getLocationById(locationId);
});

/// Meetups for a chat provider
final chatMeetupsProvider =
    FutureProvider.family<List<ScheduledMeetup>, String>((ref, chatId) async {
      final repository = ref.watch(meetupRepositoryProvider);
      return repository.getMeetupsForChat(chatId);
    });

/// User's upcoming meetups provider
final upcomingMeetupsProvider =
    FutureProvider.family<List<ScheduledMeetup>, String>((ref, userId) async {
      final repository = ref.watch(meetupRepositoryProvider);
      return repository.getUpcomingMeetups(userId);
    });

/// Single meetup provider
final scheduledMeetupProvider = FutureProvider.family<ScheduledMeetup?, String>(
  (ref, meetupId) async {
    final repository = ref.watch(meetupRepositoryProvider);
    return repository.getMeetupById(meetupId);
  },
);

/// State for scheduling a meetup
class ScheduleMeetupState {
  final bool isLoading;
  final String? error;
  final MeetupLocation? selectedLocation;
  final DateTime? selectedDate;
  final String? notes;
  final ScheduledMeetup? createdMeetup;

  const ScheduleMeetupState({
    this.isLoading = false,
    this.error,
    this.selectedLocation,
    this.selectedDate,
    this.notes,
    this.createdMeetup,
  });

  ScheduleMeetupState copyWith({
    bool? isLoading,
    String? error,
    MeetupLocation? selectedLocation,
    DateTime? selectedDate,
    String? notes,
    ScheduledMeetup? createdMeetup,
  }) {
    return ScheduleMeetupState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedDate: selectedDate ?? this.selectedDate,
      notes: notes ?? this.notes,
      createdMeetup: createdMeetup ?? this.createdMeetup,
    );
  }

  bool get isValid => selectedLocation != null && selectedDate != null;
}

/// Notifier for scheduling meetups
class ScheduleMeetupNotifier extends StateNotifier<ScheduleMeetupState> {
  final MeetupRepository _repository;
  final String chatId;
  final String listingId;
  final String buyerId;
  final String sellerId;

  ScheduleMeetupNotifier(
    this._repository, {
    required this.chatId,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
  }) : super(const ScheduleMeetupState());

  void selectLocation(MeetupLocation location) {
    state = state.copyWith(selectedLocation: location);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<ScheduledMeetup?> scheduleMeetup() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please select a location and time');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final meetup = await _repository.scheduleMeetup(
        chatId: chatId,
        listingId: listingId,
        buyerId: buyerId,
        sellerId: sellerId,
        location: state.selectedLocation!,
        scheduledAt: state.selectedDate!,
        notes: state.notes,
      );

      state = state.copyWith(isLoading: false, createdMeetup: meetup);

      return meetup;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const ScheduleMeetupState();
  }
}

/// Parameters for schedule meetup provider
class ScheduleMeetupParams {
  final String chatId;
  final String listingId;
  final String buyerId;
  final String sellerId;

  const ScheduleMeetupParams({
    required this.chatId,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleMeetupParams &&
        other.chatId == chatId &&
        other.listingId == listingId &&
        other.buyerId == buyerId &&
        other.sellerId == sellerId;
  }

  @override
  int get hashCode => Object.hash(chatId, listingId, buyerId, sellerId);
}

/// Schedule meetup notifier provider
final scheduleMeetupProvider = StateNotifierProvider.family
    .autoDispose<
      ScheduleMeetupNotifier,
      ScheduleMeetupState,
      ScheduleMeetupParams
    >((ref, params) {
      final repository = ref.watch(meetupRepositoryProvider);
      return ScheduleMeetupNotifier(
        repository,
        chatId: params.chatId,
        listingId: params.listingId,
        buyerId: params.buyerId,
        sellerId: params.sellerId,
      );
    });

/// Meetup actions notifier for confirming, canceling, etc.
class MeetupActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final MeetupRepository _repository;
  final String meetupId;

  MeetupActionsNotifier(this._repository, this.meetupId)
    : super(const AsyncValue.data(null));

  Future<void> confirm() async {
    state = const AsyncValue.loading();
    try {
      await _repository.confirmMeetup(meetupId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancel(String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelMeetup(meetupId, reason);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> complete() async {
    state = const AsyncValue.loading();
    try {
      await _repository.completeMeetup(meetupId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markNoShow() async {
    state = const AsyncValue.loading();
    try {
      await _repository.markNoShow(meetupId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Meetup actions provider
final meetupActionsProvider = StateNotifierProvider.family
    .autoDispose<MeetupActionsNotifier, AsyncValue<void>, String>((
      ref,
      meetupId,
    ) {
      final repository = ref.watch(meetupRepositoryProvider);
      return MeetupActionsNotifier(repository, meetupId);
    });
