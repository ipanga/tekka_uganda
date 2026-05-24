import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';
import '../../features/chat/application/chat_provider.dart';
import '../../features/listing/application/listing_provider.dart';
import '../../features/notifications/application/notification_provider.dart';
import '../../features/profile/application/profile_provider.dart';

/// Invalidate the data-loading providers backing every bottom-nav tab plus the
/// shell-level badges. Called on app resume and on offline→online transitions
/// so a suspended Dio socket or a dead polling timer can't leave a tab stuck
/// on an infinite spinner until the app is restarted.
///
/// The home feed (`paginatedListingsProvider`) is intentionally left alone:
/// it already has pull-to-refresh and invalidating it on every resume would
/// reset the user's scroll position.
void refreshTabDataAfterResume(WidgetRef ref) {
  // Invalidating while offline just clears the last-known cached data and
  // leaves the user staring at a spinner (or error) until they reconnect —
  // worse UX than keeping stale data. The connectivity-restored listener
  // will call us again once we're back online.
  if (!ref.read(isConnectedProvider)) return;

  // Chat tab + shell badge + open chat detail screens.
  ref.invalidate(chatsStreamProvider);
  ref.invalidate(unreadCountProvider);
  ref.invalidate(messagesStreamProvider);

  // Notifications list + shell badge.
  ref.invalidate(notificationsStreamProvider);
  ref.invalidate(unreadNotificationsStreamProvider);
  // The paginated list backing the Notifications screen is a StateNotifier.
  // Calling `.notifier.refresh()` re-fetches page 1 in-place: existing items
  // stay on screen while the request is in flight, then swap atomically.
  // We deliberately do NOT `invalidate()` here — that tears the notifier
  // down and rebuilds it with `isInitialLoading: true`, which replaces the
  // user's list with a spinner on every resume even when the cache was
  // perfectly serviceable. `refreshNotificationsAfterPush` already uses
  // this approach for the same reason.
  ref.read(notificationsListProvider.notifier).refresh();

  // Saved tab.
  ref.invalidate(savedListingsProvider);
  ref.invalidate(myFavoritesProvider);

  // Profile tab (stats + preview both depend on userListingsProvider family).
  ref.invalidate(userListingsProvider);
  ref.invalidate(profileStatsProvider);
  ref.invalidate(myListingsPreviewProvider);
}

/// Refresh the notification + chat unread providers after a push arrives
/// (foreground delivery, tap, or silent `sync_unread_state` from a sibling
/// device that just marked something read). Called from the host-side
/// `onNotificationReceived` callback wired in `main.dart`. Keeps every
/// badge consistent with the freshly-mutated backend state without
/// forcing pull-to-refresh.
///
/// Uses `.notifier.refresh()` on the paginated list rather than
/// `invalidate()` so subscribers (the Notifications screen, if open)
/// don't briefly see a "loading" state — the existing items stay on
/// screen while page 1 re-fetches, then swap atomically.
///
/// Chat unread (`unreadCountProvider`) is invalidated separately — same
/// provider the resume sweep already touches — so the chat tab badge
/// also re-polls within seconds of a sibling device reading a chat.
void refreshNotificationsAfterPush(WidgetRef ref) {
  if (!ref.read(isConnectedProvider)) return;
  ref.invalidate(unreadNotificationsStreamProvider);
  ref.read(notificationsListProvider.notifier).refresh();
  ref.invalidate(unreadCountProvider);
}
