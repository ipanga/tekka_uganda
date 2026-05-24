import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekka/core/errors/app_exception.dart';
import 'package:tekka/core/services/api_client.dart';
import 'package:tekka/features/auth/data/repositories/jwt_auth_repository.dart';
import 'package:tekka/features/auth/data/repositories/user_api_repository.dart';
import 'package:tekka/features/auth/domain/entities/app_user.dart';

/// Verifies cold-start auth restore discriminates real auth failure from
/// transient network/server errors. Real 401s wipe the session; everything
/// else hydrates from the on-disk cache and keeps the user signed in.

class _MockApiClient extends Mock implements ApiClient {}

class _MockUserApiRepository extends Mock implements UserApiRepository {}

AppUser _user(String id) => AppUser(
  uid: id,
  phoneNumber: '+256700000001',
  displayName: 'Test User',
  createdAt: DateTime.utc(2026, 1, 1),
  isOnboardingComplete: true,
);

void main() {
  late _MockApiClient api;
  late _MockUserApiRepository userApi;

  setUp(() {
    api = _MockApiClient();
    userApi = _MockUserApiRepository();

    // Default stubs — individual tests override.
    when(() => api.getToken()).thenAnswer((_) async => null);
    when(() => api.getRefreshToken()).thenAnswer((_) async => null);
    when(() => api.getCachedUser()).thenAnswer((_) async => null);
    when(() => api.setToken(any())).thenAnswer((_) async {});
    when(() => api.setRefreshToken(any())).thenAnswer((_) async {});
    when(() => api.setCachedUser(any())).thenAnswer((_) async {});
    when(() => api.clearToken()).thenAnswer((_) async {});
    when(() => api.clearRefreshToken()).thenAnswer((_) async {});
    when(() => api.clearCachedUser()).thenAnswer((_) async {});
  });

  /// Constructs the repository and waits for its async constructor task
  /// (`_checkInitialAuthState`) to complete. We collect every value emitted
  /// on `authStateChanges` so tests can assert the exact emission.
  Future<List<AppUser?>> bootAndCollect() async {
    final repo = JwtAuthRepository(apiClient: api, userApiRepository: userApi);
    final events = <AppUser?>[];
    final sub = repo.authStateChanges.listen(events.add);
    // Let microtasks settle. _checkInitialAuthState chains a handful of
    // awaits; a few flushes ensures the final emission lands.
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    await sub.cancel();
    repo.dispose();
    return events;
  }

  test('no token → emits null (signed out)', () async {
    when(() => api.getToken()).thenAnswer((_) async => null);

    final events = await bootAndCollect();

    expect(events, [null]);
    verifyNever(() => userApi.getMe());
    verifyNever(() => api.clearToken());
  });

  test('valid token + getMe success → emits user and persists cache', () async {
    when(() => api.getToken()).thenAnswer((_) async => 'access');
    when(() => userApi.getMe()).thenAnswer((_) async => _user('u1'));

    final events = await bootAndCollect();

    expect(events.length, 1);
    expect(events.first?.uid, 'u1');
    verify(() => api.setCachedUser(any())).called(1);
    verifyNever(() => api.clearToken());
  });

  test('getMe transient 503 with cached_user blob → emits cached user, '
      'tokens preserved', () async {
    final cached = _user('cached-u2');
    when(() => api.getToken()).thenAnswer((_) async => 'access');
    when(
      () => api.getCachedUser(),
    ).thenAnswer((_) async => jsonEncode(cached.toJson()));
    when(() => userApi.getMe()).thenThrow(
      const ApiException(message: 'unavailable', code: 'SERVER_ERROR'),
    );

    final events = await bootAndCollect();

    expect(events.length, 1);
    expect(events.first?.uid, 'cached-u2');
    verifyNever(() => api.clearToken());
    verifyNever(() => api.clearRefreshToken());
    verifyNever(() => api.clearCachedUser());
  });

  test(
    'getMe transient timeout + no cached blob → emits null but keeps tokens',
    () async {
      when(() => api.getToken()).thenAnswer((_) async => 'access');
      when(() => api.getCachedUser()).thenAnswer((_) async => null);
      when(
        () => userApi.getMe(),
      ).thenThrow(const ApiException(message: 'timeout', code: 'TIMEOUT'));

      final events = await bootAndCollect();

      expect(events, [null]);
      // The whole point: even though we emit null (no cache to fall back on),
      // we MUST NOT wipe the user's stored tokens — the next request can still
      // succeed once the network recovers.
      verifyNever(() => api.clearToken());
      verifyNever(() => api.clearRefreshToken());
      verifyNever(() => api.clearCachedUser());
    },
  );

  test(
    'getMe 401 + refresh 401 → real logout (tokens + cache wiped)',
    () async {
      when(() => api.getToken()).thenAnswer((_) async => 'access');
      when(() => api.getRefreshToken()).thenAnswer((_) async => 'refresh');
      when(() => userApi.getMe()).thenThrow(
        const ApiException(message: 'unauthorized', code: 'UNAUTHORIZED'),
      );
      when(
        () => api.postWithoutAuth<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        const ApiException(message: 'refresh denied', code: 'UNAUTHORIZED'),
      );

      final events = await bootAndCollect();

      expect(events, [null]);
      verify(() => api.clearToken()).called(1);
      verify(() => api.clearRefreshToken()).called(1);
      verify(() => api.clearCachedUser()).called(1);
    },
  );

  test(
    'getMe 401 + refresh 503 → transient, keep tokens, hydrate from cache',
    () async {
      final cached = _user('cached-u3');
      when(() => api.getToken()).thenAnswer((_) async => 'access');
      when(() => api.getRefreshToken()).thenAnswer((_) async => 'refresh');
      when(
        () => api.getCachedUser(),
      ).thenAnswer((_) async => jsonEncode(cached.toJson()));
      when(() => userApi.getMe()).thenThrow(
        const ApiException(message: 'unauthorized', code: 'UNAUTHORIZED'),
      );
      when(
        () => api.postWithoutAuth<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        const ApiException(message: 'unavailable', code: 'SERVER_ERROR'),
      );

      final events = await bootAndCollect();

      expect(events.length, 1);
      expect(events.first?.uid, 'cached-u3');
      verifyNever(() => api.clearToken());
      verifyNever(() => api.clearRefreshToken());
      verifyNever(() => api.clearCachedUser());
    },
  );

  test(
    'getMe 401 + refresh success → emits new user and persists cache',
    () async {
      final refreshed = _user('u4');
      when(() => api.getToken()).thenAnswer((_) async => 'stale');
      when(() => api.getRefreshToken()).thenAnswer((_) async => 'refresh');
      when(() => userApi.getMe()).thenThrow(
        const ApiException(message: 'unauthorized', code: 'UNAUTHORIZED'),
      );
      when(
        () => api.postWithoutAuth<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
          'user': refreshed.toJson(),
        },
      );

      final events = await bootAndCollect();

      expect(events.length, 1);
      expect(events.first?.uid, 'u4');
      verify(() => api.setToken('new-access')).called(1);
      verify(() => api.setRefreshToken('new-refresh')).called(1);
      verify(() => api.setCachedUser(any())).called(1);
      verifyNever(() => api.clearToken());
    },
  );
}
