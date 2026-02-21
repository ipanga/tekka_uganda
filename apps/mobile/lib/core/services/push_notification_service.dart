import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/repositories/user_api_repository.dart';

/// Top-level handler for background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

/// Push notification service for FCM
class PushNotificationService {
  final UserApiRepository _userApiRepository;
  final void Function(String route, Map<String, dynamic> data)?
  onNotificationTap;

  String? _currentToken;
  bool _initialized = false;

  PushNotificationService({
    required UserApiRepository userApiRepository,
    this.onNotificationTap,
  }) : _userApiRepository = userApiRepository;

  bool get isInitialized => _initialized;

  /// Initialize push notifications — call after user is authenticated
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push notifications: permission denied');
        return;
      }

      // Get FCM token
      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen(_registerToken);

      // Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // When app is opened from a notification (background → foreground)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _initialized = true;
      debugPrint('Push notifications initialized');
    } catch (e) {
      debugPrint('Push notification init failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    _currentToken = token;
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _userApiRepository.registerFcmToken(token, platform);
      debugPrint('FCM token registered');
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // Foreground messages are shown as local notifications by the system
    // on Android 13+. On iOS, they are shown automatically.
    // For custom handling, you could use flutter_local_notifications here.
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;

    String? route;
    switch (type) {
      case 'new_message':
      case 'chat':
        final chatId = data['chatId'] as String?;
        if (chatId != null) route = '/chat/$chatId';
        break;
      case 'listing_approved':
      case 'listing_rejected':
        final listingId = data['listingId'] as String?;
        if (listingId != null) route = '/listing/$listingId';
        break;
      case 'new_review':
        route = '/profile';
        break;
    }

    if (route != null) {
      onNotificationTap?.call(route, data);
    }
  }

  /// Remove FCM token on sign out
  Future<void> cleanup() async {
    if (_currentToken != null) {
      try {
        await _userApiRepository.removeFcmToken(_currentToken!);
      } catch (e) {
        debugPrint('FCM token removal failed: $e');
      }
      _currentToken = null;
    }
    _initialized = false;
  }
}
