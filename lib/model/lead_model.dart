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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for easy storage
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
    };
  }

  // Create from Map
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
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
    );
  }

  // Check if lead needs follow-up
  bool get needsFollowUp => followUpDate != null;

  // Check if follow-up is overdue
  bool get isOverdue {
    if (followUpDate == null) return false;
    return followUpDate!.isBefore(DateTime.now());
  }

  // Check if follow-up is today
  bool get isToday {
    if (followUpDate == null) return false;
    final now = DateTime.now();
    return followUpDate!.year == now.year &&
        followUpDate!.month == now.month &&
        followUpDate!.day == now.day;
  }

  // Check if follow-up is upcoming
  bool get isUpcoming {
    if (followUpDate == null) return false;
    return followUpDate!.isAfter(DateTime.now()) && !isToday;
  }
}
