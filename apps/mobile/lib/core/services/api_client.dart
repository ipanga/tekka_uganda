import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sentry_dio/sentry_dio.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';
import 'retry_interceptor.dart';

/// API Client for communicating with Tekka backend
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  /// Expose the underlying Dio so tests can swap its [HttpClientAdapter].
  /// Production callers must go through the typed wrappers below.
  @visibleForTesting
  Dio get dio => _dio;

  /// Factory used to construct the dedicated Dio that performs the
  /// `/auth/refresh` call. In production we mint a fresh Dio so it doesn't
  /// inherit the auth interceptor (which would recurse on its own 401).
  /// Tests can substitute a Dio whose [HttpClientAdapter] is stubbed.
  @visibleForTesting
  Dio Function()? refreshDioFactory;

  /// Called when token refresh fails — signals that the session is expired
  VoidCallback? onSessionExpired;

  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _cachedUserKey = 'cached_user';

  /// Auth paths that should NOT trigger 401 auto-retry
  static const _authPaths = [
    '/auth/send-otp',
    '/auth/verify-otp',
    '/auth/refresh',
  ];

  ApiClient({FlutterSecureStorage? storage, this.onSessionExpired})
    : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.apiTimeout,
        receiveTimeout: AppConfig.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
    // Retries run AFTER auth (so 401 refresh still happens first) and only
    // on idempotent requests. See RetryInterceptor for details.
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
    // Sentry's Dio interceptor creates an HTTP span per request and tags
    // failed responses on the active transaction. Added LAST so the auth
    // + retry behavior is already settled by the time we observe it.
    // Request/response body capture is OFF by default in sentry v9
    // (`MaxRequestBodySize.never` / `MaxResponseBodySize.never`) — that's
    // what prevents OTP/phone/password request bodies from being attached
    // to Sentry events. Leave the addSentry call argument-less to inherit
    // those defaults.
    _dio.addSentry();
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token if available (with safety for secure storage failures)
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('ApiClient: Failed to read auth token: $e');
    }
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 for non-auth endpoints
    if (error.response?.statusCode == 401 &&
        !_authPaths.any((p) => error.requestOptions.path.contains(p))) {
      final refreshed = await _tryRefreshAndRetry(error, handler);
      if (refreshed) return;
    }
    handler.next(error);
  }

  Future<bool> _tryRefreshAndRetry(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      // No refresh token in storage — the original 401 is a real logout
      // (e.g. user signed out elsewhere, or storage was wiped).
      _handleSessionExpired();
      return false;
    }

    // Use a separate Dio instance to avoid interceptor recursion. Tests can
    // override the factory to drive controlled responses.
    final refreshDio =
        refreshDioFactory?.call() ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: AppConfig.apiTimeout,
            receiveTimeout: AppConfig.apiTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data!;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await _storage.write(key: _tokenKey, value: newAccessToken);
      await _storage.write(key: _refreshTokenKey, value: newRefreshToken);

      // Retry the original request with the new token
      final opts = error.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(opts);
      handler.resolve(retryResponse);
      return true;
    } on DioException catch (e) {
      // Only treat a real 401 from /auth/refresh as session-expired. Anything
      // else (timeout, connection error, 5xx, badCertificate, cancel) means
      // we couldn't *verify* the refresh token, not that it's invalid — wiping
      // the user out here is the wrong call. Propagate the original error so
      // the caller surfaces a normal API error and the cached session stays
      // intact until either the request succeeds on retry or the server
      // genuinely rejects the refresh.
      if (e.response?.statusCode == 401) {
        debugPrint('Token refresh rejected (401): real logout');
        _handleSessionExpired();
      } else {
        debugPrint(
          'Token refresh transient failure (${e.type} / '
          '${e.response?.statusCode}); keeping session',
        );
      }
      return false;
    } catch (e) {
      // Non-Dio failures (e.g. malformed response, storage write failure):
      // also treat as transient — better to leave the user signed in and let
      // them retry than to log them out on an unexpected client-side error.
      debugPrint('Token refresh unexpected error: $e; keeping session');
      return false;
    }
  }

  void _handleSessionExpired() {
    // Clear tokens
    _storage.delete(key: _tokenKey);
    _storage.delete(key: _refreshTokenKey);
    onSessionExpired?.call();
  }

  /// Map DioException to ApiException
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please try again.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'No internet connection. Please check your network.',
          code: 'NO_CONNECTION',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return const ApiException(
          message: 'Request was cancelled.',
          code: 'CANCELLED',
        );

      default:
        return ApiException(
          message: error.message ?? 'An unexpected error occurred.',
          code: 'UNKNOWN',
        );
    }
  }

  ApiException _handleBadResponse(Response? response) {
    if (response == null) {
      return const ApiException(
        message: 'No response from server.',
        code: 'NO_RESPONSE',
      );
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    String message = 'Request failed';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
    }

    switch (statusCode) {
      case 400:
        return ApiException(message: message, code: 'BAD_REQUEST');
      case 401:
        return ApiException(message: message, code: 'UNAUTHORIZED');
      case 403:
        return ApiException(message: message, code: 'FORBIDDEN');
      case 404:
        return ApiException(message: message, code: 'NOT_FOUND');
      case 409:
        return ApiException(message: message, code: 'CONFLICT');
      case 422:
        return ApiException(message: message, code: 'VALIDATION_ERROR');
      case 429:
        return const ApiException(
          message: 'Too many requests. Please try again later.',
          code: 'RATE_LIMITED',
        );
      case 500:
      case 502:
      case 503:
        return const ApiException(
          message: 'Server error. Please try again later.',
          code: 'SERVER_ERROR',
        );
      default:
        return ApiException(message: message, code: 'HTTP_$statusCode');
    }
  }

  /// Set the authentication token
  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Clear the authentication token
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Get the current token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Set the refresh token
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Clear the refresh token
  Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Get the refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Persist the last-known authenticated user as a JSON blob so we can
  /// re-hydrate the session on cold start when `/users/me` is temporarily
  /// unreachable (deploy window, dead socket, DNS glitch). Without this,
  /// a transient `getMe()` failure would otherwise force a logout.
  Future<void> setCachedUser(String userJson) async {
    await _storage.write(key: _cachedUserKey, value: userJson);
  }

  Future<String?> getCachedUser() async {
    try {
      return await _storage.read(key: _cachedUserKey);
    } catch (e) {
      debugPrint('ApiClient: Failed to read cached user: $e');
      return null;
    }
  }

  Future<void> clearCachedUser() async {
    await _storage.delete(key: _cachedUserKey);
  }

  /// POST request without authentication (for auth endpoints)
  Future<T> postWithoutAuth<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file with multipart form data
  Future<T> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(filePath),
        ...?additionalFields,
      });

      final response = await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          sendTimeout: AppConfig.imageUploadTimeout,
          receiveTimeout: AppConfig.imageUploadTimeout,
        ),
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload multiple files
  Future<T> uploadFiles<T>(
    String path, {
    required List<String> filePaths,
    required String fileField,
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final files = await Future.wait(
        filePaths.map((path) => MultipartFile.fromFile(path)),
      );

      final formData = FormData.fromMap({
        fileField: files,
        ...?additionalFields,
      });

      final response = await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          sendTimeout: AppConfig.imageUploadTimeout,
          receiveTimeout: AppConfig.imageUploadTimeout,
        ),
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
