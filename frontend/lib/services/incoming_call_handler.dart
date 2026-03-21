import 'package:flutter/material.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/model/complaint_model.dart';
import 'package:telecaller_app/widgets.dart/new_lead_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_followup_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_booking_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_feedback_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_complaint_popup_sheet.dart';

/// Handles incoming call flow based on popupType from /customers/check-phone API
/// Routes to appropriate popup sheet based on popupType:
/// - newLeadPopup → NewLeadPopupSheet (default add lead)
/// - followupPopup → IncomingCallFollowupPopupSheet
/// - complaintPopup → IncomingCallComplaintPopupSheet
/// - returnPopup → IncomingCallFeedbackPopupSheet
/// - bookingConfirmationPopup → IncomingCallBookingPopupSheet
class IncomingCallHandler {
  final ApiService _api = ApiService();

  /// Main entry point for incoming call handling
  /// Routes based on popupType from /customers/check-phone API response
  Future<void> handleIncomingCall({
    required BuildContext context,
    required String phoneNumber,
    int? callDuration,
  }) async {
    final cleanPhone = _normalizePhoneNumber(phoneNumber);

    print('╔══════════════════════════════════════════════════════════╗');
    print('║         IncomingCallHandler: handleIncomingCall()        ║');
    print('╠══════════════════════════════════════════════════════════╣');
    print('║  rawPhone   : $phoneNumber');
    print('║  cleanPhone : $cleanPhone');
    print('║  duration   : $callDuration');
    print('╚══════════════════════════════════════════════════════════╝');

    _showLoadingDialog(context);

    try {
      // Step 1: Check phone via /customers/check-phone API
      final checkResult = await checkPhone(cleanPhone);
      print('IncomingCallHandler: checkPhone result: $checkResult');

      if (!context.mounted) {
        print('IncomingCallHandler: context not mounted after checkPhone');
        return;
      }

      Navigator.of(context).pop(); // dismiss loading

      if (checkResult == null || checkResult['success'] != true) {
        print('IncomingCallHandler: checkPhone failed or returned null');
        _showNewLeadPopup(context, cleanPhone, callDuration);
        return;
      }

      final data = checkResult['data'] as Map<String, dynamic>?;
      if (data == null) {
        print('IncomingCallHandler: no data in checkPhone response');
        _showNewLeadPopup(context, cleanPhone, callDuration);
        return;
      }

      // Check popupType from response
      final popupType = data['popupType']?.toString() ?? '';
      final leadId = data['leadId']?.toString() ?? '';

      print('IncomingCallHandler: popupType=$popupType, leadId=$leadId');

      // Route based on popupType
      switch (popupType) {
        case 'newLeadPopup':
          print('IncomingCallHandler: → Showing new lead popup');
          _showNewLeadPopup(context, cleanPhone, callDuration);
          break;

        case 'followupPopup':
          print('IncomingCallHandler: → Showing followup popup');
          await _showFollowupPopup(context, leadId, callDuration);
          break;

        case 'complaintPopup':
          print('IncomingCallHandler: → Showing complaint popup');
          await _showComplaintPopup(context, leadId, callDuration);
          break;

        case 'returnPopup':
          print('IncomingCallHandler: → Showing return popup');
          await _showReturnPopup(context, leadId, callDuration);
          break;

        case 'bookingConfirmationPopup':
          print('IncomingCallHandler: → Showing booking confirmation popup');
          await _showBookingConfirmationPopup(context, leadId, callDuration);
          break;

        default:
          print(
            'IncomingCallHandler: → Unknown popupType, showing new lead popup',
          );
          _showNewLeadPopup(context, cleanPhone, callDuration);
      }
    } catch (e) {
      print('IncomingCallHandler: ERROR - $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        _showErrorSnackbar(context, 'Failed to identify caller: $e');
        _showNewLeadPopup(context, cleanPhone, callDuration);
      }
    }
  }

  /// Step 1: Call /customers/check-phone API
  Future<Map<String, dynamic>?> checkPhone(String phone) async {
    try {
      print('IncomingCallHandler: checkPhone → calling API for $phone');
      final response = await _api.checkPhone(phone);
      print('IncomingCallHandler: checkPhone → response: $response');
      return response;
    } catch (e) {
      print('IncomingCallHandler: checkPhone → ERROR: $e');
      rethrow;
    }
  }

