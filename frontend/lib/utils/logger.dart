/// Centralized logging utility
/// Replaces print statements with structured logging

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class Logger {
  static const String _prefix = '[TeleCaller]';

  /// Log info level messages
  static void info(String message) {
    print('$_prefix [INFO] $message');
  }

  /// Log debug level messages
  static void debug(String message) {
    print('$_prefix [DEBUG] $message');
  }

  /// Log warning level messages
  static void warning(String message) {
    print('$_prefix [WARN] $message');
  }

  /// Log error level messages with optional stack trace
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    print('$_prefix [ERROR] $message');
    if (error != null) {
      print('$_prefix [ERROR] Error: $error');
    }
    if (stackTrace != null) {
      print('$_prefix [ERROR] StackTrace: $stackTrace');
    }

    // Also log to Crashlytics for production monitoring
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
      );
    }
  }

  /// Log API requests
  static void apiRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) {
    info('API $method $url');
    if (body != null) {
      debug('Request body: $body');
    }
  }

  /// Log API responses
  static void apiResponse(
    String method,
    String url,
    int statusCode, {
    String? body,
  }) {
    info('API $method $url - Status: $statusCode');
    if (body != null && body.isNotEmpty) {
      debug('Response body: $body');
    }
  }
}
