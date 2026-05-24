import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekka/features/notifications/application/notification_provider.dart';
import 'package:tekka/features/notifications/domain/entities/app_notification.dart';
import 'package:tekka/features/notifications/domain/repositories/notification_repository.dart';
import 'package:tekka/features/notifications/presentation/screens/notification_detail_screen.dart';

/// Guards that opening a notification detail does NOT trigger a full
/// `getNotifications` round-trip. The provider must scan the already-loaded
/// paginated-list cache synchronously and fall through to a direct
/// `getNotification(id)` only on a miss. The previous behaviour blocked the
/// detail screen on the list fetch, which caused infinite spinners on a
/// cold push tap when the list fetch hung.

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

AppNotification _notif(String id, {String title = 'A title'}) =>
    AppNotification(
      id: id,
      type: NotificationType.system,
      title: title,
      body: 'b',
      createdAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  late _MockNotificationRepository repo;

  setUp(() {
    repo = _MockNotificationRepository();
  });

  test('returns the cached item without touching the repository', () async {
    when(
      () => repo.getNotificationsPage(any(), limit: any(named: 'limit')),
    ).thenAnswer(
      (_) async => NotificationPage(
        items: [
          _notif('n1', title: 'cached'),
          _notif('n2'),
        ],
        nextCursor: null,
        hasMore: false,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
        notificationsListProvider.overrideWith(
          (ref) => NotificationsListNotifier(repo, 'user-1'),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Let _loadInitial settle so the items are in the state.
    await container.read(notificationsListProvider.notifier).refresh();

    final result = await container.read(
      singleNotificationProvider('n1').future,
    );

    expect(result?.title, 'cached');
    verifyNever(() => repo.getNotification(any()));
  });

  test('falls back to direct getNotification on cache miss', () async {
    when(
      () => repo.getNotificationsPage(any(), limit: any(named: 'limit')),
    ).thenAnswer(
      (_) async =>
          const NotificationPage(items: [], nextCursor: null, hasMore: false),
    );
    when(
      () => repo.getNotification('cold-tap-id'),
    ).thenAnswer((_) async => _notif('cold-tap-id', title: 'from server'));

    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repo),
        notificationsListProvider.overrideWith(
          (ref) => NotificationsListNotifier(repo, 'user-1'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(
      singleNotificationProvider('cold-tap-id').future,
    );

    // The detail screen must always be able to resolve a notification when
    // the list cache is empty — without blocking on the list fetch.
    expect(result?.title, 'from server');
    verify(() => repo.getNotification('cold-tap-id')).called(1);
  });
}
