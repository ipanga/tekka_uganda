import Flutter
import UIKit
import os

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // The Swift `Logger` struct is iOS 14+; the project Podfile is on iOS 13,
  // so use the C-style OSLog/os_log API (iOS 10+). Output still routes to
  // Console.app and `idevicesyslog` on Release builds where bare NSLog from
  // Swift is sometimes silently dropped.
  private let pushLog = OSLog(
    subsystem: "com.tootiyesolutions.tekka", category: "push"
  )

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase's requestPermission() does not reliably trigger APNs
    // registration on iOS 26 — kick it off explicitly at launch so the
    // didRegister callback fires and FCM can mint a token.
    //
    // Order matches the last-known-good config (PR #53): register for
    // remote notifications first, then forward to super (which runs
    // GeneratedPluginRegistrant via FlutterAppDelegate). We do NOT call
    // FirebaseApp.configure() here — Flutter's firebase_core plugin does
    // that from Dart's `Firebase.initializeApp()`. Doing both natively and
    // in Dart on iOS 26 has been observed to confuse FIRMessaging's
    // UIApplicationDelegate swizzle and stall push init.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let prefix = deviceToken.prefix(8).map { String(format: "%02x", $0) }.joined()
    os_log("APNs device token received: %{public}d bytes, prefix=%{public}@",
           log: pushLog, type: .default, deviceToken.count, prefix)
    print("[APNs] device token received: \(deviceToken.count) bytes, prefix=\(prefix)")
    // Forward to super so FIRMessaging's swizzled handler picks it up.
    // Do NOT manually set Messaging.messaging().apnsToken here — that path
    // requires importing FirebaseMessaging in this AppDelegate, which only
    // works once FirebaseApp.configure() has run, and we've moved Firebase
    // init back to the Flutter plugin entirely.
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    os_log("APNs registration failed: %{public}@",
           log: pushLog, type: .error, error.localizedDescription)
    print("[APNs] registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
