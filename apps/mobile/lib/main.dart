import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/environment.dart';
import 'core/providers/deep_link_provider.dart';
import 'core/providers/push_notification_provider.dart';
import 'core/theme/theme.dart';
import 'features/auth/application/auth_provider.dart';
import 'router/app_router.dart';
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
    ref.read(pushNotificationServiceProvider).onNotificationTap = (route, _) =>
        router.go(route);
    ref.read(deepLinkServiceProvider).initialize(router);

    // Initialize push notifications when user is authenticated
    ref.listen(authStateProvider, (previous, next) {
      final user = next.valueOrNull;
      final pushService = ref.read(pushNotificationServiceProvider);
      if (user != null && !pushService.isInitialized) {
        pushService.initialize();
      } else if (user == null && pushService.isInitialized) {
        pushService.cleanup();
      }
    });

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
