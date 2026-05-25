import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a deep-link route captured from a push-notification tap that
/// arrived before the app was ready to navigate (auth still restoring,
/// onboarding incomplete). Drained from `main.dart` once `authStateProvider`
/// emits a fully-onboarded user. Last-write-wins on rapid double-tap.
final pendingDeepLinkProvider = StateProvider<String?>((_) => null);
