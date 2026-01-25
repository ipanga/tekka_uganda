import '../../../../core/services/api_client.dart';
import '../../domain/entities/app_user.dart';

/// Repository for user-related API calls
class UserApiRepository {
  final ApiClient _apiClient;

  UserApiRepository(this._apiClient);

  /// Get current user's profile
  Future<AppUser> getMe() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/users/me');
    return AppUser.fromJson(response);
  }

  /// Update current user's profile
  Future<AppUser> updateMe({
    String? displayName,
    String? bio,
    String? location,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (location != null) data['location'] = location;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    final response = await _apiClient.put<Map<String, dynamic>>(
      '/users/me',
      data: data,
    );
    return AppUser.fromJson(response);
  }

  /// Complete onboarding
  Future<AppUser> completeOnboarding({
    required String displayName,
    required String location,
    String? photoUrl,
  }) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/users/me',
      data: {
        'displayName': displayName,
        'location': location,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'isOnboardingComplete': true,
      },
    );
    return AppUser.fromJson(response);
  }

  /// Update user settings
  Future<void> updateSettings({
    bool? priceAlertsEnabled,
    String? language,
    String? defaultLocation,
    // Notification preferences
    bool? pushEnabled,
    bool? emailEnabled,
    bool? marketingEnabled,
    bool? messageNotifications,
    bool? offerNotifications,
    bool? reviewNotifications,
    bool? listingNotifications,
    bool? systemNotifications,
    bool? doNotDisturb,
    int? dndStartHour,
    int? dndEndHour,
    // Security settings
    bool? pinEnabled,
    bool? biometricEnabled,
    bool? loginAlerts,
    bool? requireTransactionConfirmation,
    int? transactionThreshold,
    bool? twoFactorEnabled,
  }) async {
    final data = <String, dynamic>{};
    if (priceAlertsEnabled != null) data['priceAlertsEnabled'] = priceAlertsEnabled;
    if (language != null) data['language'] = language;
    if (defaultLocation != null) data['defaultLocation'] = defaultLocation;
    if (pushEnabled != null) data['pushEnabled'] = pushEnabled;
    if (emailEnabled != null) data['emailEnabled'] = emailEnabled;
    if (marketingEnabled != null) data['marketingEnabled'] = marketingEnabled;
    if (messageNotifications != null) data['messageNotifications'] = messageNotifications;
    if (offerNotifications != null) data['offerNotifications'] = offerNotifications;
    if (reviewNotifications != null) data['reviewNotifications'] = reviewNotifications;
    if (listingNotifications != null) data['listingNotifications'] = listingNotifications;
    if (systemNotifications != null) data['systemNotifications'] = systemNotifications;
    if (doNotDisturb != null) data['doNotDisturb'] = doNotDisturb;
    if (dndStartHour != null) data['dndStartHour'] = dndStartHour;
    if (dndEndHour != null) data['dndEndHour'] = dndEndHour;
    if (pinEnabled != null) data['pinEnabled'] = pinEnabled;
    if (biometricEnabled != null) data['biometricEnabled'] = biometricEnabled;
    if (loginAlerts != null) data['loginAlerts'] = loginAlerts;
    if (requireTransactionConfirmation != null) data['requireTransactionConfirmation'] = requireTransactionConfirmation;
    if (transactionThreshold != null) data['transactionThreshold'] = transactionThreshold;
    if (twoFactorEnabled != null) data['twoFactorEnabled'] = twoFactorEnabled;

    await _apiClient.put('/users/me/settings', data: data);
  }

  /// Get user settings (including notification preferences)
  Future<Map<String, dynamic>> getSettings() async {
    return _apiClient.get<Map<String, dynamic>>('/users/me/settings');
  }

  /// Get current user's stats
  Future<UserStats> getMyStats() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/users/me/stats');
    return UserStats.fromJson(response);
  }

  /// Register FCM token for push notifications
  Future<void> registerFcmToken(String token, String platform) async {
    await _apiClient.post(
      '/users/me/fcm-token',
      data: {'token': token, 'platform': platform},
    );
  }

  /// Remove FCM token
  Future<void> removeFcmToken(String token) async {
    await _apiClient.delete('/users/me/fcm-token/$token');
  }

  /// Get blocked users
  Future<List<AppUser>> getBlockedUsers() async {
    final response = await _apiClient.get<List<dynamic>>('/users/me/blocked');
    return response.map((json) => AppUser.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    await _apiClient.post('/users/me/blocked/$userId');
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    await _apiClient.delete('/users/me/blocked/$userId');
  }

  /// Get public profile of any user
  Future<AppUser> getPublicProfile(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/users/$userId');
    return AppUser.fromJson(response);
  }

  /// Get stats of any user
  Future<UserStats> getUserStats(String userId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/users/$userId/stats');
    return UserStats.fromJson(response);
  }

  /// Get login sessions
  Future<List<Map<String, dynamic>>> getLoginSessions() async {
    final response = await _apiClient.get<List<dynamic>>('/users/me/sessions');
    return response.cast<Map<String, dynamic>>();
  }

  /// Terminate a specific session
  Future<void> terminateSession(String sessionId) async {
    await _apiClient.delete('/users/me/sessions/$sessionId');
  }

  /// Sign out from all devices
  Future<void> signOutAllDevices() async {
    await _apiClient.post('/users/me/sessions/sign-out-all');
  }

  /// Get verification status
  Future<Map<String, dynamic>> getVerificationStatus() async {
    return _apiClient.get<Map<String, dynamic>>('/users/me/verification-status');
  }

  // 2FA Methods

  /// Get 2FA status
  Future<Map<String, dynamic>> get2FAStatus() async {
    return _apiClient.get<Map<String, dynamic>>('/users/me/2fa');
  }

  /// Setup 2FA
  Future<Map<String, dynamic>> setup2FA(String method) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/users/me/2fa/setup',
      data: {'method': method},
    );
    return response;
  }

  /// Send SMS code for 2FA
  Future<Map<String, dynamic>> send2FASmsCode() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/users/me/2fa/send-sms',
    );
    return response;
  }

  /// Verify 2FA code
  Future<Map<String, dynamic>> verify2FACode(String code, String method) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/users/me/2fa/verify',
      data: {'code': code, 'method': method},
    );
    return response;
  }

  /// Disable 2FA
  Future<void> disable2FA() async {
    await _apiClient.delete('/users/me/2fa');
  }

  /// Regenerate backup codes
  Future<List<String>> regenerateBackupCodes() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/users/me/2fa/backup-codes',
    );
    return (response['backupCodes'] as List<dynamic>).cast<String>();
  }

  // Identity Verification Methods

  /// Get identity verification status
  Future<Map<String, dynamic>> getIdentityVerificationStatus() async {
    return _apiClient.get<Map<String, dynamic>>('/users/me/identity-verification');
  }

  /// Submit identity verification
  Future<Map<String, dynamic>> submitIdentityVerification({
    required String documentType,
    required String documentNumber,
    required String fullName,
    required String dateOfBirth,
    required String frontImageUrl,
    String? backImageUrl,
    String? selfieUrl,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/users/me/identity-verification',
      data: {
        'documentType': documentType,
        'documentNumber': documentNumber,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'frontImageUrl': frontImageUrl,
        if (backImageUrl != null) 'backImageUrl': backImageUrl,
        if (selfieUrl != null) 'selfieUrl': selfieUrl,
      },
    );
    return response;
  }

  // Email Verification Methods

  /// Send email verification code
  Future<Map<String, dynamic>> sendEmailVerificationCode(String email) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/users/me/email-verification/send',
      data: {'email': email},
    );
    return response;
  }

  /// Verify email code
  Future<Map<String, dynamic>> verifyEmailCode(String code) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/users/me/email-verification/verify',
      data: {'code': code},
    );
    return response;
  }

  /// Remove email from account
  Future<void> removeEmail() async {
    await _apiClient.delete('/users/me/email');
  }

  // Privacy Settings Methods

  /// Get privacy settings
  Future<Map<String, dynamic>> getPrivacySettings() async {
    return _apiClient.get<Map<String, dynamic>>('/users/me/privacy');
  }

  /// Update privacy settings
  Future<Map<String, dynamic>> updatePrivacySettings({
    String? profileVisibility,
    bool? showLocation,
    bool? showPhoneNumber,
    String? messagePermission,
    bool? showOnlineStatus,
    bool? showPurchaseHistory,
    bool? showListingsCount,
    bool? appearInSearch,
    bool? allowProfileSharing,
  }) async {
    final data = <String, dynamic>{};
    if (profileVisibility != null) data['profileVisibility'] = profileVisibility;
    if (showLocation != null) data['showLocation'] = showLocation;
    if (showPhoneNumber != null) data['showPhoneNumber'] = showPhoneNumber;
    if (messagePermission != null) data['messagePermission'] = messagePermission;
    if (showOnlineStatus != null) data['showOnlineStatus'] = showOnlineStatus;
    if (showPurchaseHistory != null) data['showPurchaseHistory'] = showPurchaseHistory;
    if (showListingsCount != null) data['showListingsCount'] = showListingsCount;
    if (appearInSearch != null) data['appearInSearch'] = appearInSearch;
    if (allowProfileSharing != null) data['allowProfileSharing'] = allowProfileSharing;

    final response = await _apiClient.put<Map<String, dynamic>>(
      '/users/me/privacy',
      data: data,
    );
    return response;
  }

  /// Get another user's privacy settings
  Future<Map<String, dynamic>> getUserPrivacySettings(String userId) async {
    return _apiClient.get<Map<String, dynamic>>('/users/$userId/privacy');
  }

  /// Check if current user can view target user's profile
  Future<bool> canViewProfile(String targetUserId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/me/can-view/$targetUserId',
    );
    return response['canView'] as bool? ?? false;
  }

  /// Check if current user can message target user
  Future<bool> canMessageUser(String targetUserId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/users/me/can-message/$targetUserId',
    );
    return response['canMessage'] as bool? ?? false;
  }
}
