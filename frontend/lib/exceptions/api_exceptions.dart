/// Custom exception classes for API and application errors
/// Provides typed error handling and better error tracking

/// Base exception for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}

/// Exception for authentication failures
class AuthenticationException extends ApiException {
  AuthenticationException({String? message})
    : super(
        message ?? 'Authentication failed. Please login again.',
        statusCode: 401,
      );
}

/// Exception for network-related errors
class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

/// Exception for data validation errors
class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}

/// Exception for data parsing/deserialization errors
class DataParsingException extends ApiException {
  DataParsingException(String message) : super(message);
}

/// Exception for storage-related errors
class StorageException extends ApiException {
  StorageException(String message) : super(message);
}

/// Exception for business logic errors
class BusinessLogicException extends ApiException {
  BusinessLogicException(String message) : super(message);
}
