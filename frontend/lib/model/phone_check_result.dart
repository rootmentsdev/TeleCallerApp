/// Represents the response from GET /api/customers/check-phone
class PhoneCheckResult {
  /// Whether a matching customer/lead was found
  final bool exists;

  /// The popup type that determines which screen to show.
  /// Possible values: followupPopup, complaintPopup, reportPopup,
  ///                  returnPopup, bookingConfirmationPopup, newLeadPopup
  final String popupType;

  /// The raw lead data returned by the API (null when exists=false)
  final Map<String, dynamic>? lead;

  /// The raw customer data returned by the API (null when exists=false)
  final Map<String, dynamic>? customer;

  PhoneCheckResult({
    required this.exists,
    required this.popupType,
    this.lead,
    this.customer,
  });

  factory PhoneCheckResult.fromJson(Map<String, dynamic> json) {
    final exists = json['exists'] == true;
    final popupType =
        json['popupType']?.toString() ??
        (exists ? 'reportPopup' : 'newLeadPopup');

    final leadRaw = json['lead'];
    final customerRaw = json['customer'];

    return PhoneCheckResult(
      exists: exists,
      popupType: popupType,
      lead: leadRaw is Map<String, dynamic> ? leadRaw : null,
      customer: customerRaw is Map<String, dynamic> ? customerRaw : null,
    );
  }

  /// Convenience: extract the lead _id
  String? get leadId => lead?['_id']?.toString() ?? lead?['id']?.toString();

  /// Convenience: extract the customer _id
  String? get customerId =>
      customer?['_id']?.toString() ?? customer?['id']?.toString();

  /// Convenience: extract the customer name
  String get customerName =>
      lead?['name']?.toString() ??
      customer?['name']?.toString() ??
      lead?['customerName']?.toString() ??
      '';

  /// Convenience: extract the phone number
  String get phone =>
      lead?['phone']?.toString() ?? customer?['phone']?.toString() ?? '';
}
