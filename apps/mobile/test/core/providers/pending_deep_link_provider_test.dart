import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekka/core/providers/pending_deep_link_provider.dart';
import 'package:tekka/features/auth/application/auth_provider.dart';
import 'package:tekka/features/auth/domain/entities/app_user.dart';

/// Regression guard for the cold-tap deep-link buffer added on
/// fix/push-deep-link-cold-tap. The original failure: every push tapped
/// before authStateProvider resolved landed on /home, because GoRouter's
/// redirect re-evaluation collapsed `state.matchedLocation` back to
/// `initialLocation` once `appRouterProvider` rebuilt.

AppUser _onboarded() => AppUser(
  uid: 'u1',
  phoneNumber: '+256700000001',
  displayName: 'Onboarded User',
  createdAt: DateTime.utc(2026, 1, 1),
  isOnboardingComplete: true,
);

AppUser _preOnboarding() => AppUser(
  uid: 'u2',
  phoneNumber: '+256700000002',
  createdAt: DateTime.utc(2026, 1, 1),
  // isOnboardingComplete defaults to false
);

void main() {
  group('captureOrPushDeepLink', () {
    test('buffers when authStateProvider is still loading', () {
      // A stream that never emits keeps authStateProvider in AsyncLoading.
      final controller = StreamController<AppUser?>();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [authStateProvider.overrideWith((_) => controller.stream)],
      );
      addTearDown(container.dispose);

      final pushed = <String>[];
      final pushedImmediately = captureOrPushDeepLink(
        container,
        '/chat/abc',
        push: pushed.add,
      );

      expect(pushedImmediately, isFalse);
      expect(pushed, isEmpty);
      expect(container.read(pendingDeepLinkProvider), '/chat/abc');
    });

    test(
      'buffers when user is signed in but onboarding is incomplete',
      () async {
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (_) => Stream.value(_preOnboarding()),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Let the StreamProvider settle on the emitted value.
        await container.read(authStateProvider.future);

        final pushed = <String>[];
        final pushedImmediately = captureOrPushDeepLink(
          container,
          '/listing/xyz',
          push: pushed.add,
        );

        expect(pushedImmediately, isFalse);
        expect(pushed, isEmpty);
        expect(container.read(pendingDeepLinkProvider), '/listing/xyz');
      },
    );

    test(
      'pushes immediately on the warm path (auth ready + onboarded)',
      () async {
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((_) => Stream.value(_onboarded())),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authStateProvider.future);

        final pushed = <String>[];
        final pushedImmediately = captureOrPushDeepLink(
          container,
          '/reviews/u9',
          push: pushed.add,
        );

        expect(pushedImmediately, isTrue);
        expect(pushed, ['/reviews/u9']);
        expect(container.read(pendingDeepLinkProvider), isNull);
      },
    );

    test('last-write-wins on double-tap before auth resolves', () {
      final controller = StreamController<AppUser?>();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [authStateProvider.overrideWith((_) => controller.stream)],
      );
      addTearDown(container.dispose);

      final pushed = <String>[];
      captureOrPushDeepLink(container, '/chat/a', push: pushed.add);
      captureOrPushDeepLink(container, '/chat/b', push: pushed.add);

      expect(pushed, isEmpty);
      expect(container.read(pendingDeepLinkProvider), '/chat/b');
    });
  });

  group('onAuthStateForDeepLinkBuffer', () {
    ProviderContainer makeContainer() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('drains and pushes when authState resolves to an onboarded user', () {
      final container = makeContainer();
      container.read(pendingDeepLinkProvider.notifier).state = '/chat/abc';

      final pushed = <String>[];
      onAuthStateForDeepLinkBuffer(
        container,
        AsyncValue.data(_onboarded()),
        push: pushed.add,
      );

      expect(pushed, ['/chat/abc']);
      expect(container.read(pendingDeepLinkProvider), isNull);
    });

    test('does not re-fire on a second emission of the same user', () {
      final container = makeContainer();
      container.read(pendingDeepLinkProvider.notifier).state = '/listing/xyz';

      final pushed = <String>[];
      final user = _onboarded();
      onAuthStateForDeepLinkBuffer(
        container,
        AsyncValue.data(user),
        push: pushed.add,
      );
      onAuthStateForDeepLinkBuffer(
        container,
        AsyncValue.data(user),
        push: pushed.add,
      );

      // Buffer cleared after first drain → second emission finds nothing to
      // push, even though the user is still onboarded. Guards against
      // _maybeRevalidateSession re-firing a consumed link on long resume.
      expect(pushed, ['/listing/xyz']);
      expect(container.read(pendingDeepLinkProvider), isNull);
    });

    test('clears the buffer on sign-out so it does not re-fire post-login', () {
      final container = makeContainer();
      container.read(pendingDeepLinkProvider.notifier).state = '/chat/old';

      final pushed = <String>[];
      onAuthStateForDeepLinkBuffer(
        container,
        const AsyncValue.data(null),
        push: pushed.add,
      );

      expect(pushed, isEmpty);
      expect(container.read(pendingDeepLinkProvider), isNull);
    });

    test('no-ops while authState is still loading', () {
      final container = makeContainer();
      container.read(pendingDeepLinkProvider.notifier).state = '/chat/abc';

      final pushed = <String>[];
      onAuthStateForDeepLinkBuffer(
        container,
        const AsyncValue<AppUser?>.loading(),
        push: pushed.add,
      );

      expect(pushed, isEmpty);
      expect(container.read(pendingDeepLinkProvider), '/chat/abc');
    });

    test('no-ops while the user has not finished onboarding', () {
      final container = makeContainer();
      container.read(pendingDeepLinkProvider.notifier).state = '/listing/xyz';

      final pushed = <String>[];
      onAuthStateForDeepLinkBuffer(
        container,
        AsyncValue.data(_preOnboarding()),
        push: pushed.add,
      );

      expect(pushed, isEmpty);
      expect(container.read(pendingDeepLinkProvider), '/listing/xyz');
    });
  });
}
