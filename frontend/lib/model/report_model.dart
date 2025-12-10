class ReportModel {
  final String id;
  final String originalId;
  final Map<String, dynamic>? beforeSnapshot;
  final Map<String, dynamic>? afterSnapshot;
  final Map<String, dynamic>? leadSnapshot; // API uses leadSnapshot
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

  // Create from JSON/Map
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      try {
        return DateTime.parse(dateValue.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return ReportModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      originalId:
          json['originalLeadId']?.toString() ??
          json['originalId']?.toString() ??
          '',
      beforeSnapshot: json['beforeSnapshot'] as Map<String, dynamic>?,
      afterSnapshot: json['afterSnapshot'] as Map<String, dynamic>?,
      leadSnapshot: json['leadSnapshot'] as Map<String, dynamic>?,
      listSnapshot: json['listSnapshot'] as Map<String, dynamic>?,
      leadType: json['leadType']?.toString(),
      editedBy: json['editedBy'] as Map<String, dynamic>?,
      changedFields:
          json['changedFields'] != null
              ? List<String>.from(json['changedFields'] as List)
              : null,
      note: json['note']?.toString(),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
      editedAt: parseDate(json['editedAt']),
    );
  }

  // Convert to Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalId': originalId,
      'beforeSnapshot': beforeSnapshot,
      'afterSnapshot': afterSnapshot,
      'leadSnapshot': leadSnapshot,
      'listSnapshot': listSnapshot,
      'leadType': leadType,
      'editedBy': editedBy,
      'changedFields': changedFields,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  // Get lead data from leadSnapshot (the current state of the lead)
  Map<String, dynamic>? get leadData => leadSnapshot ?? afterSnapshot;
}

class ReportsResponse {
  final List<ReportModel> reports;
  final PaginationInfo pagination;

  ReportsResponse({required this.reports, required this.pagination});

  factory ReportsResponse.fromJson(Map<String, dynamic> json) {
    List<ReportModel> reportsList = [];
    if (json['reports'] != null && json['reports'] is List) {
      reportsList =
          (json['reports'] as List)
              .map((item) => ReportModel.fromJson(item as Map<String, dynamic>))
              .toList();
    }

    PaginationInfo paginationInfo = PaginationInfo.fromJson(
      json['pagination'] as Map<String, dynamic>? ?? {},
    );

    return ReportsResponse(reports: reportsList, pagination: paginationInfo);
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
    // Handle both direct values and nested structure
    return PaginationInfo(
      page:
          json['page'] as int? ??
          (json['pagination'] != null
              ? (json['pagination'] as Map)['page'] as int?
              : null) ??
          1,
      limit:
          json['limit'] as int? ??
          (json['pagination'] != null
              ? (json['pagination'] as Map)['limit'] as int?
              : null) ??
          50,
      total:
          json['total'] as int? ??
          (json['pagination'] != null
              ? (json['pagination'] as Map)['total'] as int?
              : null) ??
          0,
      pages:
          json['pages'] as int? ??
          (json['pagination'] != null
              ? (json['pagination'] as Map)['pages'] as int?
              : null) ??
          0,
    );
  }
}
