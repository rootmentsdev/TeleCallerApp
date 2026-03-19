import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:telecaller_app/services/auth_service.dart';
import 'package:telecaller_app/utils/api_config.dart';

class ApiService {
  static Function? onSessionExpired;

  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await AuthService.getToken();
    print(
      'ApiService: _getAuthHeaders - token=${token != null ? token.substring(0, 20) + '...' : 'NULL'}',
    );

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, String>> getAuthHeaders() async {
    return await _getAuthHeaders();
  }

  // Login
  Future<Map<String, dynamic>> loginUser({
    required String empId,
    required String password,
  }) async {
    final url = Uri.parse(ApiConfig.login());

    try {
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

        if (responseData.containsKey('token')) {
          await AuthService.saveToken(responseData['token'] as String);
          print('ApiService: Token saved successfully');
        }

        if (responseData.containsKey('refreshToken')) {
          await AuthService.saveRefreshToken(
            responseData['refreshToken'] as String,
          );
        }

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
          if (user.containsKey('name')) {
            await AuthService.saveUserName(user['name'].toString());
            print('ApiService: User name saved: ${user['name']}');
          }
        }

        await AuthService.saveEmpId(empId);
        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception("Invalid EMP ID or Password");
      } else {
        throw Exception('Login failed: Status ${response.statusCode}');
      }
    } catch (e, s) {
      print('ApiService: Login error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'loginUser failed',
      );
      rethrow;
    }
  }

  // Get Return Leads
  Future<Map<String, dynamic>> getReturnLeads({
    String? store,
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
  }) async {
    final url = Uri.parse(
      ApiConfig.getReturnLeads(
        store: store,
        fromDate: fromDate,
        toDate: toDate,
        page: page,
        limit: limit,
      ),
    );

    try {
      final headers = await _getAuthHeaders();

      print('ApiService: Fetching Return leads from: $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Return response status: ${response.statusCode}');
      print('ApiService: Return response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data')) {
            return {'data': decoded['data']};
          }
          if (decoded.containsKey('leads')) {
            return {'data': decoded['leads']};
          }
          return decoded;
        } else if (decoded is List) {
          return {'data': decoded};
        }
        return {'data': []};
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

  // Get Return Lead Details
  Future<Map<String, dynamic>> getReturn(String id) async {
    final url = Uri.parse(ApiConfig.updateReturnLead(id));

    try {
      final headers = await _getAuthHeaders();

      print('ApiService: getReturn - URL: $url');
      print('ApiService: getReturn - Headers: $headers');

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await http.get(url, headers: headers);

      print('ApiService: getReturn - Response status: ${response.statusCode}');
      print('ApiService: getReturn - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final normalized = <String, dynamic>{};
          decoded.forEach((key, value) {
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

  // Update Return Lead
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
    String? subCategory,
    String? itemCategory,
    DateTime? functionDate,
    String? leadType,
    bool? markAsComplaint,
    String? numberOfFunctions,
    String? numberOfAttires,
    String? competitor,
    String? service,
    String? refundStatus,
  }) async {
    final url = Uri.parse(ApiConfig.updateReturnLead(id));

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

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
      if (remarks != null && remarks.trim().isNotEmpty) {
        requestBody['remarks'] = remarks.trim();
      }
      if (callDuration != null) {
        requestBody['call_duration'] = callDuration;
      }
      if (followUpFlag != null) {
        requestBody['follow_up_flag'] = followUpFlag;
        if (followUpFlag && followUpDate != null) {
          requestBody['follow_up_date'] = followUpDate.toIso8601String();
        }
      } else if (followUpDate != null) {
        requestBody['follow_up_flag'] = true;
        requestBody['follow_up_date'] = followUpDate.toIso8601String();
      }

      final requestBodyJson = json.encode(requestBody);

      print('ApiService: Updating Return lead');
      print('ApiService: POST URL => $url');
      print('ApiService: Request body => $requestBodyJson');

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
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to update Return lead: Status ${response.statusCode}',
        );
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

  // Get Follow-up Leads
  Future<Map<String, dynamic>> getFollowUpLeads({
    String? store,
    int? limit,
  }) async {
    final url = Uri.parse(
      ApiConfig.getFollowupLeads(store: store, limit: limit),
    );

    try {
      final headers = await _getAuthHeaders();

      print('ApiService: Fetching follow-up leads');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print(
        'ApiService: Follow-up leads response status: ${response.statusCode}',
      );
      print('ApiService: Follow-up leads response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data')) {
            return {'data': decoded['data']};
          }
          if (decoded.containsKey('leads')) {
            return {'data': decoded['leads']};
          }
          return decoded;
        } else if (decoded is List) {
          return {'data': decoded};
        }
        return {'data': []};
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

  // Get Reports
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

  // Get Complaints
  Future<Map<String, dynamic>> getComplaints({
    String? store,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
  }) async {
    final url = Uri.parse(
      ApiConfig.getComplaintLeads(
        store: store,
        fromDate: dateFrom,
        toDate: dateTo,
        page: page,
        limit: limit,
      ),
    );

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      print('ApiService: Fetching complaints');
      print('ApiService: URL => $url');

      final response = await http.get(url, headers: headers);

      print('ApiService: Complaints response status: ${response.statusCode}');
      print('ApiService: Complaints response body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic> ? decodedResponse : {};
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

  // Get Complaint by ID
  Future<Map<String, dynamic>> getComplaintById(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/leads/complaints/$id');

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic> ? decodedResponse : {};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load complaint: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      print('ApiService: Error fetching complaint by ID: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getComplaintById failed',
      );
      rethrow;
    }
  }

  // Create Lead
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
    String? callStatus,
  }) async {
    final url = Uri.parse(ApiConfig.addLead());

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      String normalizedLeadType = leadType.toLowerCase();
      if (normalizedLeadType == 'booking') {
        normalizedLeadType = 'booked';
      }

      final requestBody = <String, dynamic>{
        'name': leadName,
        'phone': phoneNumber,
        'store': store,
        'leadtype': normalizedLeadType,
        'callStatus': _normalizeCallStatus(callStatus ?? 'Not Called'),
        'subCategory': subCategory,
        'itemCategory': itemCategory,
        'closingAction': closingAction,
        'closingReason': remarks,
        'remarks': remarks,
        'functionDate': functionDate,
        'markasComplaint': markAsComplaint,
        'markasFollowup': followUpFlag,
        'followupDate':
            followUpFlag && followUpDate != null ? followUpDate : null,
        'callDuration': callDuration?.toString() ?? '0',
      };

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
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to create lead: Status ${response.statusCode}');
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

  /// Maps display call status labels to backend enum values
  String _normalizeCallStatus(String status) {
    switch (status.toLowerCase()) {
      case 'connected':
        return 'connected';
      case 'not connected':
        return 'not connected';
      case 'interested':
        return 'interested';
      case 'not interested':
        return 'not interested';
      case 'forwarded':
        return 'forwarded';
      case 'not called':
      default:
        return 'not called';
    }
  }

  // Update Lead
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
    int? callDuration,
    bool isStarred = false,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/leads/$id');

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      final requestBody = <String, dynamic>{
        'customer_name': leadName,
        'phone_number': phoneNumber,
        'store_location': store,
        'source': source,
        'call_status': callStatus,
        'lead_status': leadStatus,
      };

      if (remarks != null && remarks.trim().isNotEmpty) {
        requestBody['remarks'] = remarks.trim();
      }

      if (followUpFlag) {
        requestBody['follow_up_flag'] = followUpFlag;
        if (followUpDate != null && followUpDate.isNotEmpty) {
          requestBody['follow_up_date'] = followUpDate;
        }
      }

      if (functionDate != null && functionDate.isNotEmpty) {
        requestBody['function_date'] = functionDate;
      }

      if (callDuration != null) {
        requestBody['call_duration'] = callDuration;
      }

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
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to update lead: Status ${response.statusCode}');
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

  // Post Follow-up
  Future<Map<String, dynamic>> postFollowUp({
    required String id,
    String? callStatus,
    String? leadStatus,
    String? remarks,
    bool? followUpFlag,
    DateTime? followUpDate,
    int? callDuration,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/leads/$id');

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      final requestBody = <String, dynamic>{
        'call_status': callStatus ?? 'Not Called',
        'lead_status': leadStatus ?? 'No Status',
      };

      if (remarks != null && remarks.trim().isNotEmpty) {
        requestBody['remarks'] = remarks.trim();
      }

      if (followUpFlag != null) {
        requestBody['follow_up_flag'] = followUpFlag;
        if (followUpFlag && followUpDate != null) {
          requestBody['follow_up_date'] = followUpDate.toIso8601String();
        }
      }

      if (callDuration != null) {
        requestBody['call_duration'] = callDuration;
      }

      final requestBodyJson = json.encode(requestBody);

      final response = await http.post(
        url,
        headers: headers,
        body: requestBodyJson,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic> ? decodedResponse : {};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to post follow-up: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'postFollowUp failed',
      );
      rethrow;
    }
  }

  // Get All Leads
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
      ApiConfig.getCompletedLeads(
        store: store,
        fromDate: dateFrom,
        toDate: dateTo,
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

  // Get Call Summary
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

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse is Map<String, dynamic> ? decodedResponse : {};
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

  // Get Starred Calls
  Future<Map<String, dynamic>> getStarredCalls({
    String? store,
    int? limit,
  }) async {
    final url = Uri.parse(
      ApiConfig.getStarredCalls(store: store, limit: limit),
    );

    try {
      final headers = await _getAuthHeaders();

      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is Map<String, dynamic>) {
          return decodedResponse;
        } else if (decodedResponse is List) {
          return {'data': decodedResponse};
        }
        return {'data': []};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load starred calls: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getStarredCalls failed',
      );
      rethrow;
    }
  }

  // ===== Booking Confirmation =====

  Future<Map<String, dynamic>> getBookingConfirmationLeads({
    String? store,
    String? fromDate,
    String? toDate,
    int? limit,
  }) async {
    final url = Uri.parse(
      ApiConfig.getBookingConfirmationLeads(
        store: store,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
      ),
    );
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List) return {'data': decoded};
        return {'data': []};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load booking confirmation leads: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getBookingConfirmationLeads failed',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBookingConfirmationById(String id) async {
    final url = Uri.parse(ApiConfig.updateBookingConfirmationLead(id));
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to load booking confirmation: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getBookingConfirmationById failed',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateBookingConfirmation({
    required String id,
    String? service,
    String? callDuration,
    String? billReceived,
    bool? amountMismatch,
    String? remarks,
    bool? markasComplaint,
    bool? markasFollowup,
    DateTime? followupDate,
  }) async {
    final url = Uri.parse(ApiConfig.updateBookingConfirmationLead(id));
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{};
      if (service != null) body['service'] = service;
      if (callDuration != null) body['callDuration'] = callDuration;
      if (billReceived != null) body['billReceived'] = billReceived;
      if (amountMismatch != null) body['amountMismatch'] = amountMismatch;
      if (remarks != null) body['remarks'] = remarks;
      if (markasComplaint != null) body['markasComplaint'] = markasComplaint;
      if (markasFollowup != null) body['markasFollowup'] = markasFollowup;
      if (followupDate != null) {
        body['followupDate'] = followupDate.toUtc().toIso8601String();
      }
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {};
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception(
          'Failed to update booking confirmation: Status ${response.statusCode}',
        );
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'updateBookingConfirmation failed',
      );
      rethrow;
    }
  }

  // Get Stores
  Future<Map<String, dynamic>> getStores() async {
    final url = Uri.parse(ApiConfig.getStores());

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      print('ApiService: Get stores response status: ${response.statusCode}');
      print('ApiService: Get stores response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        onSessionExpired?.call();
        throw Exception('Session expired');
      } else {
        throw Exception('Failed to load stores: Status ${response.statusCode}');
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'getStores failed',
      );
      rethrow;
    }
  }

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
}
