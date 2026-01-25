import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';

/// API Client for communicating with Tekka backend
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  ApiClient({FlutterSecureStorage? storage})
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
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token if available
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    final exception = _handleError(error);
    handler.reject(
      DioException(
        requestOptions: error.requestOptions,
        error: exception,
        response: error.response,
        type: error.type,
      ),
    );
  }

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

  /// POST request without authentication (for auth endpoints)
  Future<T> postWithoutAuth<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
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
  }

  /// GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  /// POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  /// PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  /// DELETE request
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  /// Upload file with multipart form data
  Future<T> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileField,
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onSendProgress,
  }) async {
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
  }

  /// Upload multiple files
  Future<T> uploadFiles<T>(
    String path, {
    required List<String> filePaths,
    required String fileField,
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onSendProgress,
  }) async {
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
  }
}
