import 'dart:convert';
import 'dart:developer' as developer;
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

/// Cold-start tap message captured at app boot, before auth has resolved.
///
/// Why a top-level cache: on iOS, `FirebaseMessaging.getInitialMessage()`
/// can silently return null if it isn't called soon after `runApp`. The
/// service's `initialize()` runs only after the user is authenticated
/// (gated in `main.dart`), which on a cold launch with stored creds can
/// take several seconds — long enough for the launch message to be lost.
///
/// `primeInitialMessage()` (invoked from `main()` right after Firebase init)
/// pulls the message immediately and stashes it here. The service replays
/// it from `_doInitialize()` once the auth-gated init runs.
RemoteMessage? _bootInitialMessage;

/// Capture the cold-start tap message as early as possible. Safe to call
/// before any user is signed in — the message is just held in memory.
/// Idempotent: only the first non-null result wins; subsequent calls are
/// no-ops.
///
/// **Never call with `await` from `main()`.** `getInitialMessage()` can
/// block on iOS if APNs setup hasn't completed yet (no APNs token, slow
/// boot, certain low-network conditions); awaiting it from `main` would
/// stall before `runApp` and leave the user staring at a blank screen.
/// Fire-and-forget instead: this populates the top-level cache when (and
/// if) the platform answers, and the auth-gated `_doInitialize()` reads
/// it later (or falls back to a fresh call if the prime hadn't completed
/// in time).
///
/// A defensive 5-second timeout caps the worst case so this future
/// resolves even when the platform never answers. Returns the cached
/// message at resolution time.
Future<RemoteMessage?> primeInitialMessage() async {
  if (_bootInitialMessage != null) return _bootInitialMessage;
  try {
    final msg = await FirebaseMessaging.instance.getInitialMessage().timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
    if (msg != null) {
      _bootInitialMessage = msg;
      debugPrint('Primed cold-start tap: ${msg.messageId}');
    }
  } catch (e) {
    debugPrint('primeInitialMessage failed: $e');
  }
  return _bootInitialMessage;
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
    // ignore: avoid_print
    print('[tekka.push] _doInitialize: starting');
    developer.log('_doInitialize: starting', name: 'tekka.push', level: 800);
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      // ignore: avoid_print
      print('[tekka.push] permission status=${settings.authorizationStatus}');
      developer.log(
        'permission status=${settings.authorizationStatus}',
        name: 'tekka.push',
        level: 800,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // ignore: avoid_print
        print('[tekka.push] permission denied — bailing out');
        developer.log(
          'permission denied — bailing out',
          name: 'tekka.push',
          level: 1000,
        );
        return;
      }

      // iOS: show alerts in-foreground too. Without this, iOS silently drops
      // banners while the app is active.
      //
      // Defensive timeout (5s): on iOS 26 we've seen this platform-channel
      // call hang indefinitely on first launch, freezing the rest of init
      // (including APNs poll → no FCM token → no pushes ever arrive). The
      // option only affects in-foreground presentation; if it never lands,
      // pushes still work in background/killed state, which is the bigger
      // miss. So timing out here is strictly better than blocking forever.
      if (Platform.isIOS) {
        // ignore: avoid_print
        print('[tekka.push] step=setForegroundOptions BEGIN');
        try {
          await messaging
              .setForegroundNotificationPresentationOptions(
                alert: true,
                badge: true,
                sound: true,
              )
              .timeout(const Duration(seconds: 5));
          // ignore: avoid_print
          print('[tekka.push] step=setForegroundOptions END');
        } catch (e) {
          // ignore: avoid_print
          print('[tekka.push] step=setForegroundOptions TIMEOUT/ERROR ($e)');
        }
      }

      // ignore: avoid_print
      print('[tekka.push] step=initLocalNotifications BEGIN');
      try {
        await _initLocalNotifications().timeout(const Duration(seconds: 8));
        // ignore: avoid_print
        print('[tekka.push] step=initLocalNotifications END');
      } catch (e) {
        // ignore: avoid_print
        print('[tekka.push] step=initLocalNotifications TIMEOUT/ERROR ($e)');
      }

      // Attach listeners FIRST. On iOS, the FCM token is only available after
      // APNs registration completes; if we wait for the token synchronously
      // we can miss it. onTokenRefresh fires once APNs is ready.
      // ignore: avoid_print
      print('[tekka.push] step=attachListeners BEGIN');
      messaging.onTokenRefresh.listen(_registerToken);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      // ignore: avoid_print
      print('[tekka.push] step=attachListeners END');

      // Dispatch any cold-start tap NOW — before the iOS APNs poll below.
      // That poll can block this method for up to 30s; if we wait until after
      // it to navigate, the user sits on the home screen for many seconds
      // after tapping a push and concludes the tap was ignored. Prefer the
      // message captured at boot by primeInitialMessage (see its docstring) —
      // on iOS, calling getInitialMessage this late can return null because
      // the launch message has already been consumed. onNotificationTap is
      // wired in TekkaApp.build() before runApp returns control, so it is
      // guaranteed to be set by the time _doInitialize runs.
      // 3s timeout: getInitialMessage has been observed to hang on iOS 26
      // when no notification is pending; without a timeout it stalls the
      // entire push init pipeline (including APNs poll + getToken below).
      // ignore: avoid_print
      print('[tekka.push] step=getInitialMessage BEGIN (3s timeout)');
      RemoteMessage? initialMessage = _bootInitialMessage;
      initialMessage ??= await messaging.getInitialMessage().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          // ignore: avoid_print
          print('[tekka.push] step=getInitialMessage TIMEOUT (no tap)');
          return null;
        },
      );
      _bootInitialMessage = null;
      // ignore: avoid_print
      print(
        '[tekka.push] step=getInitialMessage END (msg=${initialMessage?.messageId ?? "null"})',
      );
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // iOS requires an APNs token before FCM can mint one. Poll for up to
      // 30s — first-launch registration on slow networks can take 10-20s.
      // onTokenRefresh will still deliver it if the poll times out.
      if (Platform.isIOS) {
        // ignore: avoid_print
        print('[tekka.push] step=apnsPoll BEGIN (max 30s)');
        var apnsReady = false;
        for (var i = 0; i < 60; i++) {
          final apns = await messaging.getAPNSToken();
          if (apns != null) {
            // ignore: avoid_print
            print(
              '[tekka.push] APNs token ready after ${i * 500}ms (len=${apns.length})',
            );
            developer.log(
              'APNs token ready after ${i * 500}ms (len=${apns.length})',
              name: 'tekka.push',
              level: 800,
            );
            apnsReady = true;
            break;
          }
          if (i % 4 == 0) {
            // ignore: avoid_print
            print('[tekka.push] waiting for APNs token (poll ${i + 1}/60)');
            developer.log(
              'waiting for APNs token (poll ${i + 1}/60)',
              name: 'tekka.push',
              level: 800,
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        // ignore: avoid_print
        print('[tekka.push] step=apnsPoll END (apnsReady=$apnsReady)');
      }

      // Attempt to grab the FCM token up-front. If it's not yet available
      // (common on iOS cold start), onTokenRefresh will deliver it shortly.
      try {
        // ignore: avoid_print
        print('[tekka.push] step=getToken BEGIN');
        final token = await messaging.getToken();
        // ignore: avoid_print
        print(
          '[tekka.push] step=getToken END (token=${token == null ? "null" : "len=${token.length}"})',
        );
        if (token != null) {
          // Print the raw token only in local debug builds so it's easy to
          // copy during testing. `debugPrint` is already debug-gated, but
          // wrap in kDebugMode as defense-in-depth against release leaks.
          if (kDebugMode) {
            debugPrint('FCM token: $token');
          }
          await _registerToken(token);
        } else {
          // ignore: avoid_print
          print('[tekka.push] getToken() returned null (no FCM token minted)');
          developer.log(
            'getToken() returned null (no FCM token minted)',
            name: 'tekka.push',
            level: 1000,
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('[tekka.push] initial FCM token fetch failed: $e');
        developer.log(
          'initial FCM token fetch failed (will retry via onTokenRefresh)',
          name: 'tekka.push',
          error: e,
          level: 1000,
        );
      }

      _initialized = true;
      // ignore: avoid_print
      print('[tekka.push] push notifications initialized');
      developer.log(
        'push notifications initialized',
        name: 'tekka.push',
        level: 800,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[tekka.push] init failed: $e');
      developer.log('init failed', name: 'tekka.push', error: e, level: 1000);
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
      // ignore: avoid_print
      print(
        '[tekka.push] FCM token registered (platform=$platform, len=${token.length})',
      );
      developer.log(
        'FCM token registered (platform=$platform, len=${token.length})',
        name: 'tekka.push',
        level: 800,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[tekka.push] FCM token registration failed: $e');
      developer.log(
        'FCM token registration failed',
        name: 'tekka.push',
        error: e,
        level: 1000,
      );
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    developer.log(
      'foreground message: ${message.notification?.title}',
      name: 'tekka.push',
      level: 800,
    );
    final notification = message.notification;
    if (notification == null) {
      // Data-only payload — nothing to render. Logged so we can tell the
      // difference between "no push arrived" and "push arrived but had no
      // notification block" while debugging iOS delivery.
      developer.log(
        'data-only message: id=${message.messageId} data=${message.data}',
        name: 'tekka.push',
        level: 800,
      );
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
