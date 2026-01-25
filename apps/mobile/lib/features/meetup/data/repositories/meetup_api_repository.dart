import '../../../../core/services/api_client.dart';
import '../../domain/entities/meetup_location.dart';
import '../../domain/repositories/meetup_repository.dart';

/// API-based implementation of MeetupRepository
class MeetupApiRepository implements MeetupRepository {
  final ApiClient _apiClient;

  MeetupApiRepository(this._apiClient);

  @override
  Future<List<MeetupLocation>> getSafeLocations() async {
    final response = await _apiClient.get<List<dynamic>>('/meetups/locations');
    return response
        .map((e) => MeetupLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MeetupLocation>> getLocationsByArea(String area) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/meetups/locations',
      queryParameters: {'area': area},
    );
    return response
        .map((e) => MeetupLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MeetupLocation>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    // For now, return all locations and filter client-side
    // A proper implementation would require geo-query support in the API
    final locations = await getSafeLocations();
    return locations.where((loc) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        loc.latitude,
        loc.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple distance calculation (not accurate for large distances)
    const kmPerDegree = 111.0;
    final latDiff = (lat2 - lat1).abs() * kmPerDegree;
    final lonDiff = (lon2 - lon1).abs() * kmPerDegree * 0.85; // Approximate at equator
    return (latDiff * latDiff + lonDiff * lonDiff).sqrt();
  }

  @override
  Future<MeetupLocation?> getLocationById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/meetups/locations/$id',
      );
      return MeetupLocation.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ScheduledMeetup> scheduleMeetup({
    required String chatId,
    required String listingId,
    required String buyerId,
    required String sellerId,
    required MeetupLocation location,
    required DateTime scheduledAt,
    String? notes,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/meetups',
      data: {
        'chatId': chatId,
        'listingId': listingId,
        'otherUserId': sellerId, // The other participant
        'locationId': location.id,
        'scheduledAt': scheduledAt.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    );
    return ScheduledMeetup.fromJson(response);
  }

  @override
  Future<ScheduledMeetup?> getMeetupById(String id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/meetups/$id',
      );
      return ScheduledMeetup.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ScheduledMeetup>> getMeetupsForChat(String chatId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/meetups/chat/$chatId',
    );
    return response
        .map((e) => ScheduledMeetup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ScheduledMeetup>> getUpcomingMeetups(String userId) async {
    final response = await _apiClient.get<List<dynamic>>('/meetups/upcoming');
    return response
        .map((e) => ScheduledMeetup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateMeetupStatus(String meetupId, MeetupStatus status) async {
    switch (status) {
      case MeetupStatus.confirmed:
        await confirmMeetup(meetupId);
        break;
      case MeetupStatus.cancelled:
        await cancelMeetup(meetupId, null);
        break;
      case MeetupStatus.completed:
        await completeMeetup(meetupId);
        break;
      case MeetupStatus.noShow:
        await markNoShow(meetupId);
        break;
      default:
        break;
    }
  }

  @override
  Future<void> confirmMeetup(String meetupId) async {
    await _apiClient.put('/meetups/$meetupId/accept');
  }

  @override
  Future<void> cancelMeetup(String meetupId, String? reason) async {
    await _apiClient.put<Map<String, dynamic>>(
      '/meetups/$meetupId/cancel',
      data: {
        if (reason != null) 'reason': reason,
      },
    );
  }

  @override
  Future<void> completeMeetup(String meetupId) async {
    await _apiClient.put('/meetups/$meetupId/complete');
  }

  @override
  Future<void> markNoShow(String meetupId) async {
    await _apiClient.put('/meetups/$meetupId/no-show');
  }

  @override
  Future<void> incrementLocationUsage(String locationId) async {
    // This is handled server-side when meetup is completed
    // No client-side action needed
  }
}

// Extension for sqrt
extension on double {
  double sqrt() => this < 0 ? 0 : isNaN ? 0 : isInfinite ? 0 : _sqrt(this);

  static double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
