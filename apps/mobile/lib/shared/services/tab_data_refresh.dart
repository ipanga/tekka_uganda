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

  // Saved tab.
  ref.invalidate(savedListingsProvider);
  ref.invalidate(myFavoritesProvider);

  // Profile tab (stats + preview both depend on userListingsProvider family).
  ref.invalidate(userListingsProvider);
  ref.invalidate(profileStatsProvider);
  ref.invalidate(myListingsPreviewProvider);
}
