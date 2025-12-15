import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage authentication tokens
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _empIdKey = 'emp_id';
  static const String _userNameKey = 'user_name';

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

  /// Save user name
  static Future<bool> saveUserName(String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userNameKey, userName);
    } catch (e) {
      print('Error saving user name: $e');
      return false;
    }
  }

  /// Get user name
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }

  /// Clear all authentication data
  static Future<bool> clearAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Log what we're clearing for debugging
      print('AuthService: Clearing authentication data');
      print('  - Token exists: ${prefs.getString(_tokenKey) != null}');
      print(
        '  - Refresh token exists: ${prefs.getString(_refreshTokenKey) != null}',
      );
      print('  - User ID exists: ${prefs.getString(_userIdKey) != null}');

      // Check if leads data exists before clearing auth
      final leadsData = prefs.getString('saved_leads');
      print('  - Leads data exists: ${leadsData != null}');
      if (leadsData != null) {
        print('  - Leads data size: ${leadsData.length} characters');
      }

      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_empIdKey);
      await prefs.remove(_userNameKey);

      // NOTE: We are NOT clearing 'saved_leads' - this should persist across logins
      print('AuthService: Authentication data cleared, leads data preserved');

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
