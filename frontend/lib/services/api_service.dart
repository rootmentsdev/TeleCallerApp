import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:telecaller_app/services/auth_service.dart';
import 'package:telecaller_app/utils/api_config.dart';

class ApiService {
  // Callback for session expiry - should be set by main app
  static Function? onSessionExpired;

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
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getWalkInLeads failed',
      );
      rethrow;
    }
  }

  // Function to get Return leads
  Future<Map<String, dynamic>> getReturnLeads({
    String? store,
    int? page,
    int? limit,
  }) async {
    final url = Uri.parse(
      ApiConfig.returnLeads(store: store, page: page, limit: limit),
    );

    try {
      final headers = await _getAuthHeaders();
      print('ApiService: Fetching Return leads from: $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Return response status: ${response.statusCode}');
      print('ApiService: Return response body: ${response.body}');

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
          if (decoded.containsKey('return')) {
            return {'data': decoded['return']};
          }
          // If map but no known key, wrap entire thing
          return {
            'data': [decoded],
          };
        } else if (decoded is List) {
          return {'data': decoded};
        } else {
          throw Exception('Unexpected response format for Return leads');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load Return leads: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getReturnLeads failed',
      );
      rethrow;
    }
  }

  // Function to get Return lead details
  Future<Map<String, dynamic>> getReturn(String id) async {
    final url = Uri.parse(ApiConfig.getReturn(id));

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Normalize snake_case to camelCase
        if (decoded is Map<String, dynamic>) {
          final normalized = <String, dynamic>{};
          decoded.forEach((key, value) {
            // Convert snake_case to camelCase
            final camelKey = _snakeToCamel(key);
            normalized[camelKey] = value;
          });
          return normalized;
        }

        return decoded;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load Return lead: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getReturn failed',
      );
      rethrow;
    }
  }

  /// Update Return lead
  Future<Map<String, dynamic>> updateReturn({
    required String id,
    String? callStatus,
    String? leadStatus,
    DateTime? callDate,
    int? rating,
    String? remarks,
    int? callDuration,
    bool? followUpFlag,
    DateTime? followUpDate,
    bool? isStarred,
  }) async {
    final url = Uri.parse(ApiConfig.updateReturn(id));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body
      // IMPORTANT: Always include call_status and lead_status (backend may require these)
      final requestBody = <String, dynamic>{
        'call_status': callStatus ?? 'Not Called',
        'lead_status': leadStatus ?? 'No Status',
      };

      if (callDate != null) {
        requestBody['call_date'] = callDate.toIso8601String();
      }
      if (rating != null && rating > 0) {
        requestBody['rating'] = rating;
      }
      // Only include remarks if it's not null and not empty (backend validation requires string, not null)
      if (remarks != null && remarks.trim().isNotEmpty) {
        requestBody['remarks'] = remarks.trim();
      }
      // IMPORTANT: Include duration even if 0, as 0 is a valid duration for unanswered calls
      // Backend needs duration 0 to create report entries
      if (callDuration != null) {
        requestBody['call_duration'] = callDuration;
      }

      // Handle follow-up flag and date
      if (followUpFlag != null) {
        requestBody['follow_up_flag'] = followUpFlag;
        if (followUpFlag && followUpDate != null) {
          requestBody['follow_up_date'] = followUpDate.toIso8601String();
        }
      } else if (followUpDate != null) {
        // If followUpDate is provided without flag, set flag to true
        requestBody['follow_up_flag'] = true;
        requestBody['follow_up_date'] = followUpDate.toIso8601String();
      }

      // Handle mark as issue (starred)
      if (isStarred != null) {
        requestBody['mark_as_issue'] = isStarred;
      }

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Updating Return lead');
      print('ApiService: POST URL => $url');
      print('ApiService: Request body => $requestBodyJson');

      // IMPORTANT: API documentation shows POST method, not PUT
      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print('ApiService: Update response status: ${response.statusCode}');
      print('ApiService: Update response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {};
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
      } else if (response.statusCode == 404) {
        throw Exception('Return lead not found');
      } else {
        // Try to parse error message from response
        String errorMessage =
            'Failed to update Return lead: Status ${response.statusCode}';
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
    } catch (e, s) {
      print('ApiService: Error updating Return lead: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateReturn failed',
      );
      rethrow;
    }
  }

  /// Convert snake_case to camelCase
  String _snakeToCamel(String str) {
    List<String> parts = str.split('_');
    if (parts.length == 1) return str;

    String camel = parts[0];
    for (int i = 1; i < parts.length; i++) {
      String part = parts[i];
      if (part.isNotEmpty) {
        camel += part[0].toUpperCase() + part.substring(1);
      }
    }
    return camel;
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
    } catch (e, s) {
      print('ApiService: Error fetching all leads: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getAllLeads failed',
      );
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
    } catch (e, s) {
      print('ApiService: Login error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'loginUser failed',
      );
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Create a new lead (Walk-in/General lead)
  /// Matches backend POST /api/pages/add-lead
  Future<Map<String, dynamic>> createLead({
    required String leadName,
    required String phoneNumber,
    required String store,
    required String source,
    required String leadType,
    String? remarks,
    bool followUpFlag = false,
    String? functionDate,
    String? followUpDate,
    String? createdAt,
    String? bookingNumber,
    int securityAmount = 0,
    int? callDuration,
    String? subCategory,
    String? itemCategory,
    String? closingAction,
    bool markAsComplaint = false,
  }) async {
    final url = Uri.parse(ApiConfig.addLead());

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body with EXACT fields required by backend
      // Normalize leadType to lowercase format expected by backend
      // Convert: "Enquiry" -> "enquiry", "Booking" -> "booked"
      String normalizedLeadType = leadType.toLowerCase();
      if (normalizedLeadType == 'booking') {
        normalizedLeadType = 'booked';
      }

      final requestBody = <String, dynamic>{
        'customer_name': leadName,
        'phone_number': phoneNumber,
        'brand': store.contains('-') ? store.split('-')[0] : store,
        'store_location': store,
        'lead_status': 'No Status',
        'call_status': 'Not Called',
        'sub_category': subCategory,
        'item_category': itemCategory,
        'closing_action': closingAction,
        'reasons': remarks,
        'remarks': remarks,
        'lead_type': normalizedLeadType,
        'function_date': functionDate, // Only include if explicitly provided
        'created_at': createdAt,
        'mark_as_complaint': markAsComplaint,
        'follow_up_flag': followUpFlag,
        'follow_up_date':
            followUpFlag && followUpDate != null ? followUpDate : null,
        'call_duration':
            callDuration ?? 0, // Add call duration (0 if not provided)
      };

      print('ApiService: functionDate parameter received: $functionDate');
      print('ApiService: functionDate is null: ${functionDate == null}');

      // Remove null values
      requestBody.removeWhere((key, value) => value == null);

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Creating new lead');
      print('ApiService: URL => $url');
      print('ApiService: POST BODY SENT: $requestBodyJson');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print('ApiService: Create lead response status: ${response.statusCode}');
      print('ApiService: CREATED LEAD RESPONSE: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'success': true, 'data': decodedResponse};
      } else if (response.statusCode == 400) {
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
        // Session expired - try to refresh token
        final refreshed = await _handleUnauthorized();
        if (refreshed) {
          // Retry the request with new token
          return await createLead(
            leadName: leadName,
            phoneNumber: phoneNumber,
            store: store,
            source: source,
            leadType: leadType,
            remarks: remarks,
            followUpFlag: followUpFlag,
            functionDate: functionDate,
            bookingNumber: bookingNumber,
            securityAmount: securityAmount,
            callDuration: callDuration,
          );
        } else {
          // Token refresh failed, session expired
          onSessionExpired?.call();
          throw Exception('Session expired. Please login again.');
        }
      } else {
        String errorMessage =
            'Failed to create lead: Status ${response.statusCode}';
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
    } catch (e, s) {
      print('ApiService: Error creating lead: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'createLead failed',
      );
      rethrow;
    }
  }

  /// Update a lead (generic update for any lead type)
  /// Matches backend POST /api/pages/leads/{id}
  Future<Map<String, dynamic>> updateLead({
    required String id,
    required String leadName,
    required String phoneNumber,
    required String store,
    required String source,
    required String leadType,
    required String callStatus,
    required String leadStatus,
    String? remarks,
    bool followUpFlag = false,
    String? followUpDate,
    String? functionDate,
    String? bookingNumber,
    int securityAmount = 0,
    int? callDuration, // Call duration in seconds
    bool isStarred = false, // Whether the lead is starred
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/pages/leads/$id');

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body with EXACT snake_case fields required by backend
      // Backend expects: customer_name, phone_number, store_location, source, lead_status, call_status
      final requestBody = <String, dynamic>{
        'customer_name': leadName,
        'phone_number': phoneNumber,
        'store_location': store,
        'source': source,
        'call_status': callStatus,
        'lead_status': leadStatus,
      };

      // Add optional fields if provided
      // Only include remarks if user provided input (not empty string)
      // Backend expects remarks to be a string, so omit it if null/empty
      if (remarks != null && remarks.trim().isNotEmpty) {
        requestBody['remarks'] = remarks.trim();
      }
      // Don't include remarks field at all if null/empty (backend will use default or existing value)

      // When follow_up_flag is true, follow_up_date is REQUIRED by backend
      if (followUpFlag) {
        requestBody['follow_up_flag'] = followUpFlag;
        if (followUpDate != null && followUpDate.isNotEmpty) {
          requestBody['follow_up_date'] = followUpDate;
        } else {
          // If follow_up_flag is true but no date provided, throw error
          throw Exception(
            'follow_up_date is required when follow_up_flag is true. Please provide the follow-up date from frontend.',
          );
        }
      }

      // If follow_up_date is provided without follow_up_flag, set flag to true
      if (!followUpFlag && followUpDate != null && followUpDate.isNotEmpty) {
        requestBody['follow_up_flag'] = true;
        requestBody['follow_up_date'] = followUpDate;
      }
      if (functionDate != null && functionDate.isNotEmpty) {
        requestBody['function_date'] = functionDate;
      }
      if (bookingNumber != null && bookingNumber.isNotEmpty) {
        requestBody['booking_number'] = bookingNumber;
      }
      if (securityAmount > 0) {
        requestBody['security_amount'] = securityAmount;
      }

      // Add call_duration if provided (backend expects number in seconds)
      // IMPORTANT: Include duration even if 0, as 0 is a valid duration for unanswered calls
      // Backend needs duration 0 to create report entries
      if (callDuration != null) {
        requestBody['call_duration'] = callDuration;
      }

      // Add mark_as_issue flag (backend field for starred/important leads)
      requestBody['mark_as_issue'] = isStarred;

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Updating lead');
      print('ApiService: POST URL: $url');
      print('ApiService: POST BODY SENT: $requestBodyJson');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print('ApiService: Update lead response status: ${response.statusCode}');
      print('ApiService: Update lead response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'success': true, 'data': decodedResponse};
      } else if (response.statusCode == 400) {
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
        String errorMessage =
            'Failed to update lead: Status ${response.statusCode}';
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
    } catch (e, s) {
      print('ApiService: Error updating lead: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateLead failed',
      );
      rethrow;
    }
  }

  /// Update Return lead
  Future<Map<String, dynamic>> updateReturnLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    int? rating,
    String? remarks,
    int? callDuration,
    DateTime? followUpDate,
    bool? clearFollowUpDate,
    String? subCategory,
    String? itemCategory,
    DateTime? functionDate,
    String? leadType,
    bool? markAsComplaint,
    String? numberOfFunctions,
    String? numberOfAttires,
    String? competitor,
    String? service,
  }) async {
    final url = Uri.parse(ApiConfig.updateReturn(id));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body
      // IMPORTANT: Always include call_status and lead_status (backend may require these)
      final requestBody = <String, dynamic>{
        'call_status': callStatus ?? 'Not Called',
        'lead_status': leadStatus ?? 'No Status',
      };

      // Handle follow-up flag and date logic
      if (clearFollowUpDate == true) {
        requestBody['follow_up_flag'] = false;
        // Don't include follow_up_date when clearing
      } else if (followUpFlag != null) {
        requestBody['follow_up_flag'] = followUpFlag;
        // When follow_up_flag is true, send follow_up_date (required by backend)
        if (followUpFlag && followUpDate != null) {
          requestBody['follow_up_date'] = followUpDate.toIso8601String();
        } else if (followUpDate != null && !followUpFlag) {
          // If followUpDate is provided but flag is false, don't include it
        }
      } else if (followUpDate != null) {
        // If followUpDate is provided without flag, set flag to true
        requestBody['follow_up_flag'] = true;
        requestBody['follow_up_date'] = followUpDate.toIso8601String();
      }

      if (callDate != null) {
        requestBody['call_date'] = callDate.toIso8601String();
      }
      if (rating != null) requestBody['rating'] = rating;
      // Only include remarks if it's not null and not empty (backend validation requires string, not null)
      if (remarks != null && remarks.trim().isNotEmpty) {
        requestBody['remarks'] = remarks.trim();
      }
      // IMPORTANT: Include duration even if 0, as 0 is a valid duration for unanswered calls
      // Backend needs duration 0 to create report entries
      if (callDuration != null) {
        requestBody['call_duration'] = callDuration;
      }

      // Add optional fields if provided
      if (subCategory != null && subCategory.isNotEmpty) {
        requestBody['sub_category'] = subCategory;
      }
      if (itemCategory != null && itemCategory.isNotEmpty) {
        requestBody['item_category'] = itemCategory;
      }
      if (functionDate != null) {
        requestBody['function_date'] = functionDate.toIso8601String();
      }
      if (leadType != null && leadType.isNotEmpty) {
        requestBody['lead_type'] = leadType;
      }
      if (markAsComplaint != null) {
        requestBody['mark_as_complaint'] = markAsComplaint;
      }
      if (numberOfFunctions != null && numberOfFunctions.isNotEmpty) {
        requestBody['number_of_functions'] = numberOfFunctions;
      }
      if (numberOfAttires != null && numberOfAttires.isNotEmpty) {
        requestBody['number_of_attires'] = numberOfAttires;
      }
      if (competitor != null && competitor.isNotEmpty) {
        requestBody['competitor'] = competitor;
      }
      if (service != null && service.isNotEmpty) {
        requestBody['service'] = service;
      }

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Updating Return lead');
      print('ApiService: URL => $url');
      print('ApiService: Request body => $requestBodyJson');
      print('ApiService: Headers => $headers');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print('ApiService: Update response status: ${response.statusCode}');
      print('ApiService: Update response body: ${response.body}');

      if (response.statusCode == 404) {
        print(
          'ApiService: 404 Error - Endpoint not found. Check if lead ID is correct: $id',
        );
        print('ApiService: Full URL was: $url');
      }

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
            'Failed to update Return lead: Status ${response.statusCode}';
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
    } catch (e, s) {
      print('ApiService: Error updating Return lead: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateReturnLead failed',
      );
      rethrow;
    }
  }

  /// Get reports (edited leads) from API
  Future<Map<String, dynamic>> getReports({
    String? leadType,
    String? editedBy,
    String? dateFrom,
    String? dateTo,
    String? createdAtFrom,
    String? createdAtTo,
    String? editedAtFrom,
    String? editedAtTo,
    int? page,
    int? limit,
  }) async {
    final url = Uri.parse(
      ApiConfig.getReports(
        leadType: leadType,
        editedBy: editedBy,
        dateFrom: dateFrom,
        dateTo: dateTo,
        createdAtFrom: createdAtFrom,
        createdAtTo: createdAtTo,
        editedAtFrom: editedAtFrom,
        editedAtTo: editedAtTo,
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
    } catch (e, s) {
      print('ApiService: Error fetching reports: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getReports failed',
      );
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
    } catch (e, s) {
      print('ApiService: Error fetching report by ID: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getReportById failed',
      );
      rethrow;
    }
  }

  /// Get call summary/dashboard statistics from API
  Future<Map<String, dynamic>> getCallSummary({
    String? store,
    String? date,
  }) async {
    final url = Uri.parse(ApiConfig.getCallSummary(store: store, date: date));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      print('ApiService: Fetching call summary');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Call summary response status: ${response.statusCode}');
      print('ApiService: Call summary response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        // Handle both Map and List responses
        if (decodedResponse is Map<String, dynamic>) {
          return decodedResponse;
        } else {
          throw Exception('Unexpected response format from server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load call summary: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print('ApiService: Error fetching call summary: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getCallSummary failed',
      );
      rethrow;
    }
  }

  /// Get a single follow-up lead by ID
  /// Matches backend GET /api/pages/follow-ups/:id (plural "follow-ups")
  Future<Map<String, dynamic>> getFollowUp(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/pages/follow-ups/$id');
    print('ApiService: GET Follow-up URL => $url');

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      print('ApiService: Fetching follow-up lead by ID: $id');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Follow-up response status: ${response.statusCode}');
      print('ApiService: Follow-up response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'data': decodedResponse};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access denied: User doesn\'t have permission to access this follow-up lead.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Follow-up lead not found.');
      } else {
        throw Exception(
          'Failed to load follow-up lead: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print('ApiService: Error fetching follow-up lead: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getFollowUp failed',
      );
      rethrow;
    }
  }

  /// Create or update a follow-up lead
  /// Matches backend POST /api/pages/follow-up/:id
  /// Updates a follow-up lead with new call status, remarks, and call date
  /// Endpoint: POST /api/pages/follow-ups/:id (plural "follow-ups")
  /// Updates a follow-up lead with call status, lead status, remarks, call duration, and follow-up date
  /// According to API docs: call_status and lead_status are REQUIRED
  /// Backend expects: call_status, lead_status, call_duration (number in seconds), remarks (optional string)
  Future<Map<String, dynamic>> postFollowUp({
    required String id,
    required String callStatus,
    required String leadStatus, // REQUIRED according to API docs
    String? remarks,
    int? callDuration, // Call duration in seconds (number)
    DateTime? callDate, // Deprecated - kept for backward compatibility
    DateTime? followUpDate,
    required bool clearFollowUpDate,
    String? subCategory,
    String? closingAction,
    int? rating,
    String? leadType,
    DateTime? functionDate,
    bool? followUpFlag,
    bool? markAsComplaint,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/pages/follow-ups/$id');

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body with REQUIRED fields (call_status and lead_status)
      final requestBody = <String, dynamic>{
        'call_status': callStatus,
        'lead_status': leadStatus,
      };

      // Add call_duration if provided (backend expects number in seconds)
      // IMPORTANT: Include duration even if 0, as 0 is a valid duration for unanswered calls
      // Backend needs duration 0 to create report entries
      if (callDuration != null) {
        requestBody['call_duration'] = callDuration;
      }

      // Add optional fields if provided
      // Only include remarks if user provided input (not empty string)
      // Backend requires remarks to be a string, so omit the field entirely if null
      if (remarks != null && remarks.trim().isNotEmpty) {
        requestBody['remarks'] = remarks.trim();
      }

      // Add sub_category if provided
      if (subCategory != null && subCategory.trim().isNotEmpty) {
        requestBody['sub_category'] = subCategory.trim();
      }

      // Add closing_action if provided
      if (closingAction != null && closingAction.trim().isNotEmpty) {
        requestBody['closing_action'] = closingAction.trim();
      }

      // Add rating if provided (1-5 for return leads)
      if (rating != null && rating > 0) {
        requestBody['rating'] = rating;
      }

      // Add lead_type if provided
      if (leadType != null && leadType.trim().isNotEmpty) {
        requestBody['lead_type'] = leadType.trim();
      }

      // Add function_date if provided
      if (functionDate != null) {
        requestBody['function_date'] = functionDate.toIso8601String();
      }

      // Handle follow-up flag and date
      // CRITICAL: follow_up_flag and follow_up_date work together
      // If follow_up_flag=true, follow_up_date is REQUIRED
      if (followUpFlag != null) {
        requestBody['follow_up_flag'] = followUpFlag;
        if (followUpFlag && followUpDate != null) {
          requestBody['follow_up_date'] = followUpDate.toIso8601String();
        }
      } else if (followUpDate != null && !clearFollowUpDate) {
        // If followUpDate is provided without explicit flag, set flag to true
        requestBody['follow_up_flag'] = true;
        requestBody['follow_up_date'] = followUpDate.toIso8601String();
      }

      // Handle mark_as_complaint flag
      // CRITICAL: Routing logic:
      // - If mark_as_complaint=true → Move to Complaints (Priority 1)
      // - Else if follow_up_flag=true → Stay in Follow-Ups
      // - Else → Move to Reports (default)
      if (markAsComplaint != null) {
        requestBody['mark_as_complaint'] = markAsComplaint;
      }

      // Note: call_date is deprecated - backend expects call_duration instead
      // Keeping callDate for backward compatibility but not sending it

      final requestBodyJson = json.encode(requestBody);

      print('═══════════════════════════════════════════════════════════');
      print('ApiService: FOLLOW-UP LEAD POST REQUEST');
      print('═══════════════════════════════════════════════════════════');
      print('URL: $url');
      print('Headers: $headers');
      print('Request Body (JSON):');
      print(requestBodyJson);
      print('Request Body (Formatted):');
      requestBody.forEach((key, value) {
        print('  $key: $value');
      });
      print('═══════════════════════════════════════════════════════════');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print('═══════════════════════════════════════════════════════════');
      print('ApiService: FOLLOW-UP LEAD POST RESPONSE');
      print('═══════════════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('═══════════════════════════════════════════════════════════');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'success': true, 'data': decodedResponse};
      } else if (response.statusCode == 400) {
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
        throw Exception(
          'Access denied: User doesn\'t have permission to update this follow-up lead.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Follow-up lead not found.');
      } else {
        String errorMessage =
            'Failed to update follow-up lead: Status ${response.statusCode}';
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
    } catch (e, s) {
      print('ApiService: Error updating follow-up lead: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'postFollowUp failed',
      );
      rethrow;
    }
  }

  /// Move a lead to FollowUps collection by setting follow_up_date
  /// Matches backend POST https://telecallerappbackend.onrender.com/api/pages/leads/:id
  /// Works for all lead types (general, loss of sale, booking confirmation, return)
  Future<Map<String, dynamic>> moveLeadToFollowUp({
    required String id,
    required DateTime followUpDate,
    String? callStatus,
    String? leadStatus,
    String? remarks,
  }) async {
    final url = Uri.parse(
      'https://telecallerappbackend.onrender.com/api/pages/leads/$id',
    );

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Prepare request body with follow_up_date to trigger move to FollowUps
      final requestBody = <String, dynamic>{
        'follow_up_date': followUpDate.toIso8601String(),
      };

      // Add optional fields if provided
      if (callStatus != null && callStatus.isNotEmpty) {
        requestBody['call_status'] = callStatus;
      }
      if (leadStatus != null && leadStatus.isNotEmpty) {
        requestBody['lead_status'] = leadStatus;
      }
      if (remarks != null && remarks.isNotEmpty) {
        requestBody['remarks'] = remarks;
      }

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Moving lead to follow-up');
      print('ApiService: POST URL: $url');
      print('ApiService: POST BODY SENT: $requestBodyJson');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      print(
        'ApiService: Move to follow-up response status: ${response.statusCode}',
      );
      print('ApiService: Move to follow-up response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'success': true, 'data': decodedResponse};
      } else if (response.statusCode == 400) {
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
        String errorMessage =
            'Failed to move lead to follow-up: Status ${response.statusCode}';
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
    } catch (e, s) {
      print('ApiService: Error moving lead to follow-up: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'moveLeadToFollowUp failed',
      );
      rethrow;
    }
  }

  /// Get all follow-up leads from backend
  /// Matches backend GET /api/pages/follow-ups
  Future<Map<String, dynamic>> getFollowUpLeads({
    String? store,
    int? limit,
  }) async {
    final url = Uri.parse(ApiConfig.getFollowUps(store: store, limit: limit));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      print('ApiService: Fetching follow-up leads');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print(
        'ApiService: Follow-up leads response status: ${response.statusCode}',
      );
      print('ApiService: Follow-up leads response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Normalize response to { "data": [...] }
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('leads')) {
            return {'data': decoded['leads']};
          }
          if (decoded.containsKey('data')) {
            return {'data': decoded['data']};
          }
          return decoded;
        } else if (decoded is List) {
          return {'data': decoded};
        } else {
          throw Exception('Unexpected response format for follow-up leads');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load follow-up leads: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print('ApiService: Error fetching follow-up leads: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getFollowUpLeads failed',
      );
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

  /// Handle 401 Unauthorized response - attempt to refresh token
  Future<bool> _handleUnauthorized() async {
    try {
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        // No refresh token available, need to login again
        await AuthService.clearAuth();
        return false;
      }

      // Attempt to refresh the token
      final url = Uri.parse(ApiConfig.refreshToken());
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Save new token
        if (responseData.containsKey('token')) {
          await AuthService.saveToken(responseData['token'] as String);
          print('ApiService: Token refreshed successfully');
          return true;
        }
      } else if (response.statusCode == 401) {
        // Refresh token is also invalid, clear auth and require login
        await AuthService.clearAuth();
        return false;
      }
    } catch (e, s) {
      print('ApiService: Error refreshing token: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: '_refreshToken failed',
      );
    }

    return false;
  }

  /// Get all starred calls from backend
  /// Matches backend GET /api/pages/starred-calls
  Future<Map<String, dynamic>> getStarredCalls({
    String? store,
    int? page,
    int? limit,
  }) async {
    final url = Uri.parse(
      ApiConfig.getStarredCalls(store: store, page: page, limit: limit),
    );

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      print('ApiService: Fetching starred calls');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print(
        'ApiService: Starred calls response status: ${response.statusCode}',
      );
      print('ApiService: Starred calls response body: ${response.body}');

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
          'Failed to load starred calls: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print('ApiService: Error fetching starred calls: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getStarredCalls failed',
      );
      rethrow;
    }
  }

  /// Get a single starred call by ID
  /// Matches backend GET /api/pages/starred-calls/:id
  Future<Map<String, dynamic>> getStarredCallById(String id) async {
    final url = Uri.parse(ApiConfig.getStarredCallById(id));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      print('ApiService: Fetching starred call by ID: $id');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Starred call response status: ${response.statusCode}');
      print('ApiService: Starred call response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'data': decodedResponse};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Starred call not found');
      } else {
        throw Exception(
          'Failed to load starred call: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print('ApiService: Error fetching starred call: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getStarredCallById failed',
      );
      rethrow;
    }
  }

  /// Get complaints from API
  /// Endpoint: GET /api/pages/complaints
  Future<Map<String, dynamic>> getComplaints({
    String? store,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      // Build URL with query parameters
      final queryParams = <String, String>{};
      if (store != null && store.isNotEmpty) queryParams['store'] = store;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/pages/complaints',
      ).replace(queryParameters: queryParams);

      print('ApiService: Fetching complaints');
      print('ApiService: URL => $uri');

      final response = await http.get(uri, headers: headers);

      print('ApiService: Complaints response status: ${response.statusCode}');
      print('ApiService: Complaints response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        // Handle both Map and List responses
        if (decodedResponse is Map<String, dynamic>) {
          return decodedResponse;
        } else if (decodedResponse is List) {
          return {'complaints': decodedResponse, 'pagination': {}};
        } else {
          throw Exception('Unexpected response format from server');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load complaints: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print('ApiService: Error fetching complaints: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getComplaints failed',
      );
      rethrow;
    }
  }

  /// Get single complaint by ID
  /// Endpoint: GET /api/pages/complaints/{id}
  Future<Map<String, dynamic>> getComplaintById(String id) async {
    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/pages/complaints/$id');

      print('ApiService: Fetching complaint by ID: $id');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Complaint response status: ${response.statusCode}');
      print('ApiService: Complaint response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic>
            ? decodedResponse
            : {'data': decodedResponse};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Complaint not found');
      } else {
        throw Exception(
          'Failed to load complaint: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print('ApiService: Error fetching complaint: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getComplaintById failed',
      );
      rethrow;
    }
  }
}
