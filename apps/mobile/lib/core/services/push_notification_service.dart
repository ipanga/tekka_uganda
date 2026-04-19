import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/auth/data/repositories/user_api_repository.dart';
import 'deep_link_mapper.dart';

/// Top-level handler for background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

/// Android notification channels — must match ids used by backend
/// (`apps/api/src/notifications/notifications.service.ts :: getChannelId`).
const _androidChannels = <AndroidNotificationChannel>[
  AndroidNotificationChannel(
    'messages',
    'Messages',
    description: 'New chat messages',
    importance: Importance.high,
  ),
  AndroidNotificationChannel(
    'reviews',
    'Reviews',
    description: 'New reviews on your profile',
    importance: Importance.defaultImportance,
  ),
  AndroidNotificationChannel(
    'listings',
    'Listings',
    description: 'Listing approvals, rejections and status',
    importance: Importance.defaultImportance,
  ),
  AndroidNotificationChannel(
    'price_alerts',
    'Price alerts',
    description: 'Price drops on saved items',
    importance: Importance.defaultImportance,
  ),
  AndroidNotificationChannel(
    'meetups',
    'Meetups',
    description: 'Meetup proposals and updates',
    importance: Importance.high,
  ),
  AndroidNotificationChannel(
    'system',
    'System',
    description: 'System announcements',
    importance: Importance.low,
  ),
  AndroidNotificationChannel(
    'default',
    'General',
    description: 'General notifications',
    importance: Importance.defaultImportance,
  ),
];

/// Push notification service for FCM
class PushNotificationService {
  final UserApiRepository _userApiRepository;

  /// Called when a user taps a notification. Set from the app layer so the
  /// callback has access to the live `GoRouter` instance.
  void Function(String route, Map<String, dynamic> data)? onNotificationTap;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;
  bool _initialized = false;
  Future<void>? _initFuture;

  PushNotificationService({
    required UserApiRepository userApiRepository,
    this.onNotificationTap,
  }) : _userApiRepository = userApiRepository;

  bool get isInitialized => _initialized;

  /// Initialize push notifications — call after user is authenticated.
  /// Idempotent: concurrent callers all await the same underlying init, so
  /// message/token listeners are attached exactly once per process.
  Future<void> initialize() => _initFuture ??= _doInitialize();

  Future<void> _doInitialize() async {
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

      // iOS: show alerts in-foreground too. Without this, iOS silently drops
      // banners while the app is active.
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      await _initLocalNotifications();

      // Attach listeners FIRST. On iOS, the FCM token is only available after
      // APNs registration completes; if we wait for the token synchronously
      // we can miss it. onTokenRefresh fires once APNs is ready.
      messaging.onTokenRefresh.listen(_registerToken);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // iOS requires an APNs token before FCM can mint one. Poll briefly —
      // the simulator / a slow first-run device may not have it instantly.
      if (Platform.isIOS) {
        for (var i = 0; i < 10; i++) {
          final apns = await messaging.getAPNSToken();
          if (apns != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }

      // Attempt to grab the FCM token up-front. If it's not yet available
      // (common on iOS cold start), onTokenRefresh will deliver it shortly.
      try {
        final token = await messaging.getToken();
        if (token != null) {
          debugPrint('====== FCM_TOKEN ======');
          debugPrint(token);
          debugPrint('====== END FCM_TOKEN ======');
          await _registerToken(token);
        }
      } catch (e) {
        debugPrint('Initial FCM token fetch failed (will retry via onTokenRefresh): $e');
      }

      // Check if app was opened from a terminated state notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      debugPrint('Push notifications initialized');
    } catch (e) {
      debugPrint('Push notification init failed: $e');
      // Allow a retry on transient failure (e.g. permission dialog race).
      _initFuture = null;
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload) as Map<String, dynamic>;
          _routeFromData(decoded);
        } catch (e) {
          debugPrint('Local notification payload decode failed: $e');
        }
      },
    );

    if (Platform.isAndroid) {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      for (final channel in _androidChannels) {
        await android?.createNotificationChannel(channel);
      }
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
    final notification = message.notification;
    if (notification == null) {
      // Data-only payload — nothing to render.
      return;
    }

    final channelId =
        (message.data['channel_id'] as String?) ??
        _channelIdForType(message.data['type'] as String?);

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelNameForId(channelId),
          channelDescription: 'Foreground notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _routeFromData(message.data);
  }

  /// Resolves a target route from an FCM data payload.
  /// Priority: `deep_link` (canonical) > type-based fallback.
  void _routeFromData(Map<String, dynamic> data) {
    final deepLink = data['deep_link'] as String?;
    String? route;

    if (deepLink != null && deepLink.isNotEmpty) {
      final uri = Uri.tryParse(deepLink);
      if (uri != null) route = mapDeepLinkUri(uri);
    }

    route ??= _fallbackRouteForType(data);

    if (route != null) {
      onNotificationTap?.call(route, data.cast<String, dynamic>());
    }
  }

  /// Legacy type-based routing kept for backwards compatibility with
  /// older app installs where the backend did not yet send `deep_link`.
  String? _fallbackRouteForType(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'message':
      case 'new_message':
      case 'chat':
        final chatId = data['chatId'] as String?;
        return chatId != null ? '/chat/$chatId' : '/chat';
      case 'review':
      case 'new_review':
        final userId = data['userId'] as String?;
        return userId != null ? '/reviews/$userId' : '/profile';
      case 'listing_approved':
      case 'listing_rejected':
      case 'listing_suspended':
      case 'listing_sold':
        final listingId = data['listingId'] as String?;
        return listingId != null ? '/listing/$listingId' : null;
      case 'price_drop':
        final listingId = data['listingId'] as String?;
        return listingId != null ? '/listing/$listingId' : null;
      case 'meetup_proposed':
      case 'meetup_accepted':
        final meetupId = data['meetupId'] as String?;
        return meetupId != null ? '/meetups/$meetupId' : '/meetups';
      case 'system':
        return '/notifications';
      default:
        return null;
    }
  }

  String _channelIdForType(String? type) {
    switch (type) {
      case 'message':
      case 'new_message':
      case 'chat':
        return 'messages';
      case 'review':
      case 'new_review':
        return 'reviews';
      case 'listing_approved':
      case 'listing_rejected':
      case 'listing_suspended':
      case 'listing_sold':
        return 'listings';
      case 'price_drop':
        return 'price_alerts';
      case 'meetup_proposed':
      case 'meetup_accepted':
        return 'meetups';
      case 'system':
        return 'system';
      default:
        return 'default';
    }
  }

  String _channelNameForId(String id) {
    for (final channel in _androidChannels) {
      if (channel.id == id) return channel.name;
    }
    return 'General';
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
    _initFuture = null;
  }
}
