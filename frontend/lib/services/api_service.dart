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
  // Function to get Booking Confirmation leads
  Future<Map<String, dynamic>> getBookingConfirmationLeads({
    String? store,
  }) async {
    final url = Uri.parse(ApiConfig.bookingConfirmationLeads(store: store));

    try {
      final headers = await _getAuthHeaders();
      print('ApiService: Fetching Booking Confirmation leads');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Response status: ${response.statusCode}');
      print('ApiService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Backend returns: { "leads": [ ... ] }
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('leads')) {
            return {'data': decoded['leads']};
          }
          return decoded;
        } else if (decoded is List) {
          return {'data': decoded};
        } else {
          throw Exception(
            'Unexpected response format for booking confirmation',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load Booking Confirmation leads: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('ApiService: Error fetching Booking Confirmation leads: $e');
      rethrow;
    }
  }

  // Function to get Rent-out leads
  Future<Map<String, dynamic>> getRentOutLeads({String? store}) async {
    final url = Uri.parse(ApiConfig.rentOutLeads(store: store));

    try {
      final headers = await _getAuthHeaders();
      print('ApiService: Fetching Rent-Out leads');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Rent-Out response status: ${response.statusCode}');
      print('ApiService: Rent-Out response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Normalize to { "data": [...] }
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('leads')) {
            return {'data': decoded['leads']};
          }
          if (decoded.containsKey('data')) {
            return {'data': decoded['data']};
          }
          // If map but no known key, wrap entire thing
          return {
            'data': [decoded],
          };
        } else if (decoded is List) {
          return {'data': decoded};
        } else {
          throw Exception('Unexpected response format for Rent-Out leads');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load Rent-Out leads: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('ApiService: Error fetching Rent-Out leads: $e');
      rethrow;
    }
  }

  // Function to get all leads with pagination, store filter, and date filters
  Future<Map<String, dynamic>> getAllLeads({
    String? store,
    int? page,
    String? enquiryDateFrom,
    String? enquiryDateTo,
    String? functionDateFrom,
    String? functionDateTo,
    String? visitDateFrom,
    String? visitDateTo,
    String? dateFrom,
    String? dateTo,
    String? dateField,
    String? createdAt,
  }) async {
    final url = Uri.parse(
      ApiConfig.getAllLeads(
        store: store,
        page: page,
        enquiryDateFrom: enquiryDateFrom,
        enquiryDateTo: enquiryDateTo,
        functionDateFrom: functionDateFrom,
        functionDateTo: functionDateTo,
        visitDateFrom: visitDateFrom,
        visitDateTo: visitDateTo,
        dateFrom: dateFrom,
        dateTo: dateTo,
        dateField: dateField,
        createdAt: createdAt,
      ),
    );

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      print('ApiService: Fetching all leads');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: All leads response status: ${response.statusCode}');
      print('ApiService: All leads response body: ${response.body}');

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
          'Failed to load all leads: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('ApiService: Error fetching all leads: $e');
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
          // Save user name if present
          if (user.containsKey('name')) {
            await AuthService.saveUserName(user['name'].toString());
            print('ApiService: User name saved: ${user['name']}');
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

  /// Update Loss of Sale lead
  Future<Map<String, dynamic>> updateLossOfSaleLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    String? followUpDate,
    String? reasonCollectedFromStore,
    String? remarks,
  }) async {
    final url = Uri.parse(ApiConfig.updateLossOfSale(id));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body
      final requestBody = <String, dynamic>{};
      if (callStatus != null) requestBody['call_status'] = callStatus;
      if (leadStatus != null) requestBody['lead_status'] = leadStatus;
      if (followUpDate != null) requestBody['follow_up_date'] = followUpDate;
      if (reasonCollectedFromStore != null) {
        requestBody['reason_collected_from_store'] = reasonCollectedFromStore;
      }
      if (remarks != null) requestBody['remarks'] = remarks;

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Updating Loss of Sale lead');
      print('ApiService: URL => $url');
      print('ApiService: Request body => $requestBodyJson');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print('ApiService: Update response status: ${response.statusCode}');
      print('ApiService: Update response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'success': true, 'data': decodedResponse};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Failed to update Loss of Sale lead: Status ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                errorMessage;
          }
        } catch (e) {
          print('ApiService: Could not parse error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ApiService: Error updating Loss of Sale lead: $e');
      rethrow;
    }
  }

  /// Add a new lead
  Future<Map<String, dynamic>> addLead({
    required String customerName,
    required String phoneNumber,
    String? brand,
    String? storeLocation,
    String? leadStatus,
    String? callStatus,
    DateTime? followUpDate,
  }) async {
    final url = Uri.parse(ApiConfig.addLead());

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body
      final requestBody = <String, dynamic>{
        'customer_name': customerName,
        'phone_number': phoneNumber,
      };

      if (brand != null) requestBody['brand'] = brand;
      if (storeLocation != null) requestBody['store_location'] = storeLocation;
      if (leadStatus != null) requestBody['lead_status'] = leadStatus;
      if (callStatus != null) requestBody['call_status'] = callStatus;
      if (followUpDate != null) {
        requestBody['follow_up_date'] = followUpDate.toIso8601String();
      }

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Adding new lead');
      print('ApiService: URL => $url');
      print('ApiService: Request body => $requestBodyJson');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print('ApiService: Add lead response status: ${response.statusCode}');
      print('ApiService: Add lead response body: ${response.body}');

      if (response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'success': true, 'data': decodedResponse};
      } else if (response.statusCode == 400) {
        // Validation error - try to get detailed error message
        String errorMessage = 'Validation error. Please check your input.';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                errorMessage;
          }
        } catch (e) {
          print('ApiService: Could not parse error response: $e');
        }
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Only admin or teamLead can add leads');
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Failed to add lead: Status ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                errorMessage;
          }
        } catch (e) {
          print('ApiService: Could not parse error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ApiService: Error adding lead: $e');
      rethrow;
    }
  }

  /// Update Rent-Out lead
  Future<Map<String, dynamic>> updateRentOutLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    int? rating,
    String? remarks,
  }) async {
    final url = Uri.parse(ApiConfig.updateRentOut(id));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body
      final requestBody = <String, dynamic>{};
      if (callStatus != null) requestBody['call_status'] = callStatus;
      if (leadStatus != null) requestBody['lead_status'] = leadStatus;
      if (followUpFlag != null) requestBody['follow_up_flag'] = followUpFlag;
      if (callDate != null) {
        requestBody['call_date'] = callDate.toIso8601String();
      }
      if (rating != null) requestBody['rating'] = rating;
      if (remarks != null) requestBody['remarks'] = remarks;

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Updating Rent-Out lead');
      print('ApiService: URL => $url');
      print('ApiService: Request body => $requestBodyJson');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print('ApiService: Update response status: ${response.statusCode}');
      print('ApiService: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'success': true, 'data': decodedResponse};
      } else if (response.statusCode == 400) {
        // Validation error - try to get detailed error message
        String errorMessage = 'Validation error. Please check your input.';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                errorMessage;
          }
        } catch (e) {
          print('ApiService: Could not parse error response: $e');
        }
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Failed to update Rent-Out lead: Status ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                errorMessage;
          }
        } catch (e) {
          print('ApiService: Could not parse error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ApiService: Error updating Rent-Out lead: $e');
      rethrow;
    }
  }

  /// Update Booking Confirmation lead
  Future<Map<String, dynamic>> updateBookingConfirmationLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    String? remarks,
  }) async {
    final url = Uri.parse(ApiConfig.updateBookingConfirmation(id));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body
      final requestBody = <String, dynamic>{};
      if (callStatus != null) requestBody['call_status'] = callStatus;
      if (leadStatus != null) requestBody['lead_status'] = leadStatus;
      if (followUpFlag != null) requestBody['follow_up_flag'] = followUpFlag;
      if (callDate != null) {
        requestBody['call_date'] = callDate.toIso8601String();
      }
      if (remarks != null) requestBody['remarks'] = remarks;

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Updating Booking Confirmation lead');
      print('ApiService: URL => $url');
      print('ApiService: Request body => $requestBodyJson');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print('ApiService: Update response status: ${response.statusCode}');
      print('ApiService: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'success': true, 'data': decodedResponse};
      } else if (response.statusCode == 400) {
        // Validation error - try to get detailed error message
        String errorMessage = 'Validation error. Please check your input.';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                errorMessage;
          }
        } catch (e) {
          print('ApiService: Could not parse error response: $e');
        }
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Failed to update Booking Confirmation lead: Status ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                errorMessage;
          }
        } catch (e) {
          print('ApiService: Could not parse error response: $e');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('ApiService: Error updating Booking Confirmation lead: $e');
      rethrow;
    }
  }

  /// Get reports (edited leads) from API
  Future<Map<String, dynamic>> getReports({
    String? leadType,
    String? editedBy,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
  }) async {
    final url = Uri.parse(
      ApiConfig.getReports(
        leadType: leadType,
        editedBy: editedBy,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
        limit: limit,
      ),
    );

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      print('ApiService: Fetching reports');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Reports response status: ${response.statusCode}');
      print('ApiService: Reports response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        // Handle both Map and List responses
        if (decodedResponse is Map<String, dynamic>) {
          return decodedResponse;
        } else if (decodedResponse is List) {
          return {'reports': decodedResponse, 'pagination': {}};
        } else {
          throw Exception('Unexpected response format from server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load reports: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('ApiService: Error fetching reports: $e');
      rethrow;
    }
  }

  /// Get a single report by ID
  Future<Map<String, dynamic>> getReportById(String id) async {
    final url = Uri.parse(ApiConfig.getReportById(id));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      print('ApiService: Fetching report by ID: $id');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Report response status: ${response.statusCode}');
      print('ApiService: Report response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'data': decodedResponse};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load report: Status ${response.statusCode}');
      }
    } catch (e) {
      print('ApiService: Error fetching report by ID: $e');
      rethrow;
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
