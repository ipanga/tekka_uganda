import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/environment.dart';
import 'core/providers/cache_providers.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/deep_link_provider.dart';
import 'core/providers/push_notification_provider.dart';
import 'core/services/ios_badge_service.dart';
import 'core/services/offline_queue/queue_executor.dart';
import 'core/services/push_notification_service.dart' show primeInitialMessage;
import 'core/theme/theme.dart';
import 'features/auth/application/auth_provider.dart';
import 'features/notifications/application/notification_provider.dart';
import 'router/app_router.dart';
import 'shared/services/tab_data_refresh.dart';
import 'shared/widgets/app_lock_wrapper.dart';
import 'shared/widgets/offline_banner.dart';

void main() async {
  EnvironmentConfig.init(Environment.prod);
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for prod only. Non-prod iOS builds strip the plist
  // at build time (see Runner.xcodeproj :: "Strip Firebase plist" phase) and
  // non-prod Android skips the google-services plugin, so neither ships with
  // a Firebase config. Dev/staging don't use any Firebase features.
  if (EnvironmentConfig.isProd) {
    try {
      await Firebase.initializeApp();
      // Kick off cold-start tap capture in the background. NEVER await this
      // here — `getInitialMessage()` can block on iOS while APNs sets up,
      // and stalling main() before runApp() shows the user a blank screen.
      // The prime caches into a top-level static which the auth-gated
      // `PushNotificationService.initialize()` reads later (or falls back
      // to a fresh call). See primeInitialMessage's docstring.
      // ignore: discarded_futures
      primeInitialMessage();
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: TekkaApp()));
}

/// Tekka App - Biggest C2C Fashion Marketplace for Uganda
class TekkaApp extends ConsumerWidget {
  const TekkaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Wire notification taps + incoming universal/app links to the router.
    // Safe to re-wire on rebuild — both are idempotent.
    // Push init itself fires from the auth flow once the user is signed in.
    //
    // Use `push`, not `go`: deep-link target screens (chat / listing / review
    // detail / etc.) are top-level routes outside the shell. `go` REPLACES the
    // stack so the user lands on a page with no back button; `push` adds the
    // detail on top of whatever was there (typically /home), so the AppBar
    // back arrow returns the user where they were before the tap. Same applies
    // to Universal-Link arrivals routed by deep_link_service.
    ref.read(pushNotificationServiceProvider).onNotificationTap = (route, _) =>
        router.push(route);
    ref.read(deepLinkServiceProvider).initialize(router);

    // Prime the cache + offline queue and teach the queue how to replay
    // actions. Runs once at boot; Riverpod providers are idempotent.
    ref.read(cacheServiceProvider).init();
    final queue = ref.read(offlineQueueProvider);
    final container = ProviderScope.containerOf(context);
    queue.registerExecutor(buildQueueExecutor(container));
    queue.init().then((_) {
      // Boot-time flush: anything queued in a previous session ships now
      // (if we're online). Harmless no-op when offline.
      if (ref.read(isConnectedProvider)) queue.flush();
    });

    // Drain the queue every time connectivity is restored, and refresh the
    // tab-level providers so a request that died during the offline window
    // doesn't leave a screen stuck on a spinner.
    ref.listen<AsyncValue<void>>(connectivityRestoredProvider, (_, next) {
      next.whenData((_) {
        ref.read(offlineQueueProvider).flush();
        refreshTabDataAfterResume(ref);
      });
    });

    // Keep the iOS home-screen icon badge in sync with the unread-notification
    // count. The server sets `aps.badge` on every push so the count is correct
    // at delivery, but iOS never decrements it on its own — without this
    // listener the badge stays stuck after the user reads notifications in-app.
    // The polling stream + post-action invalidations in NotificationActions
    // feed every change through here. Logout drops user to null which emits 0
    // and clears the badge.
    ref.listen<AsyncValue<int>>(unreadNotificationsStreamProvider, (_, next) {
      next.whenData(IosBadgeService.setBadgeCount);
    });

    // Initialize push when the user becomes non-null. Two paths:
    //
    // 1. Listener — fires on any future null→non-null transition (login via
    //    OTP, Firebase email fallback, sign-out then sign-in again).
    // 2. Immediate read — for returning users whose JWT was already restored
    //    from secure storage by the time TekkaApp.build runs. The listener
    //    above only fires on transitions, so a session that was non-null at
    //    listener-attach time would never trigger push init. This is the
    //    fix for upgrade-while-signed-in: TestFlight preserves app data, so
    //    JWT restores synchronously and the listener never sees a transition.
    //
    // initialize() is idempotent so being triggered by both paths is safe.
    ref.listen<AsyncValue<Object?>>(authStateProvider, (prev, next) {
      final prevUser = prev?.valueOrNull;
      final nextUser = next.valueOrNull;
      if (prevUser == null && nextUser != null) {
        ref.read(pushNotificationServiceProvider).initialize();
      }
    });
    if (ref.read(authStateProvider).valueOrNull != null) {
      ref.read(pushNotificationServiceProvider).initialize();
    }

    return AppLockWrapper(
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        routerConfig: router,
        builder: (context, child) {
          return Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }
}
