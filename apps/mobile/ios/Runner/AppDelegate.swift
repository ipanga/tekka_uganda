import Flutter
import UIKit
import UserNotifications
import os

/// Custom method channel name for forwarding notification-tap userInfo from
/// native UNUserNotificationCenterDelegate -> Dart. The push_notification_service
/// listens on this and routes via the existing _handleNotificationTap path.
///
/// Why a custom channel: on iOS 13+ Scene Lifecycle apps the firebase_messaging
/// plugin's `onMessageOpenedApp` stream stops emitting for background-tap because
/// FlutterAppDelegate conforms to FlutterAppLifeCycleProvider and the FCM plugin
/// defers to it (see FLTFirebaseMessagingPlugin.m::registerWithRegistrar:271).
/// FlutterAppDelegate itself doesn't implement UNUserNotificationCenterDelegate,
/// so taps go to the void. Verified empirically: on iOS 26.2 the
/// `[tekka.push] tap received` print never fires after a background-tap, even
/// though all other init steps complete successfully.
private let tapChannelName = "com.tootiyesolutions.tekka/notification_tap"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // The Swift `Logger` struct is iOS 14+; the project Podfile is on iOS 13,
  // so use the C-style OSLog/os_log API (iOS 10+). Output still routes to
  // Console.app and `idevicesyslog` on Release builds where bare NSLog from
  // Swift is sometimes silently dropped.
  private let pushLog = OSLog(
    subsystem: "com.tootiyesolutions.tekka", category: "push"
  )

  /// Method channel used to forward notification-tap userInfo to Dart.
  /// Created lazily once the FlutterEngine is available.
  private var tapChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase's requestPermission() does not reliably trigger APNs registration
    // on iOS 26 — kick it off explicitly at launch so the didRegister callback
    // fires and FCM can mint a token.
    application.registerForRemoteNotifications()
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Set ourselves as the UNUserNotificationCenter delegate AFTER super
    // (which runs GeneratedPluginRegistrant). This ensures notification taps
    // route to our `userNotificationCenter:didReceive:` below — the firebase_messaging
    // plugin's own delegate setup defers when FlutterAppDelegate is already the
    // delegate, leaving tap events unhandled. We forward userInfo to Dart via a
    // custom method channel.
    UNUserNotificationCenter.current().delegate = self
    return result
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let prefix = deviceToken.prefix(8).map { String(format: "%02x", $0) }.joined()
    os_log(
      "APNs device token received: %{public}d bytes, prefix=%{public}@",
      log: pushLog, type: .default, deviceToken.count, prefix)
    print("[APNs] device token received: \(deviceToken.count) bytes, prefix=\(prefix)")
    // Forward to super so FIRMessaging's swizzled handler picks it up.
    super.application(
      application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    os_log(
      "APNs registration failed: %{public}@",
      log: pushLog, type: .error, error.localizedDescription)
    print("[APNs] registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Wire the custom tap channel as soon as the implicit engine exists so
    // taps that arrive before the user signs in are still queued for delivery
    // by the FlutterMethodChannel (it buffers until the Dart side listens).
    // FlutterImplicitEngineBridge doesn't expose `binaryMessenger` directly;
    // get it via a plugin registrar.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TekkaTapChannel") {
      tapChannel = FlutterMethodChannel(
        name: tapChannelName,
        binaryMessenger: registrar.messenger()
      )
    }
  }

  // MARK: - UNUserNotificationCenterDelegate

  /// Called when a notification arrives while the app is in the foreground.
  /// FlutterAppDelegate's default implementation is essentially a no-op for
  /// FCM data payloads on Scene-Lifecycle apps, so override and allow iOS to
  /// present the banner per its defaults.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    super.userNotificationCenter(
      center, willPresent: notification, withCompletionHandler: completionHandler)
  }

  /// Called when the user taps a notification (foreground, background, or terminated).
  /// THIS is the bug fix: forward userInfo to Dart via a custom method channel
  /// so push_notification_service can route to the right detail screen.
  /// FlutterAppDelegate's parent implementation doesn't bridge userInfo to Dart
  /// for FCM-data payloads on iOS 13+ Scene apps — the FCM plugin's stream
  /// stops emitting because the plugin defers to FlutterAppDelegate's UNUC
  /// delegate position. We forward via a dedicated channel and call super so
  /// any Flutter-internal observers still see the response.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    let messageId = userInfo["gcm.message_id"] as? String ?? "<no-gcm-id>"
    os_log(
      "Notification tapped: gcm.message_id=%{public}@",
      log: pushLog, type: .default, messageId)
    print("[APNs] notification tapped: gcm.message_id=\(messageId)")

    // Only forward if it's an FCM notification (has gcm.message_id). Local
    // notifications scheduled by flutter_local_notifications use a separate
    // path and shouldn't double-fire here.
    if userInfo["gcm.message_id"] != nil {
      // Strip non-string-keyed entries; userInfo is [AnyHashable: Any] but
      // FlutterMethodChannel only carries JSON-compatible values.
      var sanitized: [String: Any] = [:]
      for (key, value) in userInfo {
        if let stringKey = key as? String {
          sanitized[stringKey] = value
        }
      }
      tapChannel?.invokeMethod("notificationTap", arguments: sanitized)
    }

    super.userNotificationCenter(
      center, didReceive: response, withCompletionHandler: completionHandler)
  }
}
