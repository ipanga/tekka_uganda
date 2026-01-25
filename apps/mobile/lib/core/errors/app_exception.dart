/// Base exception class for Tekka app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory AuthException.invalidOtp() => const AuthException(
        message: 'Invalid OTP. Please try again.',
        code: 'invalid-otp',
      );

  factory AuthException.otpExpired() => const AuthException(
        message: 'OTP has expired. Please request a new one.',
        code: 'otp-expired',
      );

  factory AuthException.tooManyRequests() => const AuthException(
        message: 'Too many requests. Please wait before trying again.',
        code: 'too-many-requests',
      );

  factory AuthException.invalidPhone() => const AuthException(
        message: 'Invalid phone number format.',
        code: 'invalid-phone',
      );

  factory AuthException.userNotFound() => const AuthException(
        message: 'User not found.',
        code: 'user-not-found',
      );

  factory AuthException.sessionExpired() => const AuthException(
        message: 'Your session has expired. Please login again.',
        code: 'session-expired',
      );
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code,
    this.fieldErrors,
  });
}

/// Storage exceptions
class StorageException extends AppException {
  const StorageException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Listing-related exceptions
class ListingException extends AppException {
  const ListingException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory ListingException.notFound() => const ListingException(
        message: 'Listing not found.',
        code: 'listing-not-found',
      );

  factory ListingException.limitReached() => const ListingException(
        message: 'You have reached the maximum number of listings.',
        code: 'listing-limit-reached',
      );

  factory ListingException.uploadFailed() => const ListingException(
        message: 'Failed to upload images. Please try again.',
        code: 'upload-failed',
      );
}

/// Server exceptions
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  factory ServerException.internalError() => const ServerException(
        message: 'An unexpected error occurred. Please try again.',
        code: 'internal-error',
        statusCode: 500,
      );

  factory ServerException.serviceUnavailable() => const ServerException(
        message: 'Service temporarily unavailable. Please try again later.',
        code: 'service-unavailable',
        statusCode: 503,
      );
}

/// API-related exceptions
class ApiException extends AppException {
  const ApiException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory ApiException.timeout() => const ApiException(
        message: 'Connection timed out. Please try again.',
        code: 'TIMEOUT',
      );

  factory ApiException.noConnection() => const ApiException(
        message: 'No internet connection. Please check your network.',
        code: 'NO_CONNECTION',
      );

  factory ApiException.unauthorized() => const ApiException(
        message: 'Please login to continue.',
        code: 'UNAUTHORIZED',
      );

  factory ApiException.forbidden() => const ApiException(
        message: 'You do not have permission to perform this action.',
        code: 'FORBIDDEN',
      );

  factory ApiException.notFound() => const ApiException(
        message: 'The requested resource was not found.',
        code: 'NOT_FOUND',
      );

  factory ApiException.serverError() => const ApiException(
        message: 'Server error. Please try again later.',
        code: 'SERVER_ERROR',
      );
}
