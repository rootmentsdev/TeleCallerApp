class ApiConfig {
  // Base URL
  static const String baseUrl = "https://telecallerappbackend.onrender.com";

  // API endpoints paths
  static const String leadsEndpoint = "$baseUrl/api/pages/leads";
  static const String authEndpoint = "$baseUrl/api/auth";
  static const String pagesEndpoint = "$baseUrl/api/pages";
  static const String reportsEndpoint = "$baseUrl/api/reports";
  // Follow-ups endpoint (fetch follow-up leads)
  static const String followUpsEndpoint = "$baseUrl/api/pages/follow-ups";

  // Lead types
  static const String lossOfSale = "lossOfSale";
  static const String walkIn = "general";
  static const String bookingConfirmation = "bookingConfirmation";
  static const String rentOut = "return";

  // Sources
  static const String sourceWalkIn = "Walk-in";

  // API Endpoints (with optional query parameters)

  static String lossOfSaleLeads({
    String? store,
    String? enquiryFrom,
    String? enquiryTo,
    String? functionFrom,
    String? functionTo,
    String? visitFrom,
    String? visitTo,
  }) {
    String url = "$leadsEndpoint?leadType=$lossOfSale";

    if (store != null && store.isNotEmpty) {
      // Extract just the location from "Brand - Location" format
      final location = store.contains(' - ') ? store.split(' - ').last : store;
      url += "&store=${Uri.encodeComponent(location)}";
    }

    if (enquiryFrom != null && enquiryTo != null) {
      url += "&enquiryDateFrom=$enquiryFrom&enquiryDateTo=$enquiryTo";
    }

    if (functionFrom != null && functionTo != null) {
      url += "&functionDateFrom=$functionFrom&functionDateTo=$functionTo";
    }

    if (visitFrom != null && visitTo != null) {
      url += "&visitDateFrom=$visitFrom&visitDateTo=$visitTo";
    }

    return url;
  }

  static String walkInLeads() {
    return "$leadsEndpoint?leadType=$walkIn&source=$sourceWalkIn";
  }

  static String bookingConfirmationLeads({
    String? store,
    int? page,
    int? limit,
  }) {
    String url = "$leadsEndpoint?leadType=$bookingConfirmation";

    if (store != null && store.isNotEmpty) {
      // Extract just the location from "Brand - Location" format
      final location = store.contains(' - ') ? store.split(' - ').last : store;
      url += "&store=${Uri.encodeComponent(location)}";
    }

    // Add pagination parameters
    if (page != null) {
      url += "&page=$page";
    }
    if (limit != null) {
      url += "&limit=$limit";
    } else {
      // Default to high limit to get all records
      url += "&limit=1000";
    }

    return url;
  }

  static String rentOutLeads({String? store, int? page, int? limit}) {
    String url = "$leadsEndpoint?leadType=$rentOut";

    if (store != null && store.isNotEmpty) {
      // Extract just the location from "Brand - Location" format
      final location = store.contains(' - ') ? store.split(' - ').last : store;
      url += "&store=${Uri.encodeComponent(location)}";
    }

    // Add pagination parameters
    if (page != null) {
      url += "&page=$page";
    }
    if (limit != null) {
      url += "&limit=$limit";
    } else {
      // Default to high limit to get all records
      url += "&limit=1000";
    }

    return url;
  }

  /// Get all leads endpoint with pagination, store filter, and date filter support
  /// Format: /api/pages/leads?store=Suitor Guy - Edappal
  /// Or: /api/pages/leads?page=1&store=Suitor Guy - Edappal&createdAt=2025-12-04
  static String getAllLeads({
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
  }) {
    String url = "$leadsEndpoint";
    List<String> queryParams = [];

    // Add page parameter if provided
    if (page != null) {
      queryParams.add("page=$page");
    }

    // Add store filter if provided
    if (store != null && store.isNotEmpty) {
      queryParams.add("store=${Uri.encodeComponent(store)}");
    }

    // Add createdAt date filter (primary date filter)
    if (createdAt != null && createdAt.isNotEmpty) {
      queryParams.add("createdAt=${Uri.encodeComponent(createdAt)}");
    }

    // Add enquiry date filters
    if (enquiryDateFrom != null && enquiryDateFrom.isNotEmpty) {
      queryParams.add(
        "enquiryDateFrom=${Uri.encodeComponent(enquiryDateFrom)}",
      );
    }
    if (enquiryDateTo != null && enquiryDateTo.isNotEmpty) {
      queryParams.add("enquiryDateTo=${Uri.encodeComponent(enquiryDateTo)}");
    }

    // Add function date filters
    if (functionDateFrom != null && functionDateFrom.isNotEmpty) {
      queryParams.add(
        "functionDateFrom=${Uri.encodeComponent(functionDateFrom)}",
      );
    }
    if (functionDateTo != null && functionDateTo.isNotEmpty) {
      queryParams.add("functionDateTo=${Uri.encodeComponent(functionDateTo)}");
    }

    // Add visit date filters (for Loss of Sale)
    if (visitDateFrom != null && visitDateFrom.isNotEmpty) {
      queryParams.add("visitDateFrom=${Uri.encodeComponent(visitDateFrom)}");
    }
    if (visitDateTo != null && visitDateTo.isNotEmpty) {
      queryParams.add("visitDateTo=${Uri.encodeComponent(visitDateTo)}");
    }

    // Add generic date filters with dateField parameter
    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams.add("dateFrom=${Uri.encodeComponent(dateFrom)}");
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams.add("dateTo=${Uri.encodeComponent(dateTo)}");
    }
    if (dateField != null && dateField.isNotEmpty) {
      queryParams.add("dateField=${Uri.encodeComponent(dateField)}");
    }

    // Build URL with query parameters
    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }

    return url;
  }

  static String login() {
    return "$authEndpoint/login";
  }

  static String refreshToken() {
    return "$authEndpoint/refresh-token";
  }

  static String updateLossOfSale(String id) {
    return "$pagesEndpoint/loss-of-sale/$id";
  }

  static String addLead() {
    return "$pagesEndpoint/add-lead";
  }

  static String updateRentOut(String id) {
    return "$pagesEndpoint/rent-out/$id";
  }

  static String updateBookingConfirmation(String id) {
    return "$pagesEndpoint/booking-confirmation/$id";
  }

  static String getReturn(String id) {
    return "$pagesEndpoint/return/$id";
  }

  /// Reports API endpoint
  static String get reportsBaseUrl => reportsEndpoint;

  /// Get reports endpoint with filtering and pagination support
  static String getReports({
    String? leadType,
    String? editedBy,
    String? dateFrom,
    String? dateTo,
    int? page,
    int? limit,
  }) {
    String url = reportsBaseUrl;
    List<String> queryParams = [];

    if (leadType != null && leadType.isNotEmpty) {
      queryParams.add("leadType=${Uri.encodeComponent(leadType)}");
    }

    if (editedBy != null && editedBy.isNotEmpty) {
      queryParams.add("editedBy=${Uri.encodeComponent(editedBy)}");
    }

    if (dateFrom != null && dateFrom.isNotEmpty) {
      queryParams.add("dateFrom=${Uri.encodeComponent(dateFrom)}");
    }

    if (dateTo != null && dateTo.isNotEmpty) {
      queryParams.add("dateTo=${Uri.encodeComponent(dateTo)}");
    }

    // Add pagination parameters
    if (page != null) {
      queryParams.add("page=$page");
    } else {
      queryParams.add("page=1"); // Default to page 1
    }

    if (limit != null) {
      queryParams.add("limit=$limit");
    } else {
      queryParams.add("limit=50"); // Default to 50 items per page
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }

    return url;
  }

  /// Get a single report by ID
  static String getReportById(String id) {
    return "$reportsBaseUrl/$id";
  }

  /// Get call summary/dashboard statistics
  static String getCallSummary({String? store, String? date}) {
    String url = "$reportsEndpoint/call-summary";
    List<String> queryParams = [];

    if (date != null && date.isNotEmpty) {
      queryParams.add("date=${Uri.encodeComponent(date)}");
    }

    if (store != null && store.isNotEmpty) {
      queryParams.add("store=${Uri.encodeComponent(store)}");
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }

    return url;
  }

  /// Follow-ups endpoint helper
  static String getFollowUps({String? store, int? page, int? limit}) {
    String url = followUpsEndpoint;
    List<String> queryParams = [];

    if (store != null && store.isNotEmpty) {
      queryParams.add("store=${Uri.encodeComponent(store)}");
    }

    if (page != null) {
      queryParams.add("page=$page");
    }

    if (limit != null) {
      queryParams.add("limit=$limit");
    } else {
      queryParams.add("limit=1000");
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }

    return url;
  }
}
