import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/model/complaint_model.dart';
import 'package:telecaller_app/widgets.dart/new_lead_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_followup_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_booking_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_feedback_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_complaint_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_report_popup_sheet.dart';
import 'package:telecaller_app/widgets.dart/incoming_call_justdial_popup_sheet.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen/justdial_detail_screen.dart';

/// Handles incoming call flow based on popupType from /customers/check-phone API
/// Routes to appropriate popup sheet based on popupType:
/// - newLeadPopup → NewLeadPopupSheet (default add lead)
/// - followupPopup → IncomingCallFollowupPopupSheet
/// - complaintPopup → IncomingCallComplaintPopupSheet
/// - returnPopup → IncomingCallFeedbackPopupSheet
/// - bookingConfirmationPopup → IncomingCallBookingPopupSheet
/// - reportPopup → IncomingCallReportPopupSheet (completed leads from reports)
class IncomingCallHandler {
  final ApiService _api = ApiService();

  static final Queue<Map<String, dynamic>> _callQueue = Queue<Map<String, dynamic>>();
  static bool _isProcessingCall = false;

  /// Main entry point for incoming call handling
  /// Routes based on popupType from /customers/check-phone API response
  Future<void> handleIncomingCall({
    required BuildContext context,
    required String phoneNumber,
    int? callDuration,
  }) async {
    _callQueue.add({
      'context': context,
      'phoneNumber': phoneNumber,
      'callDuration': callDuration,
    });

    if (!_isProcessingCall) {
      await _processNextCall();
    }
  }

  Future<void> _processNextCall() async {
    if (_callQueue.isEmpty) {
      _isProcessingCall = false;
      return;
    }

    _isProcessingCall = true;
    final callData = _callQueue.removeFirst();

    final context = callData['context'] as BuildContext;
    final phoneNumber = callData['phoneNumber'] as String;
    final callDuration = callData['callDuration'] as int?;

    await _handleSingleIncomingCall(
      context: context,
      phoneNumber: phoneNumber,
      callDuration: callDuration,
    );

    // Process the next call in the queue
    await _processNextCall();
  }

