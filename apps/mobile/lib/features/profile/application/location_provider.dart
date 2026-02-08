import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/repository_providers.dart';

/// Uganda regions/districts for location selection
enum UgandaRegion {
  // Central Region
  kampala,
  wakiso,
  mukono,
  entebbe,
  jinja,

  // Eastern Region
  mbale,
  soroti,
  tororo,

  // Western Region
  mbarara,
  fortPortal,
  kasese,
  kabale,

  // Northern Region
  gulu,
  lira,
  arua,
}

extension UgandaRegionX on UgandaRegion {
  String get displayName {
    switch (this) {
      case UgandaRegion.kampala:
        return 'Kampala';
      case UgandaRegion.wakiso:
        return 'Wakiso';
      case UgandaRegion.mukono:
        return 'Mukono';
      case UgandaRegion.entebbe:
        return 'Entebbe';
      case UgandaRegion.jinja:
        return 'Jinja';
      case UgandaRegion.mbale:
        return 'Mbale';
      case UgandaRegion.soroti:
        return 'Soroti';
      case UgandaRegion.tororo:
        return 'Tororo';
      case UgandaRegion.mbarara:
        return 'Mbarara';
      case UgandaRegion.fortPortal:
        return 'Fort Portal';
      case UgandaRegion.kasese:
        return 'Kasese';
      case UgandaRegion.kabale:
        return 'Kabale';
      case UgandaRegion.gulu:
        return 'Gulu';
      case UgandaRegion.lira:
        return 'Lira';
      case UgandaRegion.arua:
        return 'Arua';
    }
  }

  String get region {
    switch (this) {
      case UgandaRegion.kampala:
      case UgandaRegion.wakiso:
      case UgandaRegion.mukono:
      case UgandaRegion.entebbe:
      case UgandaRegion.jinja:
        return 'Central';
      case UgandaRegion.mbale:
      case UgandaRegion.soroti:
      case UgandaRegion.tororo:
        return 'Eastern';
      case UgandaRegion.mbarara:
      case UgandaRegion.fortPortal:
      case UgandaRegion.kasese:
      case UgandaRegion.kabale:
        return 'Western';
      case UgandaRegion.gulu:
      case UgandaRegion.lira:
      case UgandaRegion.arua:
        return 'Northern';
    }
  }

  static UgandaRegion fromString(String name) {
    return UgandaRegion.values.firstWhere(
      (r) =>
          r.name == name || r.displayName.toLowerCase() == name.toLowerCase(),
      orElse: () => UgandaRegion.kampala,
    );
  }

  /// Get all regions grouped by area
  static Map<String, List<UgandaRegion>> get grouped {
    return {
      'Central': UgandaRegion.values
          .where((r) => r.region == 'Central')
          .toList(),
      'Eastern': UgandaRegion.values
          .where((r) => r.region == 'Eastern')
          .toList(),
      'Western': UgandaRegion.values
          .where((r) => r.region == 'Western')
          .toList(),
      'Northern': UgandaRegion.values
          .where((r) => r.region == 'Northern')
          .toList(),
    };
  }
}

/// State for location preferences
class LocationPreferencesState {
  final UgandaRegion selectedLocation;
  final bool isLoading;
  final String? error;

  const LocationPreferencesState({
    this.selectedLocation = UgandaRegion.kampala,
    this.isLoading = false,
    this.error,
  });

  LocationPreferencesState copyWith({
    UgandaRegion? selectedLocation,
    bool? isLoading,
    String? error,
  }) {
    return LocationPreferencesState(
      selectedLocation: selectedLocation ?? this.selectedLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Storage key for location preference
const String _locationKey = 'default_location';

/// Provider for location preferences state
final locationPreferencesProvider =
    StateNotifierProvider<
      LocationPreferencesNotifier,
      LocationPreferencesState
    >((ref) => LocationPreferencesNotifier(ref));

/// Notifier for managing location preferences
class LocationPreferencesNotifier
    extends StateNotifier<LocationPreferencesState> {
  final Ref _ref;

  LocationPreferencesNotifier(this._ref)
    : super(const LocationPreferencesState()) {
    _loadLocation();
  }

  /// Load saved location preference
  Future<void> _loadLocation() async {
    state = state.copyWith(isLoading: true);

    try {
      // First try to load from local storage for quick access
      final prefs = await SharedPreferences.getInstance();
      final locationName = prefs.getString(_locationKey);

      if (locationName != null) {
        final location = UgandaRegionX.fromString(locationName);
        state = state.copyWith(selectedLocation: location, isLoading: false);
      }

      // Then sync with API
      try {
        final userApiRepository = _ref.read(userApiRepositoryProvider);
        final settings = await userApiRepository.getSettings();
        final apiLocation = settings['defaultLocation'] as String?;
        if (apiLocation != null && apiLocation.isNotEmpty) {
          final location = UgandaRegionX.fromString(apiLocation);
          state = state.copyWith(selectedLocation: location);
          // Update local storage
          await prefs.setString(_locationKey, location.name);
        }
      } catch (_) {
        // Non-critical - use local storage value
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load location preference',
      );
    }
  }

  /// Set the default location
  Future<bool> setLocation(UgandaRegion location) async {
    if (state.selectedLocation == location) return true;

    state = state.copyWith(isLoading: true);

    try {
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_locationKey, location.name);

      // Save to API
      try {
        final userApiRepository = _ref.read(userApiRepositoryProvider);
        await userApiRepository.updateSettings(
          defaultLocation: location.displayName,
        );
      } catch (_) {
        // Non-critical - location still saved locally
      }

      state = state.copyWith(selectedLocation: location, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save location preference',
      );
      return false;
    }
  }
}
