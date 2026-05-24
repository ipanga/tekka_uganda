import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/data/repositories/jwt_auth_repository.dart';
import '../../features/profile/application/app_lock_provider.dart';
import '../../features/profile/presentation/screens/app_lock_screen.dart';
import '../services/tab_data_refresh.dart';

/// Wrapper widget that handles app lifecycle and shows lock screen when needed
class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  /// Wall-clock moment the app most recently went to the background. Used to
  /// decide whether resume should proactively revalidate the session.
  /// `null` until the first paused event.
  DateTime? _pausedAt;

  /// Sessions are revalidated on resume only after the app was backgrounded
  /// for at least this long. Quick tab-switches and brief lock-screen visits
  /// don't trigger extra `/users/me` calls; multi-hour or multi-day gaps do.
  static const Duration _resumeRevalidateThreshold = Duration(minutes: 5);

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
        // Kick any tab providers that may be stuck after a suspended socket
        // or a polling timer that fired into thin air while backgrounded.
        refreshTabDataAfterResume(ref);
        _maybeRevalidateSession();
        _pausedAt = null;
        break;
      case AppLifecycleState.paused:
        // App went to background
        appLockNotifier.onAppPaused();
        _pausedAt = DateTime.now();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // No action needed for these states
        break;
    }
  }

  /// Fire-and-forget a `getMe()` call when resuming after a long background
  /// gap. The point isn't to gate UI on the result — it's to detect a dead
  /// socket or revoked refresh token *early*, before the user starts tapping
  /// things and racks up cascading spinners. The repository's transient-vs-
  /// invalid discrimination means a network blip here never logs the user
  /// out; only a real 401 from `/auth/refresh` does.
  void _maybeRevalidateSession() {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    if (DateTime.now().difference(pausedAt) < _resumeRevalidateThreshold) {
      return;
    }
    final repo = ref.read(authRepositoryProvider);
    if (repo is JwtAuthRepository) {
      // ignore: discarded_futures
      repo.refreshCurrentUser();
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
