import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekka/core/services/retry_interceptor.dart';

void main() {
  group('isTransientError', () {
    test('timeouts and connection errors are transient', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          RetryInterceptor.isTransientError(DioException(
            requestOptions: RequestOptions(),
            type: type,
          )),
          isTrue,
          reason: '$type should be transient',
        );
      }
    });

    test('5xx and 429 are transient; other 4xx are not', () {
      for (final code in [502, 503, 504, 429]) {
        final err = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: code,
          ),
        );
        expect(RetryInterceptor.isTransientError(err), isTrue,
            reason: '$code should be transient');
      }
      for (final code in [400, 401, 403, 404, 422, 500, 501]) {
        final err = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: code,
          ),
        );
        expect(RetryInterceptor.isTransientError(err), isFalse,
            reason: '$code should NOT be transient');
      }
    });

    test('cancelled/badCertificate/unknown are never retried', () {
      for (final type in [
        DioExceptionType.cancel,
        DioExceptionType.badCertificate,
        DioExceptionType.unknown,
      ]) {
        expect(
          RetryInterceptor.isTransientError(
            DioException(requestOptions: RequestOptions(), type: type),
          ),
          isFalse,
        );
      }
    });
  });

  group('shouldRetryMethod', () {
    test('GET and HEAD retry by default', () {
      expect(RetryInterceptor.shouldRetryMethod(
        RequestOptions(method: 'GET'),
      ), isTrue);
      expect(RetryInterceptor.shouldRetryMethod(
        RequestOptions(method: 'HEAD'),
      ), isTrue);
    });

    test('POST/PUT/DELETE do not retry by default', () {
      for (final m in ['POST', 'PUT', 'PATCH', 'DELETE']) {
        expect(
          RetryInterceptor.shouldRetryMethod(RequestOptions(method: m)),
          isFalse,
          reason: '$m should not retry by default',
        );
      }
    });

    test('extra["retry"]=true opts in a write', () {
      final opts = RequestOptions(method: 'POST', extra: {'retry': true});
      expect(RetryInterceptor.shouldRetryMethod(opts), isTrue);
    });

    test('extra["retry"]=false opts a GET out', () {
      final opts = RequestOptions(method: 'GET', extra: {'retry': false});
      expect(RetryInterceptor.shouldRetryMethod(opts), isFalse);
    });
  });

  group('computeDelay', () {
    final interceptor = RetryInterceptor(
      dio: Dio(),
      baseDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(seconds: 5),
    );

    test('grows exponentially up to maxDelay', () {
      // attempt 0 => ~100ms + jitter
      // attempt 1 => ~200ms
      // attempt 4 => 1600ms
      // attempt 10 => capped to 5000ms
      final d0 = interceptor.computeDelay(0, null);
      final d2 = interceptor.computeDelay(2, null);
      final dBig = interceptor.computeDelay(10, null);
      expect(d0.inMilliseconds, lessThanOrEqualTo(200));
      expect(d2.inMilliseconds, greaterThanOrEqualTo(400));
      expect(dBig, const Duration(seconds: 5));
    });

    test('honors Retry-After header', () {
      final response = Response(
        requestOptions: RequestOptions(),
        statusCode: 429,
        headers: Headers.fromMap({'retry-after': ['3']}),
      );
      expect(interceptor.computeDelay(0, response),
          const Duration(seconds: 3));
    });

    test('Retry-After is clamped to maxDelay', () {
      final response = Response(
        requestOptions: RequestOptions(),
        statusCode: 429,
        headers: Headers.fromMap({'retry-after': ['999']}),
      );
      expect(interceptor.computeDelay(0, response),
          const Duration(seconds: 5));
    });
  });
}