  /// Show followup popup - fetch data from /leads/followups/{id}
  Future<void> _showFollowupPopup(
    BuildContext context,
    String leadId,
    int? callDuration,
  ) async {
    try {
      print('IncomingCallHandler: _showFollowupPopup → fetching lead $leadId');
      final leadData = await _api.getLeadDetails(
        '/api/leads/followups/$leadId',
      );
      print('IncomingCallHandler: _showFollowupPopup → fetched: $leadData');

      if (!context.mounted) return;

      final lead = LeadModel.fromApiJson(leadData);

      // Show popup with save callback
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => IncomingCallFollowupPopupSheet(
              lead: lead,
              callDuration: callDuration,
              onSave: (closingAction, remarks) async {
                await _saveFollowup(
                  context,
                  leadId,
                  closingAction,
                  remarks,
                  callDuration,
                );
              },
            ),
      );
    } catch (e) {
      print('IncomingCallHandler: _showFollowupPopup → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to load followup: $e');
      }
    }
  }

  /// Show complaint popup - fetch data from /leads/complaints/{id}
  Future<void> _showComplaintPopup(
    BuildContext context,
    String leadId,
    int? callDuration,
  ) async {
    try {
      print(
        'IncomingCallHandler: _showComplaintPopup → fetching complaint $leadId',
      );
      final complaintData = await _api.getLeadDetails(
        '/api/leads/complaints/$leadId',
      );
      print(
        'IncomingCallHandler: _showComplaintPopup → fetched: $complaintData',
      );

      if (!context.mounted) return;

      final complaint = ComplaintModel.fromJson(complaintData);

      // Show popup with save callback
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => IncomingCallComplaintPopupSheet(
              complaint: complaint,
              callDuration: callDuration,
              onSave: (remarks) async {
                await _saveComplaint(context, leadId, remarks);
              },
            ),
      );
    } catch (e) {
      print('IncomingCallHandler: _showComplaintPopup → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to load complaint: $e');
      }
    }
  }

  /// Show return popup - fetch data from /leads/returns/{id}
  Future<void> _showReturnPopup(
    BuildContext context,
    String leadId,
    int? callDuration,
  ) async {
    try {
      print('IncomingCallHandler: _showReturnPopup → fetching lead $leadId');
      final leadData = await _api.getLeadDetails('/api/leads/returns/$leadId');
      print('IncomingCallHandler: _showReturnPopup → fetched: $leadData');

      if (!context.mounted) return;

      final lead = LeadModel.fromApiJson(leadData);

      // Show popup with save callback
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => IncomingCallFeedbackPopupSheet(
              lead: lead,
              callDuration: callDuration,
              onSave: (
                service,
                noofFunctions,
                noofAttires,
                competitor,
                rating,
                remarks,
                markAsComplaint,
                markAsFollowup,
                followupDate,
              ) async {
                await _saveReturn(
                  context,
                  leadId,
                  service,
                  callDuration,
                  noofFunctions,
                  noofAttires,
                  competitor,
                  rating,
                  remarks,
                  markAsComplaint,
                  markAsFollowup,
                  followupDate,
                );
              },
            ),
      );
    } catch (e) {
      print('IncomingCallHandler: _showReturnPopup → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to load return lead: $e');
      }
    }
  }

  /// Show booking confirmation popup - fetch data from /leads/booking-confirmation/{id}
  Future<void> _showBookingConfirmationPopup(
    BuildContext context,
    String leadId,
    int? callDuration,
  ) async {
    try {
      print(
        'IncomingCallHandler: _showBookingConfirmationPopup → fetching lead $leadId',
      );
      final leadData = await _api.getLeadDetails(
        '/api/leads/booking-confirmation/$leadId',
      );
      print(
        'IncomingCallHandler: _showBookingConfirmationPopup → fetched: $leadData',
      );

      if (!context.mounted) return;

      final lead = LeadModel.fromApiJson(leadData);

      // Show popup with save callback
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => IncomingCallBookingPopupSheet(
              lead: lead,
              callDuration: callDuration,
              onSave: (
                service,
                billReceived,
                amountMismatch,
                remarks,
                markAsComplaint,
                markAsFollowup,
                followupDate,
              ) async {
                await _saveBookingConfirmation(
                  context,
                  leadId,
                  service,
                  callDuration,
                  billReceived,
                  amountMismatch,
                  remarks,
                  markAsComplaint,
                  markAsFollowup,
                  followupDate,
                );
              },
            ),
      );
    } catch (e) {
      print('IncomingCallHandler: _showBookingConfirmationPopup → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to load booking confirmation: $e');
      }
    }
  }

  /// Save followup - POST to /leads/followups/{id}
  Future<void> _saveFollowup(
    BuildContext context,
    String leadId,
    String closingAction,
    String remarks,
    int? callDuration,
  ) async {
    try {
      print(
        'IncomingCallHandler: _saveFollowup → saving to /api/leads/followups/$leadId',
      );

      final body = {
        'followupclosingAction': closingAction,
        'followupremarks': remarks,
        'followupcallDuration': callDuration?.toString() ?? '0',
      };

      print('IncomingCallHandler: _saveFollowup → body: $body');

      final response = await _api.postFollowupUpdate(leadId, body);
      print('IncomingCallHandler: _saveFollowup → response: $response');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Followup saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context); // Close popup
      }
    } catch (e) {
      print('IncomingCallHandler: _saveFollowup → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to save followup: $e');
      }
    }
  }

  /// Save complaint - POST to /leads/complaints/{id}
  Future<void> _saveComplaint(
    BuildContext context,
    String leadId,
    String remarks,
  ) async {
    try {
      print(
        'IncomingCallHandler: _saveComplaint → saving to /api/leads/complaints/$leadId',
      );

      final body = {'remarks': remarks};

      print('IncomingCallHandler: _saveComplaint → body: $body');

      final response = await _api.postComplaintUpdate(leadId, body);
      print('IncomingCallHandler: _saveComplaint → response: $response');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context); // Close popup
      }
    } catch (e) {
      print('IncomingCallHandler: _saveComplaint → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to save complaint: $e');
      }
    }
  }

  /// Save return - POST to /leads/returns/{id}
  Future<void> _saveReturn(
    BuildContext context,
    String leadId,
    String? service,
    int? callDuration,
    int? noofFunctions,
    int? noofAttires,
    String? competitor,
    int? rating,
    String? remarks,
    bool? markAsComplaint,
    bool? markAsFollowup,
    DateTime? followupDate,
  ) async {
    try {
      print(
        'IncomingCallHandler: _saveReturn → saving to /api/leads/returns/$leadId',
      );

      final body = <String, dynamic>{
        'service': service,
        'callDuration': callDuration?.toString() ?? '0',
        'noofFunctions': noofFunctions ?? 0,
        'noofAttires': noofAttires ?? 0,
        'competitor': competitor,
        'rating': rating ?? 0,
        'remarks': remarks,
        'markasComplaint': markAsComplaint ?? false,
        'markasFollowup': markAsFollowup ?? false,
        if (followupDate != null)
          'followupDate': followupDate.toIso8601String(),
      };

      print('IncomingCallHandler: _saveReturn → body: $body');

      final response = await _api.postReturnUpdate(leadId, body);
      print('IncomingCallHandler: _saveReturn → response: $response');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return lead saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context); // Close popup
      }
    } catch (e) {
      print('IncomingCallHandler: _saveReturn → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to save return lead: $e');
      }
    }
  }

  /// Save booking confirmation - POST to /leads/booking-confirmation/{id}
  Future<void> _saveBookingConfirmation(
    BuildContext context,
    String leadId,
    String? service,
    int? callDuration,
    bool? billReceived,
    bool? amountMismatch,
    String? remarks,
    bool? markAsComplaint,
    bool? markAsFollowup,
    DateTime? followupDate,
  ) async {
    try {
      print(
        'IncomingCallHandler: _saveBookingConfirmation → saving to /api/leads/booking-confirmation/$leadId',
      );

      final body = <String, dynamic>{
        'service': service,
        'callDuration': callDuration?.toString() ?? '0',
        'billReceived': billReceived ?? false,
        'amountMismatch': amountMismatch ?? false,
        'remarks': remarks,
        'markasComplaint': markAsComplaint ?? false,
        'markasFollowup': markAsFollowup ?? false,
        if (followupDate != null)
          'followupDate': followupDate.toIso8601String(),
      };

      print('IncomingCallHandler: _saveBookingConfirmation → body: $body');

      final response = await _api.postBookingConfirmationUpdate(leadId, body);
      print(
        'IncomingCallHandler: _saveBookingConfirmation → response: $response',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmation saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context); // Close popup
      }
    } catch (e) {
      print('IncomingCallHandler: _saveBookingConfirmation → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to save booking confirmation: $e');
      }
    }
  }

  /// Fallback: Show new lead popup
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

  /// Show loading dialog
  void _showLoadingDialog(BuildContext context) {
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

  /// Show error snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Normalize phone number (remove non-digits, handle country codes)
  String _normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }
}
