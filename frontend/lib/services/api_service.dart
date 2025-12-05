import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:telecaller_app/services/auth_service.dart';
import 'package:telecaller_app/utils/api_config.dart';

class ApiService {
  // Function to get Loss of Sale leads
  Future<Map<String, dynamic>> getLossOfSaleLeads({
    String? store,
    String? enquiryFrom,
    String? enquiryTo,
    String? functionFrom,
    String? functionTo,
    String? visitFrom,
    String? visitTo,
  }) async {
    final url = Uri.parse(
      ApiConfig.lossOfSaleLeads(
        store: store,
        enquiryFrom: enquiryFrom,
        enquiryTo: enquiryTo,
        functionFrom: functionFrom,
        functionTo: functionTo,
        visitFrom: visitFrom,
        visitTo: visitTo,
      ),
    );

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        // Handle both Map and List responses
        if (decodedResponse is Map<String, dynamic>) {
          return decodedResponse;
        } else if (decodedResponse is List) {
          return {'data': decodedResponse};
        } else {
          throw Exception('Unexpected response format from server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load Loss of Sale leads: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('ApiService: Error fetching Loss of Sale leads: $e');
      rethrow;
    }
  }

  // Function to get Walk-in leads
  Future<Map<String, dynamic>> getWalkInLeads() async {
    final url = Uri.parse(ApiConfig.walkInLeads());

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load Walk-in leads');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Function to get Booking Confirmation leads
  Future<Map<String, dynamic>> getBookingConfirmationLeads() async {
    final url = Uri.parse(ApiConfig.bookingConfirmationLeads());

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load Booking Confirmation leads');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Function to get Rent-out leads
  Future<Map<String, dynamic>> getRentOutLeads() async {
    final url = Uri.parse(ApiConfig.rentOutLeads());

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load Rent-out leads');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String empId,
    required String password,
  }) async {
    final url = Uri.parse(ApiConfig.login());

    try {
      // Prepare request body - backend expects "employeeId" not "empId"
      final requestBody = {"employeeId": empId, "password": password};

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Attempting login for EMP ID: $empId');
      print('ApiService: Login URL: $url');
      print('ApiService: Request body: $requestBodyJson');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: requestBodyJson,
      );

      print('ApiService: Login response status: ${response.statusCode}');
      print('ApiService: Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Save token if present in response
        if (responseData.containsKey('token')) {
          await AuthService.saveToken(responseData['token'] as String);
          print('ApiService: Token saved successfully');
        }

        // Save refresh token if present
        if (responseData.containsKey('refreshToken')) {
          await AuthService.saveRefreshToken(
            responseData['refreshToken'] as String,
          );
        }

        // Save user data if present
        if (responseData.containsKey('user')) {
          final user = responseData['user'] as Map<String, dynamic>;
          if (user.containsKey('_id') || user.containsKey('id')) {
            await AuthService.saveUserId(
              (user['_id'] ?? user['id']).toString(),
            );
          }
          if (user.containsKey('empId')) {
            await AuthService.saveEmpId(user['empId'].toString());
          }
        } else if (responseData.containsKey('userId')) {
          await AuthService.saveUserId(responseData['userId'].toString());
        }

        // Save EMP ID
        await AuthService.saveEmpId(empId);

        return responseData;
      } else if (response.statusCode == 400) {
        // Bad Request - try to get detailed error message
        String errorMessage = 'Invalid request. Please check your credentials.';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                'Invalid request format. Please check your EMP ID and Password.';

            // Check for validation errors
            if (errorData.containsKey('errors')) {
              final errors = errorData['errors'];
              if (errors is List) {
                // Handle array of error objects like [{"field":"employeeId", "message":"..."}]
                final errorMessages =
                    errors
                        .where((e) => e is Map && e.containsKey('message'))
                        .map((e) => (e as Map)['message'].toString())
                        .toList();
                if (errorMessages.isNotEmpty) {
                  errorMessage = errorMessages.join(', ');
                }
              } else if (errors is Map) {
                final errorList =
                    errors.values.map((e) => e.toString()).toList();
                if (errorList.isNotEmpty) {
                  errorMessage = errorList.join(', ');
                }
              }
            }
          } else if (errorData is String) {
            errorMessage = errorData;
          }
        } catch (e) {
          print('ApiService: Could not parse error response: $e');
          errorMessage =
              'Bad request. Please check your EMP ID and Password format.';
        }
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception("Invalid EMP ID or Password");
      } else {
        // Try to parse error message from response
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Login failed. Please try again.';

          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                'Login failed. Please try again.';
          } else if (errorData is String) {
            errorMessage = errorData;
          }

          throw Exception(errorMessage);
        } catch (_) {
          throw Exception(
            'Login failed: Status ${response.statusCode}. ${response.body.isNotEmpty ? response.body : "Please try again."}',
          );
        }
      }
    } catch (e) {
      print('ApiService: Login error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Get authentication headers for API requests
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
