import '../entities/report.dart';

/// Repository interface for report operations
abstract class ReportRepository {
  /// Create a new report
  Future<Report> createReport(
    CreateReportRequest request,
    String reporterId,
    String reporterName,
  );

  /// Get reports submitted by a user
  Future<List<Report>> getReportsByReporter(String reporterId);

  /// Check if user has already reported another user
  Future<bool> hasReported(String reporterId, String reportedUserId);

  /// Block a user
  Future<void> blockUser(String userId, String blockedUserId);

  /// Unblock a user
  Future<void> unblockUser(String userId, String blockedUserId);

  /// Get blocked users
  Future<List<String>> getBlockedUsers(String userId);

  /// Check if user is blocked
  Future<bool> isBlocked(String userId, String otherUserId);
}
