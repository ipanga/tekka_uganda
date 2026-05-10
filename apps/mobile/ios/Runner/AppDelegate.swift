import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import os.log

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // os.Logger is the modern unified-logging API — visible in Console.app
  // and `idevicesyslog` on Release builds, which iOS 26 silently drops for
  // bare `NSLog` from Swift.
  private let pushLog = Logger(
    subsystem: "com.tootiyesolutions.tekka", category: "push"
  )

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase BEFORE the Flutter plugin registrant runs (super
    // dispatches it). With FirebaseApp already initialised, FIRMessaging's
    // UIApplicationDelegate swizzle is in place by the time APNs returns
    // the device token. firebase_core's Dart-side `Firebase.initializeApp()`
    // in main.dart detects the existing instance and reuses it.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    application.registerForRemoteNotifications()
    return result
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let prefix = deviceToken.prefix(8).map { String(format: "%02x", $0) }.joined()
    pushLog.notice("APNs device token received: \(deviceToken.count, privacy: .public) bytes, prefix=\(prefix, privacy: .public)")
    print("[APNs] device token received: \(deviceToken.count) bytes, prefix=\(prefix)")
    // Belt-and-suspenders: hand the token to Firebase Messaging directly.
    // FIRMessaging's swizzle does this on the super forward, but on iOS 26
    // we've seen the swizzle miss the callback and FCM never mints a token.
    // Setting apnsToken explicitly here guarantees Messaging has it before
    // any subsequent `getToken()` call.
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    pushLog.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    print("[APNs] registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
