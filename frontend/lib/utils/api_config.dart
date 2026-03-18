class ApiConfig {
  // Base URL
  static const String baseUrl = "https://rootstele.onrender.com";

  // API endpoints paths
  static const String leadsEndpoint = "$baseUrl/api/leads";
  static const String authEndpoint = "$baseUrl/api/auth";
  static const String storesEndpoint = "$baseUrl/api/stores";

  // Lead types
  static const String lossOfSale = "lossOfSale";
  static const String walkIn = "general";
  static const String bookingConfirmation = "bookingConfirmation";
  static const String returnLead = "return";

  // Sources
  static const String sourceWalkIn = "Walk-in";

  // ===== Authentication =====
  static String login() {
    return "$authEndpoint/telecaller-login";
  }

  static String refreshToken() {
    return "$authEndpoint/refresh-token";
  }

  // ===== Return Leads =====
  static String getReturnLeads({
    String? store,
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
  }) {
    String url = "$leadsEndpoint/returns";
    List<String> queryParams = [];

    if (store != null && store.isNotEmpty) {
      queryParams.add("store=${Uri.encodeComponent(store)}");
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams.add("fromDate=${Uri.encodeComponent(fromDate)}");
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams.add("toDate=${Uri.encodeComponent(toDate)}");
    }
    if (page != null) {
      queryParams.add("page=$page");
    }
    if (limit != null) {
      queryParams.add("limit=$limit");
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }
    return url;
  }

  static String updateReturnLead(String id) {
    return "$leadsEndpoint/returns/$id";
  }

  // ===== Booking Confirmation Leads =====
  static String getBookingConfirmationLeads({
    String? store,
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
  }) {
    String url = "$leadsEndpoint/booking-confirmation";
    List<String> queryParams = [];

    if (store != null && store.isNotEmpty) {
      queryParams.add("store=${Uri.encodeComponent(store)}");
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams.add("fromDate=${Uri.encodeComponent(fromDate)}");
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams.add("toDate=${Uri.encodeComponent(toDate)}");
    }
    if (page != null) {
      queryParams.add("page=$page");
    }
    if (limit != null) {
      queryParams.add("limit=$limit");
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }
    return url;
  }

  static String updateBookingConfirmationLead(String id) {
    return "$leadsEndpoint/booking-confirmation/$id";
  }

  // ===== Followup Leads =====
  static String getFollowupLeads({
    String? store,
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
  }) {
    String url = "$leadsEndpoint/followups";
    List<String> queryParams = [];

    if (store != null && store.isNotEmpty) {
      queryParams.add("store=${Uri.encodeComponent(store)}");
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams.add("fromDate=${Uri.encodeComponent(fromDate)}");
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams.add("toDate=${Uri.encodeComponent(toDate)}");
    }
    if (page != null) {
      queryParams.add("page=$page");
    }
    if (limit != null) {
      queryParams.add("limit=$limit");
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }
    return url;
  }

  static String updateFollowupLead(String id) {
    return "$leadsEndpoint/followups/$id";
  }

  // ===== Complaint Leads =====
  static String getComplaintLeads({
    String? store,
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
  }) {
    String url = "$leadsEndpoint/complaints";
    List<String> queryParams = [];

    if (store != null && store.isNotEmpty) {
      queryParams.add("store=${Uri.encodeComponent(store)}");
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams.add("fromDate=${Uri.encodeComponent(fromDate)}");
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams.add("toDate=${Uri.encodeComponent(toDate)}");
    }
    if (page != null) {
      queryParams.add("page=$page");
    }
    if (limit != null) {
      queryParams.add("limit=$limit");
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }
    return url;
  }

  // ===== Completed Leads (Reports) =====
  static String getCompletedLeads({
    String? store,
    String? fromDate,
    String? toDate,
    String? leadtype,
    int? page,
    int? limit,
  }) {
    String url = "$leadsEndpoint/completed";
    List<String> queryParams = [];

    if (store != null && store.isNotEmpty) {
      queryParams.add("store=${Uri.encodeComponent(store)}");
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams.add("fromDate=${Uri.encodeComponent(fromDate)}");
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams.add("toDate=${Uri.encodeComponent(toDate)}");
    }
    if (leadtype != null && leadtype.isNotEmpty) {
      queryParams.add("leadtype=${Uri.encodeComponent(leadtype)}");
    }
    if (page != null) {
      queryParams.add("page=$page");
    }
    if (limit != null) {
      queryParams.add("limit=$limit");
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }
    return url;
  }

  // ===== Stores =====
  static String getStores() {
    return storesEndpoint;
  }

  // ===== Legacy Methods (for backward compatibility) =====
  static String addLead() {
    return "$leadsEndpoint/add-lead";
  }

  static String walkInLeads() {
    return "$leadsEndpoint/walk-in";
  }

  static String getReports({
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
  }) {
    return getCompletedLeads(
      fromDate: dateFrom ?? createdAtFrom,
      toDate: dateTo ?? createdAtTo,
      page: page,
      limit: limit,
    );
  }

  static String getReportById(String id) {
    return "$leadsEndpoint/$id";
  }

  static String getCallSummary({String? store, String? date}) {
    String url = "$leadsEndpoint/call-summary";
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

  static String getFollowUps({String? store, int? page, int? limit}) {
    return getFollowupLeads(store: store, page: page, limit: limit);
  }

  static String getStarredCalls({String? store, int? page, int? limit}) {
    String url = "$leadsEndpoint/starred-calls";
    List<String> queryParams = [];

    if (store != null && store.isNotEmpty) {
      queryParams.add("store=${Uri.encodeComponent(store)}");
    }
    if (page != null) {
      queryParams.add("page=$page");
    }
    if (limit != null) {
      queryParams.add("limit=$limit");
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }
    return url;
  }

  static String getStarredCallById(String id) {
    return "$leadsEndpoint/starred-calls/$id";
  }
}
