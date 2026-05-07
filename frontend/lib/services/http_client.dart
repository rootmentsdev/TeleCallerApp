/// HTTP Client wrapper for centralized API communication
/// Eliminates duplication of HTTP request/response handling

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/exceptions/api_exceptions.dart';
import 'package:telecaller_app/services/auth_service.dart';

class HttpClient {
  static const int _defaultTimeout = 30; // seconds

  /// Get request with automatic header management
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final headers = await _getHeaders(additionalHeaders);
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: _defaultTimeout));

      return _handleResponse(response);
    } catch (e, s) {
      _logError('GET', url, e, s);
      rethrow;
    }
  }

  /// POST request with automatic header management
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final headers = await _getHeaders(additionalHeaders);
      final response = await http
          .post(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(Duration(seconds: _defaultTimeout));

      return _handleResponse(response);
    } catch (e, s) {
      _logError('POST', url, e, s);
      rethrow;
    }
  }

  /// PUT request with automatic header management
  Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final headers = await _getHeaders(additionalHeaders);
      final response = await http
          .put(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(Duration(seconds: _defaultTimeout));

      return _handleResponse(response);
    } catch (e, s) {
      _logError('PUT', url, e, s);
      rethrow;
    }
  }

  /// DELETE request with automatic header management
  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final headers = await _getHeaders(additionalHeaders);
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: _defaultTimeout));

      return _handleResponse(response);
    } catch (e, s) {
      _logError('DELETE', url, e, s);
      rethrow;
    }
  }

  /// Get authorization headers
  Future<Map<String, String>> _getHeaders(
    Map<String, String>? additionalHeaders,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handle HTTP response and parse JSON
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseResponse(response.body);
    } else if (response.statusCode == 401) {
      throw AuthenticationException();
    } else if (response.statusCode == 400) {
      throw ValidationException('Invalid request: ${response.body}');
    } else if (response.statusCode >= 500) {
      throw NetworkException('Server error: ${response.statusCode}');
    } else {
      throw ApiException(
        'Request failed with status ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Parse JSON response
  Map<String, dynamic> _parseResponse(String body) {
    try {
      final decoded = json.decode(body);

      if (decoded is Map<String, dynamic>) {
        // If response has 'data' key, return it
        if (decoded.containsKey('data')) {
          return {'data': decoded['data']};
        }
        // If response has 'leads' key, return it as data
        if (decoded.containsKey('leads')) {
          return {'data': decoded['leads']};
        }
        // Return the entire response
        return decoded;
      } else if (decoded is List) {
        // Wrap list in data key
        return {'data': decoded};
      }

      return {'data': []};
    } catch (e) {
      throw DataParsingException('Failed to parse response: $e');
    }
  }

  /// Log errors to console and Crashlytics
  void _logError(
    String method,
    String url,
    dynamic error,
    StackTrace stackTrace,
  ) {
    print('HttpClient: $method $url failed: $error');
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: '$method request to $url failed',
    );
  }
}
