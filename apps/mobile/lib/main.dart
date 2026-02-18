import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/environment.dart';
import 'core/theme/theme.dart';
import 'router/app_router.dart';
import 'shared/widgets/app_lock_wrapper.dart';

void main() async {
  EnvironmentConfig.init(Environment.prod);
  WidgetsFlutterBinding.ensureInitialized();

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

    return AppLockWrapper(
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}
