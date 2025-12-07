import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:telecaller_app/services/auth_service.dart';
import 'package:telecaller_app/utils/api_config.dart';

class ApiService {
  // -----------------------------------------------------------
  // 🔐 AUTH HEADERS
  // -----------------------------------------------------------
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getToken();

    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  // -----------------------------------------------------------
  // 🧰 COMMON HELPERS
  // -----------------------------------------------------------

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List) return {"data": decoded};
      return {"data": decoded};
    } catch (_) {
      return {"error": "Invalid JSON"};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = _decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final msg =
        decoded["message"] ??
        decoded["error"] ??
        decoded["msg"] ??
        "Something went wrong (${response.statusCode})";

    throw Exception(msg);
  }

  Future<Map<String, dynamic>> _get(String url) async {
    final headers = await _getAuthHeaders();
    print("GET URL: $url");

    final response = await http.get(Uri.parse(url), headers: headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getAuthHeaders();
    print("POST URL: $url");
    print("POST BODY: $body");

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return _handleResponse(response);
  }

  // -----------------------------------------------------------
  // 👤 LOGIN
  // -----------------------------------------------------------
  Future<Map<String, dynamic>> loginUser({
    required String empId,
    required String password,
  }) async {
    final url = ApiConfig.login();
    final headers = {"Content-Type": "application/json"};

    final body = {"employeeId": empId, "password": password};

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    final data = _handleResponse(response);

    // Token saving
    if (data.containsKey("token")) {
      await AuthService.saveToken(data["token"]);
    }

    if (data.containsKey("refreshToken")) {
      await AuthService.saveRefreshToken(data["refreshToken"]);
    }

    if (data.containsKey("user")) {
      await AuthService.saveUserId(data["user"]["_id"]);
    }

    await AuthService.saveEmpId(empId);

    return data;
  }

  // -----------------------------------------------------------
  // 📌 GET LEADS
  // -----------------------------------------------------------

  Future<Map<String, dynamic>> getLossOfSaleLeads({
    String? store,
    String? enquiryFrom,
    String? enquiryTo,
    String? functionFrom,
    String? functionTo,
    String? visitFrom,
    String? visitTo,
  }) {
    return _get(
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
  }

  Future<Map<String, dynamic>> getWalkInLeads() {
    return _get(ApiConfig.walkInLeads());
  }

  Future<Map<String, dynamic>> getBookingConfirmationLeads() {
    return _get(ApiConfig.bookingConfirmationLeads());
  }

  Future<Map<String, dynamic>> getRentOutLeads() {
    return _get(ApiConfig.rentOutLeads());
  }

  // -----------------------------------------------------------
  // 📌 ADD LEAD
  // -----------------------------------------------------------
  Future<Map<String, dynamic>> addLead({
    required String customerName,
    required String phoneNumber,
    String? brand,
    String? storeLocation,
    String? leadStatus,
    String? callStatus,
    DateTime? followUpDate,
  }) {
    final body = {
      "customer_name": customerName,
      "phone_number": phoneNumber,
      if (brand != null) "brand": brand,
      if (storeLocation != null) "store_location": storeLocation,
      if (leadStatus != null) "lead_status": leadStatus,
      if (callStatus != null) "call_status": callStatus,
      if (followUpDate != null)
        "follow_up_date": followUpDate.toIso8601String(),
    };

    return _post(ApiConfig.addLead(), body);
  }

  // -----------------------------------------------------------
  // ✏️ UPDATE: LOSS OF SALE
  // -----------------------------------------------------------
  Future<Map<String, dynamic>> updateLossOfSaleLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    String? followUpDate,
    String? reasonCollectedFromStore,
    String? remarks,
  }) {
    final body = {
      if (callStatus != null) "call_status": callStatus,
      if (leadStatus != null) "lead_status": leadStatus,
      if (followUpDate != null) "follow_up_date": followUpDate,
      if (reasonCollectedFromStore != null)
        "reason_collected_from_store": reasonCollectedFromStore,
      if (remarks != null) "remarks": remarks,
    };

    return _post(ApiConfig.updateLossOfSale(id), body);
  }

  // -----------------------------------------------------------
  // ✏️ UPDATE: RENT OUT
  // -----------------------------------------------------------
  Future<Map<String, dynamic>> updateRentOutLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    int? rating,
    String? remarks,
  }) {
    final body = {
      if (callStatus != null) "call_status": callStatus,
      if (leadStatus != null) "lead_status": leadStatus,
      if (followUpFlag != null) "follow_up_flag": followUpFlag,
      if (callDate != null) "call_date": callDate.toIso8601String(),
      if (rating != null) "rating": rating,
      if (remarks != null) "remarks": remarks,
    };

    return _post(ApiConfig.updateRentOut(id), body);
  }

  // -----------------------------------------------------------
  // ✏️ UPDATE: BOOKING CONFIRMATION
  // -----------------------------------------------------------
  Future<Map<String, dynamic>> updateBookingConfirmationLead({
    required String id,
    String? callStatus,
    String? leadStatus,
    bool? followUpFlag,
    DateTime? callDate,
    String? remarks,
  }) {
    final body = {
      if (callStatus != null) "call_status": callStatus,
      if (leadStatus != null) "lead_status": leadStatus,
      if (followUpFlag != null) "follow_up_flag": followUpFlag,
      if (callDate != null) "call_date": callDate.toIso8601String(),
      if (remarks != null) "remarks": remarks,
    };

    return _post(ApiConfig.updateBookingConfirmation(id), body);
  }
}
