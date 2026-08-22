class ReportModel {
  final String id;
  final String originalId;

  // Snapshots
  final Map<String, dynamic>? beforeSnapshot;
  final Map<String, dynamic>? afterSnapshot;
  final Map<String, dynamic>? leadSnapshot;
  final Map<String, dynamic>? listSnapshot;

  final String? leadType;
  final Map<String, dynamic>? editedBy;
  final List<String>? changedFields;
  final String? note;
  final int? callDuration; // Call duration from top-level API response

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? editedAt;

  ReportModel({
    required this.id,
    required this.originalId,
    this.beforeSnapshot,
    this.afterSnapshot,
    this.leadSnapshot,
    this.listSnapshot,
    this.leadType,
    this.editedBy,
    this.changedFields,
    this.note,
    this.callDuration,
    required this.createdAt,
    required this.updatedAt,
    this.editedAt,
  });

  // Parse date safely
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    try {
      return DateTime.parse(date.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  // -------- JSON to Model -------- //
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Extract leadType from multiple possible locations (including lowercase)
    final extractedLeadType =
        json['leadType']?.toString() ??
        json['lead_type']?.toString() ??
        json['leadtype']?.toString() ??
        (json['leadSnapshot'] != null
            ? (json['leadSnapshot']['leadType']?.toString() ??
                json['leadSnapshot']['lead_type']?.toString() ??
                json['leadSnapshot']['leadtype']?.toString())
            : null) ??
        '';

    print(
      'ReportModel: Extracted leadType: "$extractedLeadType" from JSON keys: ${json.keys.toList()}',
    );

    // Fallback leadSnapshot if backend did not send nested snapshot
    // Backend returns data at top level, so we create a snapshot from it
    final fallbackLeadSnapshot = {
      // Support both snake_case and camelCase
      "lead_name": json["name"] ?? json["lead_name"],
      "name": json["name"] ?? json["lead_name"],
      "phone_number": json["phone"] ?? json["phone_number"],
      "phone": json["phone"] ?? json["phone_number"],
      "store": json["store"],
      "location": json["store"],
      // JustDial-specific location fields
      "city": json["city"],
      "area": json["area"],
      "brancharea": json["brancharea"],
      "lead_type": json["leadType"] ?? json["lead_type"],
      "leadType": json["leadType"] ?? json["lead_type"],
      "call_status": json["callStatus"] ?? json["call_status"],
      "callStatus": json["callStatus"] ?? json["call_status"],
      "lead_status": json["leadStatus"] ?? json["lead_status"],
      "leadStatus": json["leadStatus"] ?? json["lead_status"],
      "remarks": json["remarks"] ?? json["note"],
      "reason": json["remarks"] ?? json["note"],
      "reason_collected_from_store": json["remarks"] ?? json["note"],
      "enquiry_date": json["enquiry_date"],
      "enquiryDate": json["enquiry_date"],
      "visit_date": json["visit_date"],
      "visitDate": json["visit_date"],
      "function_date": json["functionDate"] ?? json["function_date"],
      "functionDate": json["functionDate"] ?? json["function_date"],
      "return_date": json["return_date"],
      "returnDate": json["return_date"],
      "created_at": json["createdAt"] ?? json["created_at"],
      "createdAt": json["createdAt"] ?? json["created_at"],
      "call_duration": json["callDuration"] ?? json["call_duration"],
      "callDuration": json["callDuration"] ?? json["call_duration"],
      "sub_category": json["subCategory"] ?? json["sub_category"],
      "subCategory": json["subCategory"] ?? json["sub_category"],
      "item_category": json["itemCategory"] ?? json["item_category"],
      "itemCategory": json["itemCategory"] ?? json["item_category"],
      "closing_action": json["closingAction"] ?? json["closing_action"],
      "closingAction": json["closingAction"] ?? json["closing_action"],
      "brand": json["brand"],
      "source": json["source"],
      "follow_up_flag": json["followUpFlag"] ?? json["follow_up_flag"],
      "followUpFlag": json["followUpFlag"] ?? json["follow_up_flag"],
      "follow_up_date": json["followUpDate"] ?? json["follow_up_date"],
      "followUpDate": json["followUpDate"] ?? json["follow_up_date"],
      // Additional fields for feedback/return reports
      "booking_date": json["bookingDate"] ?? json["booking_date"],
      "bookingDate": json["bookingDate"] ?? json["booking_date"],
      "attended_by": json["attendedBy"] ?? json["attended_by"],
      "attendedBy": json["attendedBy"] ?? json["attended_by"],
      "service": json["service"],
      "rating": json["rating"],
      "mark_as_complaint": json["markAsComplaint"] ?? json["mark_as_complaint"],
      "markAsComplaint": json["markAsComplaint"] ?? json["mark_as_complaint"],
      "no_of_functions": json["noOfFunctions"] ?? json["no_of_functions"],
      "noOfFunctions": json["noOfFunctions"] ?? json["no_of_functions"],
      "no_of_attires": json["noOfAttires"] ?? json["no_of_attires"],
      "noOfAttires": json["noOfAttires"] ?? json["no_of_attires"],
      "competitor": json["competitor"],
    };

    return ReportModel(
      id: json['_id']?.toString() ?? '',
      originalId:
          json['report_id']?.toString() ??
          json['originalLeadId']?.toString() ??
          '',

      beforeSnapshot: json['beforeSnapshot'] as Map<String, dynamic>?,
      afterSnapshot: json['afterSnapshot'] as Map<String, dynamic>?,

      // FIX: always provide a valid snapshot object with top-level fields
      // Merge fallbackLeadSnapshot (top-level fields) with leadSnapshot if it exists
      leadSnapshot: () {
        final existingSnapshot = json['leadSnapshot'] as Map<String, dynamic>?;
        if (existingSnapshot != null && existingSnapshot.isNotEmpty) {
          // Merge: existing snapshot takes precedence, but fallback fills missing fields
          return Map<String, dynamic>.from(fallbackLeadSnapshot)
            ..addAll(existingSnapshot);
        }
        return fallbackLeadSnapshot;
      }(),

      listSnapshot: json['listSnapshot'] as Map<String, dynamic>?,

      // FIX: support both leadType & lead_type
      leadType: extractedLeadType.isNotEmpty ? extractedLeadType : null,

      editedBy: json['editedBy'] as Map<String, dynamic>?,
      changedFields:
          json['changedFields'] != null
              ? List<String>.from(json['changedFields'] as List)
              : null,
      note: json['note']?.toString(),

      // Get call_duration from top-level API response
      // API returns callDuration as String, so parse it to int
      callDuration: () {
        final callDur = json['call_duration'] ?? json['callDuration'];
        if (callDur == null) return null;
        if (callDur is int) return callDur;
        if (callDur is String) {
          try {
            return int.parse(callDur);
          } catch (_) {
            return null;
          }
        }
        return null;
      }(),

      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      editedAt: json['editedAt'] != null ? _parseDate(json['editedAt']) : null,
    );
  }

  // -------- Model to JSON -------- //
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "originalId": originalId,
      "beforeSnapshot": beforeSnapshot,
      "afterSnapshot": afterSnapshot,
      "leadSnapshot": leadSnapshot,
      "listSnapshot": listSnapshot,
      "leadType": leadType,
      "editedBy": editedBy,
      "changedFields": changedFields,
      "note": note,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "editedAt": editedAt?.toIso8601String(),
    };
  }

  // Helper for UI
  // Returns leadData with call_duration included from top-level if not in snapshot
  Map<String, dynamic>? get leadData {
    final data = leadSnapshot ?? afterSnapshot;
    if (data != null && callDuration != null) {
      // Ensure call_duration is included in leadData
      final updatedData = Map<String, dynamic>.from(data);
      if (!updatedData.containsKey('call_duration') &&
          !updatedData.containsKey('callDuration')) {
        updatedData['call_duration'] = callDuration;
        updatedData['callDuration'] = callDuration;
      }
      return updatedData;
    }
    return data;
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 50,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
    );
  }
}

class ReportsResponse {
  final List<ReportModel> reports;
  final PaginationInfo pagination;

  ReportsResponse({required this.reports, required this.pagination});

  factory ReportsResponse.fromJson(Map<String, dynamic> json) {
    // API returns data in 'data' object with 'leads' array
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final List<ReportModel> parsedReports =
        (data['leads'] as List? ?? data['reports'] as List? ?? [])
            .map((item) => ReportModel.fromJson(item as Map<String, dynamic>))
            .toList();

    print(
      'ReportsResponse: Parsed ${parsedReports.length} reports from API response',
    );

    return ReportsResponse(
      reports: parsedReports,
      pagination: PaginationInfo.fromJson(
        data['pagination'] ??
            {
              'page': data['page'] ?? 1,
              'limit': data['limit'] ?? 100,
              'total': data['total'] ?? 0,
              'pages': ((data['total'] ?? 0) / (data['limit'] ?? 100)).ceil(),
            },
      ),
    );
  }
}
