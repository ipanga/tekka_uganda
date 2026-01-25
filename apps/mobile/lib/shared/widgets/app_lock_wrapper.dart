import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/application/app_lock_provider.dart';
import '../../features/profile/presentation/screens/app_lock_screen.dart';

/// Wrapper widget that handles app lifecycle and shows lock screen when needed
class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final appLockNotifier = ref.read(appLockProvider.notifier);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - check if we should lock
        appLockNotifier.onAppResumed();
        break;
      case AppLifecycleState.paused:
        // App went to background
        appLockNotifier.onAppPaused();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // No action needed for these states
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowLock = ref.watch(shouldShowLockScreenProvider);

    if (shouldShowLock) {
      return AppLockScreen(
        onUnlocked: () {
          // The provider will automatically update and hide the lock screen
        },
      );
    }

    return widget.child;
  }
}
