import '../entities/meetup_location.dart';

/// Repository interface for meetup operations
abstract class MeetupRepository {
  /// Get all safe meetup locations
  Future<List<MeetupLocation>> getSafeLocations();

  /// Get safe locations by area
  Future<List<MeetupLocation>> getLocationsByArea(String area);

  /// Get nearby locations
  Future<List<MeetupLocation>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  });

  /// Get a single location by ID
  Future<MeetupLocation?> getLocationById(String id);

  /// Schedule a meetup
  Future<ScheduledMeetup> scheduleMeetup({
    required String chatId,
    required String listingId,
    required String buyerId,
    required String sellerId,
    required MeetupLocation location,
    required DateTime scheduledAt,
    String? notes,
  });

  /// Get meetup by ID
  Future<ScheduledMeetup?> getMeetupById(String id);

  /// Get meetups for a chat
  Future<List<ScheduledMeetup>> getMeetupsForChat(String chatId);

  /// Get user's upcoming meetups
  Future<List<ScheduledMeetup>> getUpcomingMeetups(String userId);

  /// Update meetup status
  Future<void> updateMeetupStatus(String meetupId, MeetupStatus status);

  /// Confirm a proposed meetup
  Future<void> confirmMeetup(String meetupId);

  /// Cancel a meetup
  Future<void> cancelMeetup(String meetupId, String reason);

  /// Mark meetup as completed
  Future<void> completeMeetup(String meetupId);

  /// Mark meetup as no-show
  Future<void> markNoShow(String meetupId);

  /// Increment usage count for a location
  Future<void> incrementLocationUsage(String locationId);
}