  Future<void> _handleSingleIncomingCall({
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
        await _showNewLeadPopup(context, cleanPhone, callDuration);
        return;
      }

      final data = checkResult['data'] as Map<String, dynamic>?;
      if (data == null) {
        print('IncomingCallHandler: no data in checkPhone response');
        await _showNewLeadPopup(context, cleanPhone, callDuration);
        return;
      }

      // Check popupType from response
      final popupType = data['popupType']?.toString() ?? '';
      final leadId = data['leadId']?.toString() ?? data['_id']?.toString() ?? data['id']?.toString() ?? '';

      print('IncomingCallHandler: popupType=$popupType, leadId=$leadId');

      // Route based on popupType
      switch (popupType) {
        case 'newLeadPopup':
          print('IncomingCallHandler: → Showing new lead popup');
          await _showNewLeadPopup(context, cleanPhone, callDuration);
          break;

        case 'followupPopup':
          print('IncomingCallHandler: → Showing followup popup');
          // Check if a lead screen is already open - if yes, update it instead
          if (!_tryUpdateExistingLeadScreen(context, leadId, callDuration)) {
            await _showFollowupPopup(context, leadId, callDuration);
          }
          break;

        case 'complaintPopup':
          print('IncomingCallHandler: → Showing complaint popup');
          // Check if a lead screen is already open - if yes, update it instead
          if (!_tryUpdateExistingLeadScreen(context, leadId, callDuration)) {
            await _showComplaintPopup(context, leadId, callDuration);
          }
          break;

        case 'returnPopup':
          print('IncomingCallHandler: → Showing return popup');
          // Check if a lead screen is already open - if yes, update it instead
          if (!_tryUpdateExistingLeadScreen(context, leadId, callDuration)) {
            await _showReturnPopup(context, leadId, callDuration);
          }
          break;

        case 'bookingConfirmationPopup':
          print('IncomingCallHandler: → Showing booking confirmation popup');
          // Check if a lead screen is already open - if yes, update it instead
          if (!_tryUpdateExistingLeadScreen(context, leadId, callDuration)) {
            await _showBookingConfirmationPopup(context, leadId, callDuration);
          }
          break;

        case 'reportPopup':
          print('IncomingCallHandler: → Showing report popup');
          // Check if a lead screen is already open - if yes, update it instead
          if (!_tryUpdateExistingLeadScreen(context, leadId, callDuration)) {
            await _showReportPopup(context, leadId, callDuration, data);
          }
          break;

        case 'justdialPopup':
          print('IncomingCallHandler: → Showing JustDial popup');
          // Check if a lead screen is already open - if yes, update it instead
          if (!_tryUpdateExistingLeadScreen(context, leadId, callDuration)) {
            await _showJustDialPopup(context, leadId, callDuration, data);
          }
          break;

        default:
          print(
            'IncomingCallHandler: → Unknown popupType, showing new lead popup',
          );
          await _showNewLeadPopup(context, cleanPhone, callDuration);
      }
    } catch (e) {
      print('IncomingCallHandler: ERROR - $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        _showErrorSnackbar(context, 'Failed to identify caller: $e');
        await _showNewLeadPopup(context, cleanPhone, callDuration);
      }
    }
  }

  /// Try to update an existing lead screen if one is open
  /// Returns true if a lead screen was found and updated, false otherwise
  bool _tryUpdateExistingLeadScreen(
    BuildContext context,
    String leadId,
    int? callDuration,
  ) {
    try {
      print(
        'IncomingCallHandler: _tryUpdateExistingLeadScreen - checking for open lead screen',
      );

      // Try to find a lead screen in the navigation stack
      // This is a simple check - in a real app, you might use a more sophisticated approach
      // For now, we'll just return false to show the popup as before
      // In the future, you can implement a global state management solution to track open screens

      print(
        'IncomingCallHandler: _tryUpdateExistingLeadScreen - no open lead screen found',
      );
      return false;
    } catch (e) {
      print('IncomingCallHandler: _tryUpdateExistingLeadScreen - ERROR: $e');
      return false;
    }
  }

  /// Step 1: Call /customers/check-phone API
  Future<Map<String, dynamic>?> checkPhone(String phone) async {
    try {
      print('IncomingCallHandler: checkPhone → phone: $phone');
      final result = await _api.checkPhone(phone);
      print('IncomingCallHandler: checkPhone → result: $result');
      return result;
    } catch (e) {
      print('IncomingCallHandler: checkPhone → ERROR: $e');
      return null;
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
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => IncomingCallFollowupPopupSheet(
              lead: lead,
              callDuration: callDuration,
              onSave: (closingAction, remarks, followupDate) async {
                await _saveFollowup(
                  context,
                  leadId,
                  closingAction,
                  remarks,
                  callDuration,
                  followupDate,
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
      await showModalBottomSheet(
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
      await showModalBottomSheet(
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
      await showModalBottomSheet(
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

  /// Show report popup or navigate to detail screen
  /// If JustDial lead, navigate to JustDialDetailScreen instead of showing popup
  Future<void> _showReportPopup(
    BuildContext context,
    String leadId,
    int? callDuration,
    Map<String, dynamic>? leadDataFromResponse,
  ) async {
    try {
      print('IncomingCallHandler: _showReportPopup → leadId: $leadId');

      Map<String, dynamic> leadData;

      // If leadData is provided directly (e.g., from checkPhone response), use it
      if (leadDataFromResponse != null && leadDataFromResponse.isNotEmpty) {
        print(
          'IncomingCallHandler: _showReportPopup → using lead data from response',
        );
        leadData = leadDataFromResponse;
      } else if (leadId.isNotEmpty) {
        // Otherwise, fetch using leadId
        print('IncomingCallHandler: _showReportPopup → fetching lead $leadId');
        leadData = await _api.getLeadDetails('/api/leads/$leadId');
        print('IncomingCallHandler: _showReportPopup → fetched: $leadData');
      } else {
        // No leadId and no lead data - show error
        print(
          'IncomingCallHandler: _showReportPopup → ERROR: No leadId or lead data provided',
        );
        if (context.mounted) {
          _showErrorSnackbar(
            context,
            'Failed to load report lead: Missing lead ID',
          );
        }
        return;
      }

      if (!context.mounted) return;

      final lead = LeadModel.fromApiJson(leadData);
      final name = lead.name;
      final phone = lead.phone;

      // Check if this is a JustDial lead - navigate to detail screen instead of popup
      if (lead.leadType?.toLowerCase() == 'justdial') {
        print(
          'IncomingCallHandler: _showReportPopup → Detected JustDial lead, navigating to detail screen',
        );
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => JustDialDetailScreen(
                  name: name,
                  phone: phone,
                  callType: 'JustDial',
                  reportData: leadData,
                ),
          ),
        );
      } else {
        // Show generic report popup for non-JustDial leads
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder:
              (_) => IncomingCallReportPopupSheet(
                lead: lead,
                callDuration: callDuration,
                onSave: (remarks) async {
                  await _saveReport(context, lead, remarks, callDuration);
                },
              ),
        );
      }
    } catch (e) {
      print('IncomingCallHandler: _showReportPopup → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to load report lead: $e');
      }
    }
  }

  /// Show JustDial popup - fetch data from /leads/{id}
  /// Can also accept lead data directly if leadId is empty
  Future<void> _showJustDialPopup(
    BuildContext context,
    String leadId,
    int? callDuration,
    Map<String, dynamic>? leadDataFromResponse,
  ) async {
    try {
      print('IncomingCallHandler: _showJustDialPopup → leadId: $leadId');

      Map<String, dynamic> leadData;

      // If leadData is provided directly (e.g., from checkPhone response), use it
      if (leadDataFromResponse != null && leadDataFromResponse.isNotEmpty) {
        print(
          'IncomingCallHandler: _showJustDialPopup → using lead data from response',
        );
        leadData = leadDataFromResponse;
      } else if (leadId.isNotEmpty) {
        // Otherwise, fetch using leadId
        print(
          'IncomingCallHandler: _showJustDialPopup → fetching lead $leadId',
        );
        leadData = await _api.getLeadDetails('/api/leads/$leadId');
        print('IncomingCallHandler: _showJustDialPopup → fetched: $leadData');
      } else {
        // No leadId and no lead data - show error
        print(
          'IncomingCallHandler: _showJustDialPopup → ERROR: No leadId or lead data provided',
        );
        if (context.mounted) {
          _showErrorSnackbar(
            context,
            'Failed to load JustDial lead: Missing lead ID',
          );
        }
        return;
      }

      if (!context.mounted) return;

      final lead = LeadModel.fromApiJson(leadData);

      // Show JustDial popup with save callback
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => IncomingCallJustDialPopupSheet(
              lead: lead,
              callDuration: callDuration,
              onSave: (remarks) async {
                await _saveReport(context, lead, remarks, callDuration);
              },
            ),
      );
    } catch (e) {
      print('IncomingCallHandler: _showJustDialPopup → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to load JustDial lead: $e');
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
    DateTime? followupDate,
  ) async {
    try {
      print(
        'IncomingCallHandler: _saveFollowup → saving to /api/leads/followups/$leadId',
      );

      final body = {
        'followupclosingAction': closingAction,
        'followupremarks': remarks,
        'followupcallDuration': callDuration?.toString() ?? '0',
        if (followupDate != null)
          'followupDate': followupDate.toIso8601String(),
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

  /// Save report - POST to /leads
  Future<void> _saveReport(
    BuildContext context,
    LeadModel lead,
    String remarks,
    int? callDuration,
  ) async {
    try {
      final isJustDial = lead.leadType?.toLowerCase() == 'justdial';
      
      final body = <String, dynamic>{
        'name': lead.name ?? 'Unknown',
        'remarks': remarks,
        'phone': lead.phone,
        'leadtype': lead.leadType?.toLowerCase() ?? 'enquiry',
        'callStatus': 'connected',
        'store': lead.brand ?? lead.location ?? 'Unknown',
        if (callDuration != null) 'callDuration': callDuration.toString(),
      };

      print('IncomingCallHandler: _saveReport → body: $body');

      if (isJustDial) {
        print('IncomingCallHandler: _saveReport → saving JustDial to /api/leads/justdial/${lead.id}');
        await _api.updateJustDialLead(lead.id, body);
      } else {
        print('IncomingCallHandler: _saveReport → saving to /api/leads');
        await _api.postLeadUpdate(body);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report lead updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context); // Close popup
      }
    } catch (e) {
      print('IncomingCallHandler: _saveReport → ERROR: $e');
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to save report lead: $e');
      }
    }
  }

  /// Fallback: Show new lead popup
  Future<void> _showNewLeadPopup(
    BuildContext context,
    String phone,
    int? callDuration,
  ) async {
    await showModalBottomSheet(
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
