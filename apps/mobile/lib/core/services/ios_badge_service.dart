import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges to the native iOS MethodChannel that sets the home-screen app-icon
/// badge. On Android this is a no-op — Android badge behaviour is owned by the
/// OEM launcher + FCM `notification.android.notification_count` and the user
/// dashboard hasn't requested any custom badge handling there.
///
/// Why this exists: the backend sets `aps.badge` to the per-user unread count
/// on every push so the badge is correct at delivery, but iOS never
/// decrements it on its own. When the user marks notifications read in-app
/// the icon stays stuck at the last-pushed value until the next push lands.
/// Call [setBadgeCount] after any mutation that changes the unread count.
class IosBadgeService {
  IosBadgeService._();

  static const _channel = MethodChannel('com.tootiyesolutions.tekka/badge');

  /// Set the home-screen icon badge. Errors are swallowed (logged in debug);
  /// a stale badge is a UX nit, not worth crashing the app over.
  static Future<void> setBadgeCount(int count) async {
    if (kIsWeb || !Platform.isIOS) return;
    final clamped = count < 0 ? 0 : count;
    try {
      await _channel.invokeMethod<void>('setBadgeCount', {'count': clamped});
    } on PlatformException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[badge] setBadgeCount($clamped) failed: ${e.message}');
        debugPrint('$st');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[badge] unexpected error: $e');
        debugPrint('$st');
      }
    }
  }
}
