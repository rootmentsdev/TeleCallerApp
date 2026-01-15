class LeadModel {
  final String id;
  final String name;
  final String phone;
  final String? brand;
  final String? location;
  final String? leadStatus;
  final String? callStatus;
  final DateTime? followUpDate;
  final String? reason;
  final String? category; // Loss of Sale, Feedback, Booking Confirmation, etc.
  final DateTime createdAt;
  final DateTime?
  returnDate; // Return date for return leads (used instead of createdAt for return lead filtering)
  final int? callDuration; // Call duration in seconds
  final int callCount; // Number of calls made to this lead
  final String? source; // Source of lead (Walk-in, Call, etc.)
  final String? leadType; // Type of lead
  final bool isStarred; // Whether the lead is starred/favorite

  LeadModel({
    required this.id,
    required this.name,
    required this.phone,
    this.brand,
    this.location,
    this.leadStatus,
    this.callStatus,
    this.followUpDate,
    this.reason,
    this.category,
    this.callDuration,
    this.callCount = 0,
    DateTime? createdAt,
    this.returnDate,
    this.source,
    this.leadType,
    this.isStarred = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for local storage (camelCase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'brand': brand,
      'location': location,
      'leadStatus': leadStatus,
      'callStatus': callStatus,
      'followUpDate': followUpDate?.toIso8601String(),
      'reason': reason,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'callDuration': callDuration,
      'callCount': callCount,
      'source': source,
      'leadType': leadType,
      'isStarred': isStarred,
    };
  }

  // Convert to API format (snake_case) for backend
  Map<String, dynamic> toApiJson() {
    return {
      'lead_name': name,
      'phone_number': phone,
      'store': brand ?? location ?? '',
      'source': source ?? 'Walk-in',
      'lead_type': leadType ?? category ?? 'General',
      'call_status': callStatus ?? 'Not Called',
      'lead_status': leadStatus ?? 'No Status',
      'remarks': reason ?? '',
      'follow_up_flag': followUpDate != null,
      'function_date': followUpDate?.toIso8601String() ?? '',
      'booking_number': '',
      'security_amount': 0,
      'mark_as_issue': isStarred,
    };
  }

  // Create from Map (local storage - camelCase)
  factory LeadModel.fromMap(Map<String, dynamic> map) {
    return LeadModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      brand: map['brand'],
      location: map['location'],
      leadStatus: map['leadStatus'],
      callStatus: map['callStatus'],
      followUpDate:
          map['followUpDate'] != null
              ? DateTime.parse(map['followUpDate'])
              : null,
      reason: map['reason'],
      category: map['category'],
      callDuration: map['callDuration'],
      callCount: map['callCount'] ?? 0,
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      returnDate:
          map['returnDate'] != null ? DateTime.parse(map['returnDate']) : null,
      source: map['source'],
      leadType: map['leadType'],
      isStarred: map['isStarred'] ?? false,
    );
  }

  // Create from API response (handles both snake_case and camelCase)
  factory LeadModel.fromApiJson(Map<String, dynamic> json) {
    // Handle both snake_case and camelCase field names
    final id = json['_id'] ?? json['id'] ?? '';
    final name =
        json['lead_name'] ??
        json['name'] ??
        json['customerName'] ??
        json['customer_name'] ??
        '';
    final phone =
        json['phone_number'] ?? json['phone'] ?? json['phoneNumber'] ?? '';

    // Parse store field to extract brand and location
    String? brand;
    String? location;
    final storeField =
        json['store']?.toString() ?? json['store_location']?.toString();

    if (storeField != null && storeField.isNotEmpty) {
      if (storeField.contains(' - ')) {
        // Extract brand and location from "Brand - Location" format
        final parts = storeField.split(' - ');
        if (parts.length >= 2) {
          brand = parts[0].trim();
          location = parts[1].trim();
        } else {
          location = storeField.trim();
        }
      } else {
        location = storeField.trim();
      }
    } else {
      // Fallback to direct brand/location fields
      brand = json['brand'];
      location = json['location'];
    }

    // Handle both snake_case and camelCase for status fields
    final leadStatus = json['lead_status'] ?? json['leadStatus'];
    final callStatus = json['call_status'] ?? json['callStatus'];

    // Handle follow-up date (both formats)
    DateTime? followUpDate;
    final followUpDateValue =
        json['follow_up_date'] ?? json['followUpDate'] ?? json['follow_upDate'];
    if (followUpDateValue != null) {
      try {
        followUpDate = DateTime.parse(followUpDateValue.toString());
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    // Handle remarks/reason
    final reason = json['remarks'] ?? json['reason'];

    // Handle call duration (both formats)
    final callDuration = json['call_duration'] ?? json['callDuration'];

    // Handle call count
    final callCount = json['call_count'] ?? json['callCount'] ?? 0;

    // Handle createdAt (both formats)
    DateTime createdAt = DateTime.now();
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    if (createdAtValue != null) {
      try {
        createdAt = DateTime.parse(createdAtValue.toString());
      } catch (e) {
        // If parsing fails, use current time
      }
    }

    // Handle lead type (both formats)
    final leadType = json['lead_type'] ?? json['leadType'];

    // Handle isStarred (multiple possible field names)
    final isStarred =
        json['mark_as_issue'] ??
        json['is_starred'] ??
        json['isStarred'] ??
        false;

    // Handle returnDate (for return leads - both formats)
    DateTime? returnDate;
    final returnDateValue = json['return_date'] ?? json['returnDate'];
    if (returnDateValue != null) {
      try {
        returnDate = DateTime.parse(returnDateValue.toString());
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    return LeadModel(
      id: id,
      name: name,
      phone: phone,
      brand: brand,
      location: location,
      leadStatus: leadStatus,
      callStatus: callStatus,
      followUpDate: followUpDate,
      reason: reason,
      category: json['category'],
      callDuration:
          callDuration != null
              ? (callDuration is int
                  ? callDuration
                  : int.tryParse(callDuration.toString()))
              : null,
      callCount:
          callCount is int
              ? callCount
              : (int.tryParse(callCount.toString()) ?? 0),
      createdAt: createdAt,
      returnDate: returnDate,
      source: json['source'],
      leadType: leadType,
      isStarred: isStarred,
    );
  }

  // Check if lead needs follow-up (has followUpDate set)
  // Used to determine if lead should use follow-up API endpoint
  bool get needsFollowUp => followUpDate != null;

  /// Get the effective date for this lead based on its type
  /// For return leads: use returnDate if available, otherwise createdAt
  /// For all other leads: use createdAt
  DateTime getEffectiveDate() {
    if (leadType == 'return' && returnDate != null) {
      return returnDate!;
    }
    return createdAt;
  }

  // UI-level sorting helpers for Follow-Up screen tabs (Today/Upcoming/Overdue)
  // These are used ONLY for display sorting, not for data filtering
  // Backend already manages which leads are in FollowUps collection

  bool get isOverdue {
    if (followUpDate == null) return false;
    return followUpDate!.isBefore(DateTime.now());
  }

  bool get isToday {
    if (followUpDate == null) return false;
    final now = DateTime.now();
    return followUpDate!.year == now.year &&
        followUpDate!.month == now.month &&
        followUpDate!.day == now.day;
  }

  bool get isUpcoming {
    if (followUpDate == null) return false;
    return followUpDate!.isAfter(DateTime.now()) && !isToday;
  }
}
