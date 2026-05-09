import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Run super first so GeneratedPluginRegistrant installs FIRMessaging's
    // UIApplicationDelegate swizzle before APNs can call back. Calling
    // registerForRemoteNotifications() before super raced the swizzle on
    // iOS 26 and dropped the device token before FCM could see it.
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    application.registerForRemoteNotifications()
    return result
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let prefix = deviceToken.prefix(8).map { String(format: "%02x", $0) }.joined()
    NSLog("[APNs] device token received: \(deviceToken.count) bytes, prefix=\(prefix)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[APNs] registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
