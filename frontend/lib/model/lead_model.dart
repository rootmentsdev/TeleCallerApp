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
  final int? callDuration; // Call duration in seconds
  final int callCount; // Number of calls made to this lead
  final String? source; // Source of lead (Walk-in, Call, etc.)
  final String? leadType; // Type of lead

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
    this.source,
    this.leadType,
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
      'callDuration': callDuration,
      'callCount': callCount,
      'source': source,
      'leadType': leadType,
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
      source: map['source'],
      leadType: map['leadType'],
    );
  }

  // Create from API response (snake_case)
  factory LeadModel.fromApiJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['lead_name'] ?? json['name'] ?? '',
      phone: json['phone_number'] ?? json['phone'] ?? '',
      brand: json['brand'],
      location: json['location'],
      leadStatus: json['lead_status'],
      callStatus: json['call_status'],
      followUpDate:
          json['follow_up_date'] != null
              ? DateTime.parse(json['follow_up_date'])
              : null,
      reason: json['remarks'] ?? json['reason'],
      category: json['category'],
      callDuration: json['call_duration'],
      callCount: json['call_count'] ?? json['callCount'] ?? 0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      source: json['source'],
      leadType: json['lead_type'],
    );
  }

  // Check if lead needs follow-up (has followUpDate set)
  // Used to determine if lead should use follow-up API endpoint
  bool get needsFollowUp => followUpDate != null;

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
