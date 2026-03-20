import 'package:flutter/material.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/model/complaint_model.dart';
import 'package:telecaller_app/model/phone_check_result.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/view/followup_screen/followup_detail_screen.dart';
import 'package:telecaller_app/view/complaints_screen/complaint_detail_screen.dart';
import 'package:telecaller_app/view/lead_screen/return_lead_details_screen.dart';
import 'package:telecaller_app/view/lead_screen/booking_confirmation_detail_screen.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen/enquiry_detail_screen.dart';
import 'package:telecaller_app/widgets.dart/new_lead_popup_sheet.dart';

/// Handles the "identify caller" workflow.
///
/// Call [identify] with the incoming phone number and an optional call duration.
/// It will:
///   1. Hit GET /api/customers/check-phone?phone=<number>
///   2. Parse the popupType from the response
///   3. Navigate / show the correct screen with pre-filled data
///   4. Fall back to the newLeadPopup on any error
class PhoneIdentificationService {
  final ApiService _api = ApiService();

  /// Main entry point. Call this when an incoming call is detected or
  /// when the user manually searches a phone number.
  ///
  /// [context]      – A valid BuildContext for navigation.
  /// [phone]        – Raw phone string (digits, spaces, dashes — all OK).
  /// [callDuration] – Optional call duration in seconds (from call tracking).
  Future<void> identify({
    required BuildContext context,
    required String phone,
    int? callDuration,
  }) async {
    print('╔══════════════════════════════════════════════════════════╗');
    print('║         PhoneIdentificationService: identify()           ║');
    print('╠══════════════════════════════════════════════════════════╣');
    print('║  phone        : $phone');
    print('║  callDuration : $callDuration');
    print('╚══════════════════════════════════════════════════════════╝');

    // Show a loading indicator while we wait for the API
    _showLoading(context);

    PhoneCheckResult result;
    try {
      print('PhoneIdentificationService: Calling checkPhone API for $phone...');
      final raw = await _api.checkPhone(phone);
      print('PhoneIdentificationService: Raw API response: $raw');
      result = PhoneCheckResult.fromJson(raw);
      print('PhoneIdentificationService: Parsed result:');
      print('  popupType    : ${result.popupType}');
      print('  customerName : ${result.customerName}');
      print('  phone        : ${result.phone}');
      print('  leadId       : ${result.leadId}');
      print('  lead keys    : ${result.lead?.keys.toList()}');
    } catch (e) {
      print('PhoneIdentificationService: ERROR calling checkPhone - $e');
      print('PhoneIdentificationService: Falling back to newLeadPopup');
      // On any error, fall back to the new-lead flow
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        _showNewLeadPopup(context, phone, callDuration);
      } else {
        print(
          'PhoneIdentificationService: context not mounted after error, cannot show fallback popup',
        );
      }
      return;
    }

    if (!context.mounted) {
      print(
        'PhoneIdentificationService: context not mounted after API call, cannot show popup',
      );
      return;
    }
    Navigator.of(context).pop(); // dismiss loading

    print(
      'PhoneIdentificationService: Routing to popupType="${result.popupType}"',
    );

    // Route based on popupType
    switch (result.popupType) {
      case 'followupPopup':
        print('PhoneIdentificationService: → FollowupDetailScreen');
        _navigateFollowup(context, result);
        break;
      case 'complaintPopup':
        print('PhoneIdentificationService: → ComplaintDetailScreen');
        _navigateComplaint(context, result);
        break;
      case 'returnPopup':
        print('PhoneIdentificationService: → ReturnLeadDetailsScreen');
        _navigateReturn(context, result);
        break;
      case 'bookingConfirmationPopup':
        print('PhoneIdentificationService: → BookingConfirmationDetailScreen');
        _navigateBookingConfirmation(context, result);
        break;
      case 'reportPopup':
        print('PhoneIdentificationService: → EnquiryDetailScreen (report)');
        _navigateReport(context, result);
        break;
      case 'newLeadPopup':
      default:
        print(
          'PhoneIdentificationService: → NewLeadPopupSheet (default/newLeadPopup)',
        );
        _showNewLeadPopup(context, phone, callDuration);
        break;
    }
  }

  // ─── Routing helpers ────────────────────────────────────────────────────────

  void _navigateFollowup(BuildContext context, PhoneCheckResult result) {
    final lead = _buildLeadModel(result);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FollowupDetailScreen(lead: lead)),
    );
  }

  void _navigateComplaint(BuildContext context, PhoneCheckResult result) {
    final complaint = _buildComplaintModel(result);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintDetailScreen(complaint: complaint),
      ),
    );
  }

  void _navigateReturn(BuildContext context, PhoneCheckResult result) {
    final lead = _buildLeadModel(result);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReturnLeadDetailsScreen(lead: lead)),
    );
  }

  void _navigateBookingConfirmation(
    BuildContext context,
    PhoneCheckResult result,
  ) {
    final lead = _buildLeadModel(result);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationDetailScreen(lead: lead),
      ),
    );
  }

  void _navigateReport(BuildContext context, PhoneCheckResult result) {
    final leadData = result.lead ?? {};
    final name =
        result.customerName.isNotEmpty ? result.customerName : 'Unknown';
    final phone = result.phone;
    final callType =
        leadData['leadType']?.toString() ??
        leadData['leadtype']?.toString() ??
        'Enquiry';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EnquiryDetailScreen(
              name: name,
              phone: phone,
              callType: callType,
              reportData: leadData,
            ),
      ),
    );
  }

  void _showNewLeadPopup(
    BuildContext context,
    String phone,
    int? callDuration,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) =>
              NewLeadPopupSheet(phoneNumber: phone, callDuration: callDuration),
    );
  }

  // ─── Model builders ─────────────────────────────────────────────────────────

  /// Build a [LeadModel] from the API response, pre-filling all available fields.
  LeadModel _buildLeadModel(PhoneCheckResult result) {
    if (result.lead != null) {
      return LeadModel.fromApiJson(result.lead!);
    }
    // Minimal fallback when lead data is absent
    return LeadModel(
      id: result.leadId ?? '',
      name: result.customerName,
      phone: result.phone,
    );
  }

  /// Build a [ComplaintModel] from the API response.
  ComplaintModel _buildComplaintModel(PhoneCheckResult result) {
    final data = result.lead ?? {};
    if (data.isNotEmpty) {
      return ComplaintModel.fromJson(data);
    }
    return ComplaintModel(
      id: result.leadId ?? '',
      name: result.customerName,
      phone: result.phone,
      store: '',
      type: 'Complaint',
      date: '',
      functionDate: '',
      subCategory: '',
      remarks: '',
      callStatus: 'Not Called',
      leadStatus: 'No Status',
      rawData: data,
    );
  }

  // ─── Loading indicator ───────────────────────────────────────────────────────

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Identifying caller...'),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
