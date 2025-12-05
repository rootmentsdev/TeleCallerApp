import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage authentication tokens
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _empIdKey = 'emp_id';

  /// Get the stored authentication token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  /// Save the authentication token
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }

  /// Get the stored refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      print('Error getting refresh token: $e');
      return null;
    }
  }

  /// Save the refresh token
  static Future<bool> saveRefreshToken(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_refreshTokenKey, refreshToken);
    } catch (e) {
      print('Error saving refresh token: $e');
      return false;
    }
  }

  /// Save user ID
  static Future<bool> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userIdKey, userId);
    } catch (e) {
      print('Error saving user ID: $e');
      return false;
    }
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  /// Save EMP ID
  static Future<bool> saveEmpId(String empId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_empIdKey, empId);
    } catch (e) {
      print('Error saving EMP ID: $e');
      return false;
    }
  }

  /// Get EMP ID
  static Future<String?> getEmpId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_empIdKey);
    } catch (e) {
      print('Error getting EMP ID: $e');
      return null;
    }
  }

  /// Clear all authentication data
  static Future<bool> clearAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_empIdKey);
      return true;
    } catch (e) {
      print('Error clearing auth: $e');
      return false;
    }
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
