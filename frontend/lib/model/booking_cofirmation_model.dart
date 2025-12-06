class BookingConfirmationLead {
  final String id;
  final String leadName;
  final String phoneNumber;
  final String store;
  final String leadType;
  final String callStatus;
  final String leadStatus;
  final DateTime? functionDate;
  final DateTime? enquiryDate;
  final DateTime createdAt;
  final String? assignedTo;
  final String bookingNumber;

  BookingConfirmationLead({
    required this.id,
    required this.leadName,
    required this.phoneNumber,
    required this.store,
    required this.leadType,
    required this.callStatus,
    required this.leadStatus,
    required this.functionDate,
    required this.enquiryDate,
    required this.createdAt,
    required this.assignedTo,
    required this.bookingNumber,
  });

  factory BookingConfirmationLead.fromJson(Map<String, dynamic> json) {
    return BookingConfirmationLead(
      id: json["id"] ?? "",
      leadName: json["lead_name"] ?? "",
      phoneNumber: json["phone_number"] ?? "",
      store: json["store"] ?? "",
      leadType: json["lead_type"] ?? "",
      callStatus: json["call_status"] ?? "",
      leadStatus: json["lead_status"] ?? "",
      functionDate:
          json["function_date"] != null
              ? DateTime.parse(json["function_date"])
              : null,
      enquiryDate:
          json["enquiry_date"] != null
              ? DateTime.parse(json["enquiry_date"])
              : null,
      createdAt: DateTime.parse(json["created_at"]),
      assignedTo: json["assigned_to"],
      bookingNumber: json["booking_number"] ?? "",
    );
  }
}
