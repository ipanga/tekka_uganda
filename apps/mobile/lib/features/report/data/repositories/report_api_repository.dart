import '../../../../core/services/api_client.dart';
import '../../../auth/data/repositories/user_api_repository.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';

/// API-based implementation of ReportRepository
///
/// Note: Reports are submitted through specific endpoints (chat reports, listing reports, etc.)
/// This repository primarily handles blocking functionality via the users API.
class ReportApiRepository implements ReportRepository {
  final ApiClient _apiClient;
  final UserApiRepository _userApiRepository;

  ReportApiRepository(this._apiClient, this._userApiRepository);

  @override
  Future<Report> createReport(
    CreateReportRequest request,
    String reporterId,
    String reporterName,
  ) async {
    // Submit report through the API
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/reports',
      data: {
        'reportedUserId': request.reportedUserId,
        'reason': request.reason.name.toUpperCase(),
        if (request.additionalDetails != null)
          'description': request.additionalDetails,
        if (request.listingId != null) 'reportedListingId': request.listingId,
      },
    );

    return Report(
      id: response['id'] as String,
      reporterId: reporterId,
      reporterName: reporterName,
      reportedUserId: request.reportedUserId,
      reportedUserName: request.reportedUserName,
      reason: request.reason,
      additionalDetails: request.additionalDetails,
      listingId: request.listingId,
      chatId: request.chatId,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<Report>> getReportsByReporter(String reporterId) async {
    // Reports by reporter are not typically needed in the mobile app
    // This would be an admin feature
    return [];
  }

  @override
  Future<bool> hasReported(String reporterId, String reportedUserId) async {
    // Check if user has already reported another user
    // This is not critical for the mobile app, return false to allow report attempts
    // The API will reject duplicate reports if needed
    return false;
  }

  @override
  Future<void> blockUser(String userId, String blockedUserId) async {
    await _userApiRepository.blockUser(blockedUserId);
  }

  @override
  Future<void> unblockUser(String userId, String blockedUserId) async {
    await _userApiRepository.unblockUser(blockedUserId);
  }

  @override
  Future<List<String>> getBlockedUsers(String userId) async {
    final blockedUsers = await _userApiRepository.getBlockedUsers();
    return blockedUsers.map((user) => user.uid).toList();
  }

  @override
  Future<bool> isBlocked(String userId, String otherUserId) async {
    final blockedUsers = await getBlockedUsers(userId);
    return blockedUsers.contains(otherUserId);
  }
}
