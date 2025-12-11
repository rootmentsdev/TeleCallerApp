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
    // Fallback leadSnapshot if backend did not send nested snapshot
    final fallbackLeadSnapshot = {
      "lead_name": json["lead_name"],
      "phone_number": json["phone_number"],
      "store": json["store"],
      "lead_type": json["lead_type"],
      "call_status": json["call_status"],
      "lead_status": json["lead_status"],
      "remarks": json["remarks"],
      "reason_collected_from_store": json["reason_collected_from_store"],
      "enquiry_date": json["enquiry_date"],
      "visit_date": json["visit_date"],
      "function_date": json["function_date"],
      "return_date": json["return_date"],
      "created_at": json["created_at"],
    };

    return ReportModel(
      id: json['_id']?.toString() ?? '',
      originalId: json['originalLeadId']?.toString() ?? '',

      beforeSnapshot: json['beforeSnapshot'] as Map<String, dynamic>?,
      afterSnapshot: json['afterSnapshot'] as Map<String, dynamic>?,

      // FIX: always provide a valid snapshot object
      leadSnapshot: json['leadSnapshot'] != null
          ? json['leadSnapshot'] as Map<String, dynamic>?
          : fallbackLeadSnapshot,

      listSnapshot: json['listSnapshot'] as Map<String, dynamic>?,

      // FIX: support both leadType & lead_type
      leadType: json['leadType']?.toString() ?? json['lead_type']?.toString(),

      editedBy: json['editedBy'] as Map<String, dynamic>?,
      changedFields:
          json['changedFields'] != null
              ? List<String>.from(json['changedFields'] as List)
              : null,
      note: json['note']?.toString(),

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
  Map<String, dynamic>? get leadData => leadSnapshot ?? afterSnapshot;
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
    final List<ReportModel> parsedReports =
        (json['reports'] as List? ?? [])
            .map((item) => ReportModel.fromJson(item))
            .toList();

    return ReportsResponse(
      reports: parsedReports,
      pagination: PaginationInfo.fromJson(
        json['pagination'] ?? {},
      ),
    );
  }
}
