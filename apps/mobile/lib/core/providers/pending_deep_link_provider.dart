import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_provider.dart';
import '../../features/auth/domain/entities/app_user.dart';

/// Holds a deep-link route captured from a push-notification tap that
/// arrived before the app was ready to navigate (auth still restoring,
/// onboarding incomplete). Drained from `main.dart` once `authStateProvider`
/// emits a fully-onboarded user. Last-write-wins on rapid double-tap.
final pendingDeepLinkProvider = StateProvider<String?>((_) => null);

/// Signature for whatever pushes a route onto the navigation stack. Kept
/// as a plain function so unit tests can pass a list-appender instead of
/// a real `GoRouter`.
typedef DeepLinkPush = void Function(String route);

/// Decides what to do with a fresh push-tap route. Warm path (auth ready
/// + onboarding complete) pushes immediately; cold path writes to the
/// buffer for the drain listener to consume once auth resolves.
///
/// Returns true iff the route was pushed right away.
bool captureOrPushDeepLink(
  ProviderContainer container,
  String route, {
  required DeepLinkPush push,
}) {
  final auth = container.read(authStateProvider);
  final user = auth.valueOrNull;
  if (!auth.isLoading && user != null && user.isOnboardingComplete) {
    push(route);
    return true;
  }
  container.read(pendingDeepLinkProvider.notifier).state = route;
  return false;
}

/// Handles an `authStateProvider` emission for buffer-draining purposes.
///
/// - Loading: no-op (keep the buffer for the next emission).
/// - Signed out (`user == null`): clear any buffered route so a stale link
///   can't re-fire after the next sign-in (potentially as a different
///   account on the same device).
/// - Onboarded user with a buffered route: clear the slot *first*, then
///   push. Clearing-before-pushing defeats re-emissions from
///   `_maybeRevalidateSession` and similar listeners.
void onAuthStateForDeepLinkBuffer(
  ProviderContainer container,
  AsyncValue<AppUser?> next, {
  required DeepLinkPush push,
}) {
  if (next.isLoading) return;
  final user = next.valueOrNull;
  if (user == null) {
    if (container.read(pendingDeepLinkProvider) != null) {
      container.read(pendingDeepLinkProvider.notifier).state = null;
    }
    return;
  }
  if (!user.isOnboardingComplete) return;
  final pending = container.read(pendingDeepLinkProvider);
  if (pending == null) return;
  container.read(pendingDeepLinkProvider.notifier).state = null;
  push(pending);
}
