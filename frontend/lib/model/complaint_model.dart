import 'package:telecaller_app/utils/date_formatter.dart';
import 'package:telecaller_app/utils/store_location.dart';

class ComplaintModel {
  final String id;
  final String name;
  final String phone;
  final String store;
  final String type;
  final String date;
  final String functionDate;
  final String subCategory;
  final String remarks; // Original remarks (before call)
  final String
  complaintRemarks; // Complaint remarks (after call) - from complaint_remarks field
  final String callStatus;
  final String leadStatus;
  final bool isExpanded;
  final Map<String, dynamic> rawData;
  final int? callDuration;

  ComplaintModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.store,
    required this.type,
    required this.date,
    required this.functionDate,
    required this.subCategory,
    required this.remarks,
    this.complaintRemarks = '', // Optional - defaults to empty string
    required this.callStatus,
    required this.leadStatus,
    this.isExpanded = false,
    required this.rawData,
    this.callDuration,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    try {
      final rawStore = json['store']?.toString() ?? '';
      final normalizedStore = StoreLocations.normalizeStoreName(rawStore);

      // Parse callDuration - API returns as String, need to convert to int
      final callDuration = () {
        final callDur = json['callDuration'] ?? json['call_duration'];
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
      }();

      // Fetch original remarks (before call) - this is the 'remarks' field
      String originalRemarks = '';
      if (json['remarks'] != null) {
        originalRemarks = json['remarks'].toString();
      }

      // Check in nested snapshots if not found at top level
      if (originalRemarks.isEmpty) {
        final leadSnapshot = json['leadSnapshot'] as Map<String, dynamic>?;
        if (leadSnapshot != null && leadSnapshot['remarks'] != null) {
          originalRemarks = leadSnapshot['remarks'].toString();
        }
      }

      if (originalRemarks.isEmpty) {
        final afterSnapshot = json['afterSnapshot'] as Map<String, dynamic>?;
        if (afterSnapshot != null && afterSnapshot['remarks'] != null) {
          originalRemarks = afterSnapshot['remarks'].toString();
        }
      }

      // Fetch complaint remarks (after call) - this is the 'complaint_remarks' field
      // Handle null values properly
      String complaintRemarks = '';

      // Check top-level fields first - use null-aware operators
      if (json['complaint_remarks'] != null) {
        complaintRemarks = json['complaint_remarks'].toString();
      } else if (json['complaintRemarks'] != null) {
        complaintRemarks = json['complaintRemarks'].toString();
      }

      // Check in nested snapshots if not found at top level
      if (complaintRemarks.isEmpty) {
        final leadSnapshot = json['leadSnapshot'] as Map<String, dynamic>?;
        if (leadSnapshot != null) {
          if (leadSnapshot['complaint_remarks'] != null) {
            complaintRemarks = leadSnapshot['complaint_remarks'].toString();
          } else if (leadSnapshot['complaintRemarks'] != null) {
            complaintRemarks = leadSnapshot['complaintRemarks'].toString();
          }
        }
      }

      if (complaintRemarks.isEmpty) {
        final afterSnapshot = json['afterSnapshot'] as Map<String, dynamic>?;
        if (afterSnapshot != null) {
          if (afterSnapshot['complaint_remarks'] != null) {
            complaintRemarks = afterSnapshot['complaint_remarks'].toString();
          } else if (afterSnapshot['complaintRemarks'] != null) {
            complaintRemarks = afterSnapshot['complaintRemarks'].toString();
          }
        }
      }

      // Parse functionDate - handle MongoDB date format or string
      String functionDateStr = '';
      final functionDateValue = json['functionDate'];
      if (functionDateValue != null) {
        if (functionDateValue is Map) {
          // Handle MongoDB date format: {"$date": "2026-02-12T00:00:00.000Z"}
          if (functionDateValue.containsKey('\$date')) {
            functionDateStr = functionDateValue['\$date']?.toString() ?? '';
          } else if (functionDateValue.containsKey('date')) {
            functionDateStr = functionDateValue['date']?.toString() ?? '';
          } else {
            functionDateStr = functionDateValue.toString();
          }
        } else {
          functionDateStr = functionDateValue.toString();
        }
      }

      // Safely parse all fields with null handling
      // Handle _id which can be a Map with $oid or a String
      String id = '';
      final idValue = json['_id'];
      if (idValue != null) {
        if (idValue is Map) {
          // Handle MongoDB ObjectId format: {"$oid": "..."}
          id =
              idValue['\$oid']?.toString() ??
              idValue['oid']?.toString() ??
              idValue.toString();
        } else {
          id = idValue.toString();
        }
      }
      if (id.isEmpty) {
        id = json['id']?.toString() ?? '';
      }

      final name = json['name']?.toString() ?? 'Unknown';
      final phone = json['phone']?.toString() ?? '';
      final type = json['leadType']?.toString() ?? 'Enquiry';
      final subCategory = json['subCategory']?.toString() ?? '';
      final callStatus = json['callStatus']?.toString() ?? 'Not Called';
      final leadStatus = json['leadStatus']?.toString() ?? 'No Status';

      return ComplaintModel(
        id: id,
        name: name,
        phone: phone,
        store: normalizedStore,
        type: type,
        date: _formatDate(json['createdAt']),
        functionDate: functionDateStr,
        subCategory: subCategory,
        remarks: originalRemarks, // Original remarks (before call)
        complaintRemarks: complaintRemarks, // Complaint remarks (after call)
        callStatus: callStatus,
        leadStatus: leadStatus,
        rawData: json,
        callDuration: callDuration,
      );
    } catch (e, stackTrace) {
      print('ComplaintModel.fromJson error: $e');
      print('ComplaintModel.fromJson stackTrace: $stackTrace');
      print('ComplaintModel.fromJson json keys: ${json.keys.toList()}');
      // Return a minimal valid model to prevent crashes
      // Handle _id which can be a Map with $oid or a String
      String safeId = '';
      final idValue = json['_id'];
      if (idValue != null) {
        if (idValue is Map) {
          safeId =
              idValue['\$oid']?.toString() ??
              idValue['oid']?.toString() ??
              idValue.toString();
        } else {
          safeId = idValue.toString();
        }
      }
      if (safeId.isEmpty) {
        safeId = json['id']?.toString() ?? '';
      }

      return ComplaintModel(
        id: safeId,
        name: json['name']?.toString() ?? 'Unknown',
        phone: json['phone']?.toString() ?? '',
        store: StoreLocations.normalizeStoreName(
          json['store']?.toString() ?? '',
        ),
        type: json['leadType']?.toString() ?? 'Enquiry',
        date: 'N/A',
        functionDate: '',
        subCategory: json['subCategory']?.toString() ?? '',
        remarks: json['remarks']?.toString() ?? '',
        complaintRemarks:
            json['complaint_remarks']?.toString() ??
            json['complaintRemarks']?.toString() ??
            '',
        callStatus: json['callStatus']?.toString() ?? 'Not Called',
        leadStatus: json['leadStatus']?.toString() ?? 'No Status',
        rawData: json,
        callDuration:
            json['callDuration'] as int? ?? json['call_duration'] as int?,
      );
    }
  }

  static String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      String dateStr = '';
      if (dateValue is Map) {
        // Handle MongoDB date format: {"$date": "2026-02-12T00:00:00.000Z"}
        dateStr =
            dateValue['\$date']?.toString() ??
            dateValue['date']?.toString() ??
            '';
        if (dateStr.isEmpty) {
          return 'N/A';
        }
      } else {
        dateStr = dateValue.toString();
        if (dateStr.isEmpty || dateStr == 'null') {
          return 'N/A';
        }
      }

      final date = DateTime.parse(dateStr);
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final formattedDate = DateFormatter.formatDate(date);
      return '$formattedDate $hour:$minute';
    } catch (e) {
      return 'N/A';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'store': store,
      'type': type,
      'date': date,
      'functionDate': functionDate,
      'subCategory': subCategory,
      'remarks': remarks,
      'complaintRemarks': complaintRemarks,
      'callStatus': callStatus,
      'leadStatus': leadStatus,
      'isExpanded': isExpanded,
      'rawData': rawData,
      'callDuration': callDuration,
    };
  }

  ComplaintModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? store,
    String? type,
    String? date,
    String? functionDate,
    String? subCategory,
    String? remarks,
    String? complaintRemarks,
    String? callStatus,
    String? leadStatus,
    bool? isExpanded,
    Map<String, dynamic>? rawData,
    int? callDuration,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      store: store ?? this.store,
      type: type ?? this.type,
      date: date ?? this.date,
      functionDate: functionDate ?? this.functionDate,
      subCategory: subCategory ?? this.subCategory,
      remarks: remarks ?? this.remarks,
      complaintRemarks: complaintRemarks ?? this.complaintRemarks,
      callStatus: callStatus ?? this.callStatus,
      leadStatus: leadStatus ?? this.leadStatus,
      isExpanded: isExpanded ?? this.isExpanded,
      rawData: rawData ?? this.rawData,
      callDuration: callDuration ?? this.callDuration,
    );
  }

  /// Check if call has been made (call was completed)
  /// Returns true only if callStatus is NOT "Not Called" AND there's evidence of a call
  ///
  /// Logic:
  /// - If callStatus is "Not Called", return false (no call made, regardless of other fields)
  /// - If callStatus is not "Not Called", check if callDuration > 0 or complaint_remarks exists
  bool get hasCallBeenMade {
    // If callStatus is "Not Called", no call has been made
    if (callStatus == 'Not Called') {
      return false;
    }

    // If callStatus is not "Not Called", check for evidence of a call:
    // - callDuration > 0 indicates a call was tracked
    // - complaint_remarks exists indicates a call was made and saved
    final hasCallDuration = callDuration != null && callDuration! > 0;
    final hasComplaintRemarks = complaintRemarks.isNotEmpty;

    // Call was made if there's evidence (duration or remarks)
    return hasCallDuration || hasComplaintRemarks;
  }

  /// Get display remarks - shows complaint remarks only after call is made
  /// Before call: shows original remarks (remarks field)
  /// After call: shows complaint remarks (complaint_remarks field)
  String get displayRemarks {
    if (hasCallBeenMade) {
      // After call: show complaint remarks (complaint_remarks from backend)
      return complaintRemarks.isNotEmpty
          ? complaintRemarks
          : (remarks.isNotEmpty ? remarks : 'No remarks yet');
    } else {
      // Before call: show original remarks (remarks field)
      return remarks.isNotEmpty ? remarks : 'No remarks yet';
    }
  }
}
