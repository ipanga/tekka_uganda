import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Dio interceptor that retries transient failures with exponential backoff.
///
/// Only retries idempotent methods (GET/HEAD) by default. Callers can opt-in
/// per request via `options.extra['retry'] = true`. Writes are never retried
/// automatically.
///
/// Transient conditions that trigger a retry:
///   - DioExceptionType.connectionTimeout / sendTimeout / receiveTimeout
///   - DioExceptionType.connectionError
///   - Response status 502, 503, 504
///   - Response status 429 (rate-limited) — uses Retry-After if present
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 8),
    FutureOr<void> Function(Duration)? sleeper,
  })  : _dio = dio,
        _sleeper = sleeper ?? Future<void>.delayed;

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final FutureOr<void> Function(Duration) _sleeper;

  static const String _retryCountKey = 'retry_count';
  static const String _retryOptIn = 'retry';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!isTransientError(err) ||
        !shouldRetryMethod(err.requestOptions)) {
      return handler.next(err);
    }

    final attempt = (err.requestOptions.extra[_retryCountKey] as int? ?? 0);
    if (attempt >= maxRetries) {
      return handler.next(err);
    }

    final delay = computeDelay(attempt, err.response);
    debugPrint(
      'RetryInterceptor: retrying ${err.requestOptions.method} '
      '${err.requestOptions.path} (attempt ${attempt + 1}/$maxRetries) '
      'after ${delay.inMilliseconds}ms',
    );

    await _sleeper(delay);

    try {
      final clonedOptions = err.requestOptions.copyWith(
        extra: {
          ...err.requestOptions.extra,
          _retryCountKey: attempt + 1,
        },
      );
      // Re-fire on the same Dio so every interceptor (auth, retry, logging)
      // applies exactly once more — and this interceptor sees the bumped
      // retry count in `extra`.
      final response = await _dio.fetch<dynamic>(clonedOptions);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  /// Is [err] the kind of failure that's safe to retry?
  @visibleForTesting
  static bool isTransientError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        return code == 502 || code == 503 || code == 504 || code == 429;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Opt a specific request in/out of retries via `options.extra['retry']`.
  /// Default: "retry if method is GET or HEAD".
  @visibleForTesting
  static bool shouldRetryMethod(RequestOptions options) {
    final extra = options.extra[_retryOptIn];
    if (extra is bool) return extra;
    final method = options.method.toUpperCase();
    return method == 'GET' || method == 'HEAD';
  }

  /// Exponential backoff with jitter; honors Retry-After when present.
  @visibleForTesting
  Duration computeDelay(int attempt, Response<dynamic>? response) {
    final retryAfter = response?.headers.value('retry-after');
    if (retryAfter != null) {
      final secs = int.tryParse(retryAfter);
      if (secs != null && secs > 0) {
        return Duration(seconds: math.min(secs, maxDelay.inSeconds));
      }
    }
    final expMs = baseDelay.inMilliseconds * (1 << attempt);
    final jitterMs = math.Random().nextInt(baseDelay.inMilliseconds);
    final total = math.min(expMs + jitterMs, maxDelay.inMilliseconds);
    return Duration(milliseconds: total);
  }
}
