import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekka/core/services/api_client.dart';

/// Asserts the refresh-and-retry interceptor only signals `onSessionExpired`
/// when the backend genuinely rejects the refresh token (HTTP 401) or when
/// there is no refresh token in storage. Network errors and 5xx must NOT
/// log the user out — they're transient and the cached session must survive.

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Programmable HttpClientAdapter. Each queued handler is called once in
/// order; tests fail fast if more requests fire than expected.
class _StubAdapter implements HttpClientAdapter {
  final List<_Stub Function(RequestOptions options)> handlers;
  final List<RequestOptions> calls = [];

  _StubAdapter(this.handlers);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    if (handlers.isEmpty) {
      fail('No stub queued for ${options.method} ${options.path}');
    }
    final stub = handlers.removeAt(0)(options);
    if (stub.error != null) throw stub.error!;
    return stub.body!;
  }

  @override
  void close({bool force = false}) {}
}

class _Stub {
  final ResponseBody? body;
  final DioException? error;
  _Stub.ok(this.body) : error = null;
  _Stub.fail(this.error) : body = null;
}

ResponseBody _json(Map<String, dynamic> payload, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeIOSOptions());
    registerFallbackValue(_FakeAndroidOptions());
  });

  group('ApiClient refresh-and-retry policy', () {
    late _MockSecureStorage storage;
    late int sessionExpiredCount;
    late ApiClient client;

    // Per-test fresh adapters: one for the main Dio (handles user requests
    // and the retry), one for the refresh Dio (handles /auth/refresh).
    late _StubAdapter mainAdapter;
    _StubAdapter? refreshAdapter;

    final tokenStore = <String, String?>{};

    setUp(() {
      tokenStore.clear();
      storage = _MockSecureStorage();
      sessionExpiredCount = 0;

      // Storage backed by an in-memory map — gives us read-after-write
      // semantics so we can verify which keys get wiped on a real logout.
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((inv) async {
        return tokenStore[inv.namedArguments[#key] as String];
      });
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
          lOptions: any(named: 'lOptions'),
          webOptions: any(named: 'webOptions'),
          mOptions: any(named: 'mOptions'),
          wOptions: any(named: 'wOptions'),
        ),
      ).thenAnswer((inv) async {
        tokenStore[inv.namedArguments[#key] as String] =
            inv.namedArguments[#value] as String?;
      });
      when(
        () => storage.delete(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
          lOptions: any(named: 'lOptions'),
          webOptions: any(named: 'webOptions'),
          mOptions: any(named: 'mOptions'),
          wOptions: any(named: 'wOptions'),
        ),
      ).thenAnswer((inv) async {
        tokenStore.remove(inv.namedArguments[#key] as String);
      });

      client = ApiClient(
        storage: storage,
        onSessionExpired: () => sessionExpiredCount++,
      );
      mainAdapter = _StubAdapter([]);
      client.dio.httpClientAdapter = mainAdapter;
      refreshAdapter = null;
      client.refreshDioFactory = () {
        final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
        if (refreshAdapter != null) dio.httpClientAdapter = refreshAdapter!;
        return dio;
      };
    });

    test(
      '401 on /auth/refresh → onSessionExpired fires and tokens wiped',
      () async {
        tokenStore['access_token'] = 'stale';
        tokenStore['refresh_token'] = 'doomed';

        // Original GET returns 401.
        mainAdapter.handlers.add(
          (opts) => _Stub.fail(
            DioException(
              requestOptions: opts,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: opts,
                statusCode: 401,
                data: {'message': 'token expired'},
              ),
            ),
          ),
        );
        // Refresh Dio returns 401 (refresh token genuinely invalid).
        refreshAdapter = _StubAdapter([
          (opts) => _Stub.fail(
            DioException(
              requestOptions: opts,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: opts,
                statusCode: 401,
                data: {'message': 'refresh token invalid'},
              ),
            ),
          ),
        ]);

        await expectLater(client.get('/users/me'), throwsA(isA<Exception>()));

        expect(sessionExpiredCount, 1, reason: 'real 401 must trigger logout');
        expect(
          tokenStore['access_token'],
          isNull,
          reason: '_handleSessionExpired clears access token',
        );
        expect(
          tokenStore['refresh_token'],
          isNull,
          reason: '_handleSessionExpired clears refresh token',
        );
      },
    );

    test(
      'Timeout on /auth/refresh → onSessionExpired NOT fired, tokens kept',
      () async {
        tokenStore['access_token'] = 'stale';
        tokenStore['refresh_token'] = 'still-good';

        mainAdapter.handlers.add(
          (opts) => _Stub.fail(
            DioException(
              requestOptions: opts,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: opts,
                statusCode: 401,
                data: {},
              ),
            ),
          ),
        );
        refreshAdapter = _StubAdapter([
          (opts) => _Stub.fail(
            DioException(
              requestOptions: opts,
              type: DioExceptionType.receiveTimeout,
              message: 'timed out',
            ),
          ),
        ]);

        await expectLater(client.get('/users/me'), throwsA(isA<Exception>()));

        expect(
          sessionExpiredCount,
          0,
          reason: 'transient timeout must not log the user out',
        );
        expect(
          tokenStore['access_token'],
          'stale',
          reason: 'access token survives transient refresh failure',
        );
        expect(
          tokenStore['refresh_token'],
          'still-good',
          reason: 'refresh token survives transient refresh failure',
        );
      },
    );

    test('503 on /auth/refresh → onSessionExpired NOT fired', () async {
      tokenStore['access_token'] = 'stale';
      tokenStore['refresh_token'] = 'still-good';

      mainAdapter.handlers.add(
        (opts) => _Stub.fail(
          DioException(
            requestOptions: opts,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: opts, statusCode: 401, data: {}),
          ),
        ),
      );
      refreshAdapter = _StubAdapter([
        (opts) => _Stub.fail(
          DioException(
            requestOptions: opts,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: opts,
              statusCode: 503,
              data: {'message': 'unavailable'},
            ),
          ),
        ),
      ]);

      await expectLater(client.get('/users/me'), throwsA(isA<Exception>()));

      expect(
        sessionExpiredCount,
        0,
        reason: '5xx during deploy windows must not log the user out',
      );
      expect(tokenStore['refresh_token'], 'still-good');
    });

    test('Missing refresh token on 401 → real logout', () async {
      tokenStore['access_token'] = 'stale';
      // No refresh_token in store.

      mainAdapter.handlers.add(
        (opts) => _Stub.fail(
          DioException(
            requestOptions: opts,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: opts, statusCode: 401, data: {}),
          ),
        ),
      );

      await expectLater(client.get('/users/me'), throwsA(isA<Exception>()));

      expect(
        sessionExpiredCount,
        1,
        reason: 'no refresh token means there is nothing to recover from',
      );
    });

    test(
      'Successful refresh retries the original request transparently',
      () async {
        tokenStore['access_token'] = 'stale';
        tokenStore['refresh_token'] = 'good-refresh';

        mainAdapter.handlers.addAll([
          // First call → 401
          (opts) => _Stub.fail(
            DioException(
              requestOptions: opts,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: opts,
                statusCode: 401,
                data: {},
              ),
            ),
          ),
          // Retry after refresh → 200
          (opts) {
            expect(
              opts.headers['Authorization'],
              'Bearer fresh-access',
              reason: 'retry must carry the new access token',
            );
            return _Stub.ok(_json({'id': 'user-42'}));
          },
        ]);
        refreshAdapter = _StubAdapter([
          (opts) => _Stub.ok(
            _json({
              'accessToken': 'fresh-access',
              'refreshToken': 'fresh-refresh',
              'user': {'id': 'user-42'},
            }),
          ),
        ]);

        final result = await client.get<Map<String, dynamic>>('/users/me');

        expect(result['id'], 'user-42');
        expect(sessionExpiredCount, 0);
        expect(tokenStore['access_token'], 'fresh-access');
        expect(tokenStore['refresh_token'], 'fresh-refresh');
      },
    );
  });
}

class _FakeIOSOptions extends Fake implements IOSOptions {}

class _FakeAndroidOptions extends Fake implements AndroidOptions {}
