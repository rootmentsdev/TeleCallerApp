class ApiConfig {
  // Base URL
  static const String baseUrl =
      "https://telecallerappbackend.onrender.com/api/pages/leads";

  // Lead types
  static const String lossOfSale = "lossOfSale";
  static const String walkIn = "general";
  static const String bookingConfirmation = "bookingConfirmation";
  static const String rentOut = "rentOutFeedback";

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
    String url = "$baseUrl?leadType=$lossOfSale";

    if (store != null && store.isNotEmpty) {
      url += "&store=${Uri.encodeComponent(store)}";
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
    return "$baseUrl?leadType=$walkIn&source=$sourceWalkIn";
  }

  static String bookingConfirmationLeads() {
    return "$baseUrl?leadType=$bookingConfirmation";
  }

  static String rentOutLeads() {
    return "$baseUrl?leadType=$rentOut";
  }

  static String login() {
    return "https://telecallerappbackend.onrender.com/api/auth/login";
  }
}
