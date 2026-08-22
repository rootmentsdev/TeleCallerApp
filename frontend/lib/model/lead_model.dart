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
  updatedAt; // When the lead was last updated (e.g., when call was made)
  final DateTime?
  returnDate; // Return date for return leads (used instead of createdAt for return lead filtering)
  final int? callDuration; // Call duration in seconds
  final int callCount; // Number of calls made to this lead
  final String? source; // Source of lead (Walk-in, Call, etc.)
  final String? leadType; // Type of lead
  final bool isStarred; // Whether the lead is starred/favorite
  final String? subCategory; // Sub category for the lead
  final String? closingAction; // Closing action for the lead
  final DateTime? enquiryDate; // Enquiry date from API
  final DateTime? functionDate; // Function date from API
  final DateTime? visitDate; // Visit date from API
  final String? bookingNumber; // Booking number from API
  final Map<String, dynamic>? assignedTo; // Assigned to user info from API
  final int? rating; // Rating for return leads (1-5)
  final bool? followUpFlag; // Flag to keep in Follow-Ups collection
  final bool? markAsComplaint; // Flag to move to Complaints
  final DateTime? bookingDate; // Booking date for booking confirmation leads

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
    this.updatedAt,
    this.returnDate,
    this.source,
    this.leadType,
    this.isStarred = false,
    this.subCategory,
    this.closingAction,
    this.enquiryDate,
    this.functionDate,
    this.visitDate,
    this.bookingNumber,
    this.assignedTo,
    this.rating,
    this.followUpFlag,
    this.markAsComplaint,
    this.bookingDate,
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
      'updatedAt': updatedAt?.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'callDuration': callDuration,
      'callCount': callCount,
      'source': source,
      'leadType': leadType,
      'isStarred': isStarred,
      'subCategory': subCategory,
      'closingAction': closingAction,
      'enquiryDate': enquiryDate?.toIso8601String(),
      'functionDate': functionDate?.toIso8601String(),
      'visitDate': visitDate?.toIso8601String(),
      'bookingNumber': bookingNumber,
      'assignedTo': assignedTo,
      'rating': rating,
      'followUpFlag': followUpFlag,
      'markAsComplaint': markAsComplaint,
      'bookingDate': bookingDate?.toIso8601String(),
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
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      returnDate:
          map['returnDate'] != null ? DateTime.parse(map['returnDate']) : null,
      source: map['source'],
      leadType: map['leadType'],
      isStarred: map['isStarred'] ?? false,
      subCategory: map['subCategory'],
      closingAction: map['closingAction'],
      enquiryDate:
          map['enquiryDate'] != null
              ? DateTime.parse(map['enquiryDate'])
              : null,
      functionDate:
          map['functionDate'] != null
              ? DateTime.parse(map['functionDate'])
              : null,
      visitDate:
          map['visitDate'] != null ? DateTime.parse(map['visitDate']) : null,
      bookingNumber: map['bookingNumber'],
      assignedTo: map['assignedTo'],
      rating: map['rating'],
      followUpFlag: map['followUpFlag'],
      markAsComplaint: map['markAsComplaint'],
      bookingDate:
          map['bookingDate'] != null
              ? DateTime.parse(map['bookingDate'])
              : null,
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
        json['phone_number'] ?? json['phone'] ?? json['phoneNumber'] ?? json['customerPhone'] ?? '';

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

    // JustDial leads don't have a 'store' field — use city/area/brancharea instead
    if (location == null || location.isEmpty) {
      final branchArea = json['brancharea']?.toString();
      final area = json['area']?.toString();
      final city = json['city']?.toString();
      location =
          (branchArea != null && branchArea.isNotEmpty)
              ? branchArea
              : (area != null && area.isNotEmpty)
              ? area
              : city;
    }

    // Handle both snake_case and camelCase for status fields
    final leadStatus = json['lead_status'] ?? json['leadStatus'];
    final callStatus = json['call_status'] ?? json['callStatus'];

    // Handle follow-up date (both formats)
    DateTime? followUpDate;
    final followUpDateValue =
        json['follow_up_date'] ?? json['followUpDate'] ?? json['followupDate'];
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

    // Handle createdAt (both formats) — also check JustDial 'date' field
    DateTime createdAt = DateTime.now();
    final createdAtValue =
        json['created_at'] ?? json['createdAt'] ?? json['date'];
    if (createdAtValue != null) {
      try {
        createdAt = DateTime.parse(createdAtValue.toString());
      } catch (e) {
        // If parsing fails, use current time
      }
    }

    // Handle updatedAt (both formats)
    DateTime? updatedAt;
    final updatedAtValue = json['updated_at'] ?? json['updatedAt'];
    if (updatedAtValue != null) {
      try {
        updatedAt = DateTime.parse(updatedAtValue.toString());
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    // Handle lead type (both formats)
    final leadType = json['lead_type'] ?? json['leadType'] ?? json['leadtype'];

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

    // Handle enquiry date
    DateTime? enquiryDate;
    final enquiryDateValue = json['enquiry_date'] ?? json['enquiryDate'];
    if (enquiryDateValue != null) {
      try {
        enquiryDate = DateTime.parse(enquiryDateValue.toString());
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    // Handle function date
    DateTime? functionDate;
    final functionDateValue = json['function_date'] ?? json['functionDate'];
    if (functionDateValue != null) {
      try {
        functionDate = DateTime.parse(functionDateValue.toString());
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    // Handle visit date
    DateTime? visitDate;
    final visitDateValue = json['visit_date'] ?? json['visitDate'];
    if (visitDateValue != null) {
      try {
        visitDate = DateTime.parse(visitDateValue.toString());
      } catch (e) {
        // If parsing fails, leave as null
      }
    }

    // Handle booking number
    final bookingNumber = json['booking_number'] ?? json['bookingNumber'];

    // Handle assigned_to (user info)
    final assignedTo = json['assigned_to'] ?? json['assignedTo'];

    // Handle rating
    final rating = json['rating'];

    // Handle follow_up_flag
    final followUpFlag = json['follow_up_flag'] ?? json['followUpFlag'];

    // Handle mark_as_complaint
    final markAsComplaint =
        json['mark_as_complaint'] ??
        json['markAsComplaint'] ??
        json['markasComplaint'];

    // Handle bookingDate (for booking confirmation leads)
    DateTime? bookingDate;
    final bookingDateValue = json['bookingDate'] ?? json['booking_date'];
    if (bookingDateValue != null) {
      try {
        bookingDate = DateTime.parse(bookingDateValue.toString());
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
      updatedAt: updatedAt,
      returnDate: returnDate,
      source: json['source'],
      leadType: leadType,
      isStarred: isStarred,
      subCategory: json['sub_category'] ?? json['subCategory'],
      closingAction: json['closing_action'] ?? json['closingAction'],
      enquiryDate: enquiryDate,
      functionDate: functionDate,
      visitDate: visitDate,
      bookingNumber: bookingNumber,
      assignedTo: assignedTo,
      rating:
          rating != null
              ? (rating is int ? rating : int.tryParse(rating.toString()))
              : null,
      followUpFlag:
          followUpFlag != null
              ? (followUpFlag is bool
                  ? followUpFlag
                  : followUpFlag.toString().toLowerCase() == 'true')
              : null,
      markAsComplaint:
          markAsComplaint != null
              ? (markAsComplaint is bool
                  ? markAsComplaint
                  : markAsComplaint.toString().toLowerCase() == 'true')
              : null,
      bookingDate: bookingDate,
    );
  }

  // Check if lead needs follow-up (has followUpDate set)
  // Used to determine if lead should use follow-up API endpoint
  bool get needsFollowUp => followUpDate != null;

  /// Get the effective date for this lead based on its type
  /// For return/feedback leads: use returnDate if available, otherwise createdAt
  /// For booking confirmation leads: use bookingDate if available, otherwise createdAt
  /// For all other leads: use createdAt
  DateTime getEffectiveDate() {
    final type = leadType?.toLowerCase();
    final cat = category?.toLowerCase();

    // Return/Feedback leads — check both leadType and category
    final isReturn =
        type == 'return' ||
        type == 'feedback' ||
        type == 'rentout' ||
        type == 'rent out' ||
        type == 'rentoutfeedback' ||
        cat == 'return' ||
        cat == 'rentout' ||
        cat == 'rent out' ||
        cat == 'feedback';
    if (isReturn && returnDate != null) {
      return returnDate!;
    }

    // Booking Confirmation leads — check both leadType and category
    final isBooking =
        type == 'bookingconfirmation' ||
        type == 'booking confirmation' ||
        type == 'booking' ||
        type == 'booked' ||
        cat == 'booking confirmation' ||
        cat == 'bookingconfirmation';
    if (isBooking && bookingDate != null) {
      return bookingDate!;
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
