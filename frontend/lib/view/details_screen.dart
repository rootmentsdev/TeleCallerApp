import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/controller/followup_controller.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/format_helper.dart';
import 'package:telecaller_app/utils/date_formatter.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/services/api_service.dart';

class DetailsScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  final int
  callTypeIndex; // 0: All Calls, 1: Loss of Sale, 3: Booking Confirmation

  const DetailsScreen({
    super.key,
    required this.contact,
    required this.callTypeIndex,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  String? selectedCallStatus;
  String? selectedReason;
  final TextEditingController customReasonController = TextEditingController();
  String? selectedLeadStatus;
  bool markAsFollowUp = false;
  bool markAsStarred = false;
  DateTime? followUpDate;
  int rating = 0;
  final TextEditingController remarksController = TextEditingController();

  // Dirty flag to track unsaved changes
  bool _isDirty = false;

  // Call tracking variables
  bool _isCallActive = false;
  int _callDurationSeconds = 0;
  bool _hasCalled = false; // Track if call was initiated from lead screen
  bool _isWaitingForDuration =
      false; // Track if waiting for call log to write duration
  bool _isSaving = false; // Track if save operation is in progress

  final List<Map<String, dynamic>> callSummary = [
    {
      "title": "All Calls",
      "count": "88",
      "bgColor": const Color(0xFFE8E3FF),
      "iconColor": const Color(0xFF7C5DFF),
      "icon": Icons.people_alt_outlined,
    },
    {
      "title": "Loss of Sale",
      "count": "44",
      "bgColor": const Color(0xFFFFE8E8),
      "iconColor": const Color(0xFFE23434),
      "icon": Icons.trending_down,
    },
    {
      "title": "Hard-Out Calls",
      "count": "15",
      "bgColor": const Color(0xFFFFF7CC),
      "iconColor": const Color(0xFFFFCC00),
      "icon": Icons.message_outlined,
    },
    {
      "title": "Booking\nConfirmation",
      "count": "0",
      "bgColor": const Color(0xFFD4F5DA),
      "iconColor": const Color(0xff56BE6B),
      "icon": Icons.flag_outlined,
    },
  ];

  final List<String> callStatusOptions = [
    "Not called yet",
    "Connected",
    "Not Connected",
    "Call Back Later",
    "Confirmed",
    "Cancelled",
  ];

  final List<String> reasonOptions = [
    "Price too high",
    "Not interested",
    "Family approval pending",
    "Looking for alternatives",
    "Budget constraints",
    "Other",
  ];

  final List<String> leadStatusOptions = [
    "No Status",
    "Confirmed",
    "Pending",
    "Cancelled",
    "Follow Up Required",
  ];

  // Check if this is a follow-up lead
  bool get isFollowUpLead {
    final followUpDate = widget.contact["followUpDate"] as DateTime?;
    final category = widget.contact["category"] as String?;
    return followUpDate != null || category == "Follow Up";
  }

  // Get category name for follow-up screen
  String get followUpCategory {
    final category = widget.contact["category"] as String?;
    if (category == "Loss of Sales") return "Loss of Sale";
    if (category == "Return") return "Return";
    if (category == "Booking confirmation") return "Booking Confirmation";
    if (category == "Just Dial") return "Just Dial Enquiry";
    return category ?? "Follow Up";
  }

  String get screenTitle {
    // Check if it's a follow-up lead
    if (isFollowUpLead) {
      return "Follow Up | $followUpCategory";
    }

    // Check if it's a return call
    if (widget.contact["isRentout"] == true) {
      return "Return Call";
    }

    switch (widget.callTypeIndex) {
      case 0:
        return "All Calls Lead Details";
      case 1:
        return "Loss of Sale Lead Details";
      case 3:
        return "Booking Confirmation Lead Details";
      default:
        return "Lead Details";
    }
  }

  Color get iconColor {
    // Purple for follow-up leads
    if (isFollowUpLead) {
      return const Color(0xFF7C5DFF);
    }
    return callSummary[widget.callTypeIndex]["iconColor"] as Color;
  }

  Color get iconBgColor {
    // Light purple for follow-up leads
    if (isFollowUpLead) {
      return const Color(0xFFE8E3FF);
    }
    return callSummary[widget.callTypeIndex]["bgColor"] as Color;
  }

  IconData get icon {
    // Headset icon for follow-up leads
    if (isFollowUpLead) {
      return Icons.headset_mic_outlined;
    }
    return callSummary[widget.callTypeIndex]["icon"] as IconData;
  }

  @override
  void initState() {
    super.initState();

    // Add listeners to track changes for dirty flag
    remarksController.addListener(_markDirty);
    customReasonController.addListener(_markDirty);

    // Initialize call duration from existing contact if available
    final existingDuration = widget.contact["callDuration"] as int?;
    if (existingDuration != null && existingDuration > 0) {
      _callDurationSeconds = existingDuration;
    }

    // Check if there's a cached duration from a previous call
    // (in case user navigated away during call)
    final cachedDuration = PhoneCallService.getCachedDuration();
    if (cachedDuration != null && cachedDuration > 0) {
      print('DetailsScreen: Found cached duration=$cachedDuration');
      _callDurationSeconds = cachedDuration;
      if (selectedCallStatus == null) {
        selectedCallStatus = "Connected";
      }
    }

    // Initialize CallTrackingController and listen for call duration updates
    // Do this immediately, not in addPostFrameCallback, so we don't miss events
    final callTrackingController = Provider.of<CallTrackingController>(
      context,
      listen: false,
    );

    // Initialize the service (only sets up listener once)
    callTrackingController.initialize();

    // Listen to controller changes for call duration updates
    callTrackingController.addListener(_onCallTrackingUpdate);
  }

  /// Handle call tracking updates from CallTrackingController
  void _onCallTrackingUpdate() {
    print('DetailsScreen: _onCallTrackingUpdate called');

    // Check if widget is still mounted BEFORE accessing context
    if (!mounted) {
      print('DetailsScreen: Widget unmounted, ignoring call tracking update');
      return;
    }

    final callTrackingController = Provider.of<CallTrackingController>(
      context,
      listen: false,
    );

    print(
      'DetailsScreen: lastDuration=${callTrackingController.lastDuration}, lastPhone=${callTrackingController.lastPhone}',
    );

    if (callTrackingController.lastDuration != null) {
      final duration = callTrackingController.lastDuration!;
      final phoneNumber = callTrackingController.lastPhone ?? '';
      final contactPhone = widget.contact["phone"] as String? ?? "";

      final callWasAnswered = callTrackingController.lastCallWasAnswered;
      print(
        'DetailsScreen: Call tracking update - duration=$duration, phone=$phoneNumber, callWasAnswered=$callWasAnswered',
      );

      // Check if this call matches our contact OR if we're currently in a call
      // This handles cases where phone number is "Unknown" but we just made a call
      final phoneMatches = _isPhoneNumberMatch(phoneNumber, contactPhone);
      final isCurrentlyInCall = _isCallActive || _hasCalled;

      print(
        'DetailsScreen: phoneMatches=$phoneMatches, isCurrentlyInCall=$isCurrentlyInCall',
      );

      // Update if phone matches OR if we're currently in a call (handles "Unknown" phone number case)
      if (phoneMatches || isCurrentlyInCall) {
        print(
          'DetailsScreen: Call matches current lead or we\'re in a call - updating duration',
        );

        // Only update UI if widget is still mounted
        if (mounted) {
          if (duration > 0) {
            print(
              'DetailsScreen: Setting duration=$duration and status=Connected',
            );
            setState(() {
              _callDurationSeconds =
                  duration; // Always overwrite with new duration
              _isCallActive = false;
              _isWaitingForDuration = false;
              // Auto-set status to Connected if call had duration
              if (selectedCallStatus == null) {
                selectedCallStatus = "Connected";
              }
            });

            // Also update the lead repository immediately
            _updateLeadDurationInRepository(duration);
          } else {
            // Call ended with 0 duration
            // CRITICAL FIX: If call was answered, don't overwrite valid duration with 0
            // This prevents valid durations from being cleared by delayed/duplicate events
            final callWasAnswered = callTrackingController.lastCallWasAnswered;
            if (callWasAnswered && _callDurationSeconds > 0) {
              print(
                'DetailsScreen: Call was answered but got duration=0 - ignoring to preserve existing duration=${_callDurationSeconds}',
              );
              // Don't overwrite - keep existing duration, but reset call active state
              setState(() {
                _isCallActive = false;
                _isWaitingForDuration = false;
              });
            } else {
              // Call ended but was not answered (missed/rejected) OR no previous duration
              print(
                'DetailsScreen: Call ended with 0 duration (not answered or no previous duration)',
              );
              setState(() {
                _isCallActive = false;
                _callDurationSeconds = 0;
                _isWaitingForDuration = false;
              });
            }
          }
        } else {
          print(
            'DetailsScreen: Widget unmounted, but duration cached for next mount',
          );
        }
      } else {
        print(
          'DetailsScreen: Call does not match current lead and we\'re not in a call - ignoring',
        );
      }
    } else {
      print('DetailsScreen: lastDuration is null');
    }
  }

  /// Check if phone numbers match (handles different formats)
  bool _isPhoneNumberMatch(String phone1, String phone2) {
    // Clean both numbers
    String clean1 = phone1.replaceAll(RegExp(r'[^\d]'), '');
    String clean2 = phone2.replaceAll(RegExp(r'[^\d]'), '');

    // Handle country codes
    if (clean1.startsWith('91') && clean1.length == 12) {
      clean1 = clean1.substring(2);
    }
    if (clean2.startsWith('91') && clean2.length == 12) {
      clean2 = clean2.substring(2);
    }

    // Handle leading zeros
    if (clean1.startsWith('0') && clean1.length == 11) {
      clean1 = clean1.substring(1);
    }
    if (clean2.startsWith('0') && clean2.length == 11) {
      clean2 = clean2.substring(1);
    }

    // Compare last 10 digits
    if (clean1.length >= 10) {
      clean1 = clean1.substring(clean1.length - 10);
    }
    if (clean2.length >= 10) {
      clean2 = clean2.substring(clean2.length - 10);
    }

    return clean1 == clean2 ||
        clean1.contains(clean2) ||
        clean2.contains(clean1);
  }

  /// Update lead duration in repository immediately when Android writes to call log
  Future<void> _updateLeadDurationInRepository(int duration) async {
    final leadId = widget.contact["id"] as String?;
    if (leadId == null) return;

    try {
      final repository = LeadRepository();
      final lead = repository.getLeadById(leadId);
      if (lead != null) {
        // Increment call count if duration > 0 (call was answered)
        final newCallCount =
            duration > 0 ? (lead.callCount + 1) : lead.callCount;

        final updatedLead = LeadModel(
          id: lead.id,
          name: lead.name,
          phone: lead.phone,
          brand: lead.brand,
          location: lead.location,
          leadStatus: lead.leadStatus,
          callStatus: lead.callStatus,
          followUpDate: lead.followUpDate,
          reason: lead.reason,
          category: lead.category,
          createdAt: lead.createdAt,
          callDuration:
              duration, // Always overwrite with new duration from Android call log
          callCount: newCallCount, // Increment call count
        );
        await repository.updateLead(updatedLead);
        print(
          'DetailsScreen: Updated lead with duration=${duration}s, callCount=$newCallCount',
        );
      }
    } catch (e) {
      print('DetailsScreen: Error updating lead duration: $e');
    }
  }

  Future<void> _saveCallUpdate() async {
    // Check if widget is still mounted before proceeding
    if (!mounted) {
      print('DetailsScreen: Widget unmounted, aborting save');
      return;
    }

    print('DetailsScreen: Saving call update - duration=$_callDurationSeconds');

    // If call was made and has duration, auto-set status to Connected
    if (_callDurationSeconds > 0 && selectedCallStatus == null) {
      selectedCallStatus = "Connected";
    }

    // If no call status is set, set default
    if (selectedCallStatus == null || selectedCallStatus!.isEmpty) {
      if (_isCallActive || _callDurationSeconds > 0) {
        selectedCallStatus = "Connected";
      } else {
        selectedCallStatus = "Not called yet";
      }
    }

    // Get the lead ID if available
    final leadId = widget.contact["id"] as String?;

    if (leadId != null) {
      final repository = LeadRepository();
      final lead = repository.getLeadById(leadId);

      if (lead != null) {
        // Update lead with new information
        final updatedLead = LeadModel(
          id: lead.id,
          name: lead.name,
          phone: lead.phone,
          brand: lead.brand,
          location: lead.location,
          leadStatus: selectedLeadStatus,
          callStatus: selectedCallStatus,
          followUpDate: markAsFollowUp ? followUpDate : null,
          reason:
              selectedReason == "Other"
                  ? customReasonController.text.trim().isEmpty
                      ? null
                      : customReasonController.text.trim()
                  : selectedReason,
          category: lead.category,
          createdAt: lead.createdAt,
          callDuration: _callDurationSeconds > 0 ? _callDurationSeconds : null,
          callCount: lead.callCount, // Preserve call count
        );

        // Update locally first
        await repository.updateLead(updatedLead);
        print(
          'DetailsScreen: Lead updated locally with duration=$_callDurationSeconds',
        );

        // If this is a follow-up lead (has followUpDate), update via follow-up endpoint
        // Check if lead is from FollowUps collection (has followUpDate) AND call was made (not "Not Called")
        final newCallStatus =
            selectedCallStatus ?? lead.callStatus ?? 'Not Called';

        // Check followUpDate from lead object OR from contact map (fallback)
        final followUpDateFromContact =
            widget.contact["followUpDate"] as DateTime?;
        final hasFollowUpDate =
            lead.needsFollowUp || followUpDateFromContact != null;

        final isFollowUpLead =
            hasFollowUpDate; // Has followUpDate means it's in FollowUps collection
        final callWasMade = !LeadConstants.isUncalledStatus(newCallStatus);

        print('DetailsScreen: Checking follow-up update conditions:');
        print(
          'DetailsScreen: lead.needsFollowUp=${lead.needsFollowUp}, followUpDateFromContact=$followUpDateFromContact',
        );
        print(
          'DetailsScreen: isFollowUpLead=$isFollowUpLead, newCallStatus=$newCallStatus, callWasMade=$callWasMade',
        );

        if (isFollowUpLead && callWasMade) {
          try {
            print('DetailsScreen: Updating follow-up lead via API');
            print('DetailsScreen: Follow-up Lead ID: $leadId');
            print('DetailsScreen: Call Status: $newCallStatus');
            print(
              'DetailsScreen: Lead Status: ${selectedLeadStatus ?? lead.leadStatus ?? "No Status"}',
            );

            // Use followUpDate from lead object or fallback to contact map
            final followUpDateToUse =
                lead.followUpDate ?? followUpDateFromContact;

            // Get call duration from the current call duration (in seconds)
            // IMPORTANT: Pass duration even if 0, as 0 is a valid duration for unanswered calls
            // Backend needs duration 0 to create report entries
            final callDurationToSend =
                _callDurationSeconds >= 0 ? _callDurationSeconds : null;

            await repository.updateFollowUpLeadFromApi(
              id: leadId,
              callStatus: newCallStatus,
              leadStatus:
                  selectedLeadStatus ??
                  lead.leadStatus ??
                  'No Status', // REQUIRED by API
              remarks:
                  remarksController.text.trim().isEmpty
                      ? null
                      : remarksController.text.trim(),
              callDuration:
                  callDurationToSend, // Pass call duration (number in seconds) - backend expects this
              followUpDate: followUpDateToUse,
              clearFollowUpDate: followUpDateToUse == null,
            );

            print('DetailsScreen: Follow-up lead updated successfully via API');

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Follow-up lead updated successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Show error message but don't block navigation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update follow-up on server: ${e.toString().replaceFirst('Exception: ', '')}',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            print('DetailsScreen: Error updating follow-up lead via API: $e');
          }

          // Pop back and refresh Follow-Up screen immediately
          if (mounted) {
            Navigator.of(context).pop();

            // Refresh FollowupController to remove the lead from Follow-Up screen
            // (backend moved it to Reports collection)
            try {
              final followupController = Provider.of<FollowupController>(
                context,
                listen: false,
              );
              await followupController.fetchFollowUpLeads();
              print('DetailsScreen: Follow-Up screen refreshed');
            } catch (e) {
              print('DetailsScreen: Error refreshing Follow-Up screen: $e');
            }

            // Also refresh Reports screen to show the new report
            try {
              final reportController = Provider.of<ReportController>(
                context,
                listen: false,
              );
              await reportController.fetchReportsWithCurrentFilters();
              print('DetailsScreen: Reports screen refreshed');
            } catch (e) {
              print('DetailsScreen: Error refreshing Reports screen: $e');
            }
          }
          return;
        }

        // If it's a Loss of Sale lead, also update via API
        if (lead.category == LeadConstants.categoryLossOfSales) {
          try {
            // Get LeadScreenController from Provider
            final leadController = Provider.of<LeadScreenController>(
              context,
              listen: false,
            );

            await leadController.updateLossOfSaleLead(
              id: leadId,
              callStatus: selectedCallStatus,
              leadStatus: selectedLeadStatus,
              followUpDate: markAsFollowUp ? followUpDate : null,
              reasonCollectedFromStore: updatedLead.reason,
              remarks:
                  remarksController.text.trim().isEmpty
                      ? null
                      : remarksController.text.trim(),
            );

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Loss of Sale lead updated successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Show error message but don't block navigation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update on server: ${e.toString().replaceFirst('Exception: ', '')}',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            print('Error updating Loss of Sale lead via API: $e');
          }
        }

        // If it's a Return lead, also update via API
        if (lead.category == LeadConstants.categoryRentOut ||
            widget.contact["isRentout"] == true) {
          try {
            // Get LeadScreenController from Provider
            final leadController = Provider.of<LeadScreenController>(
              context,
              listen: false,
            );

            // Determine call date - use current time if call was made
            DateTime? callDate;
            if (_callDurationSeconds > 0 || _isCallActive) {
              callDate = DateTime.now();
            }

            await leadController.updateReturnLead(
              id: leadId,
              callStatus: selectedCallStatus,
              leadStatus: selectedLeadStatus,
              followUpFlag: markAsFollowUp,
              callDate: callDate,
              rating: rating > 0 ? rating : null,
              remarks:
                  remarksController.text.trim().isEmpty
                      ? null
                      : remarksController.text.trim(),
              // IMPORTANT: Pass duration even if 0, as 0 is a valid duration for unanswered calls
              // Backend needs duration 0 to create report entries
              callDuration:
                  _callDurationSeconds >= 0 ? _callDurationSeconds : null,
              followUpDate: markAsFollowUp ? callDate : null,
              clearFollowUpDate: !markAsFollowUp && lead.followUpDate != null,
            );

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Return lead updated successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Show error message but don't block navigation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update on server: ${e.toString().replaceFirst('Exception: ', '')}',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            print('Error updating Return lead via API: $e');
          }
        }

        // If it's a Booking Confirmation lead, also update via API
        if (lead.category == LeadConstants.categoryBookingConfirmation ||
            widget.callTypeIndex == 3) {
          try {
            // Get LeadScreenController from Provider
            final leadController = Provider.of<LeadScreenController>(
              context,
              listen: false,
            );

            // Determine call date - use current time if call was made
            DateTime? callDate;
            if (_callDurationSeconds > 0 || _isCallActive) {
              callDate = DateTime.now();
            }

            await leadController.updateBookingConfirmationLead(
              id: leadId,
              callStatus: selectedCallStatus,
              leadStatus: selectedLeadStatus,
              followUpFlag: markAsFollowUp,
              callDate: callDate,
              remarks:
                  remarksController.text.trim().isEmpty
                      ? null
                      : remarksController.text.trim(),
              // IMPORTANT: Pass duration even if 0, as 0 is a valid duration for unanswered calls
              // Backend needs duration 0 to create report entries
              callDuration:
                  _callDurationSeconds >= 0 ? _callDurationSeconds : null,
            );

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Booking Confirmation lead updated successfully',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Show error message but don't block navigation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update on server: ${e.toString().replaceFirst('Exception: ', '')}',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            print('Error updating Booking Confirmation lead via API: $e');
          }
        }

        // If it's a general/walk-in lead (no specific category), update via API
        if (lead.category == null || lead.category!.isEmpty) {
          try {
            final apiService = ApiService();
            final store = lead.location ?? lead.brand ?? 'Unknown';

            print('DetailsScreen: Updating general lead via API');
            print('DetailsScreen: Lead ID: $leadId');

            // If marking as follow-up, call moveLeadToFollowUp to move to FollowUps collection
            if (markAsFollowUp && followUpDate != null) {
              print('DetailsScreen: Moving lead to follow-up collection');
              await apiService.moveLeadToFollowUp(
                id: leadId,
                followUpDate: followUpDate!,
                callStatus: selectedCallStatus ?? 'Not Called',
                leadStatus: selectedLeadStatus ?? 'No Status',
                remarks:
                    remarksController.text.trim().isEmpty
                        ? null
                        : remarksController.text.trim(),
              );
              print('DetailsScreen: Lead moved to follow-up successfully');

              // Remove the original lead from local repository to prevent duplicates
              // Backend creates a new follow-up lead with a new ID, so we need to remove the original
              try {
                final repository = LeadRepository();
                await repository.removeLead(leadId);
                print(
                  'DetailsScreen: Original lead removed from local repository to prevent duplicates',
                );
              } catch (e) {
                print(
                  'DetailsScreen: Error removing original lead from local repository: $e',
                );
                // Don't block navigation if removal fails - phone number matching in fetchFollowUpLeadsFromApi will handle it
              }
            } else {
              // Regular update (may go directly to Reports if not follow-up)
              print('DetailsScreen: Calling apiService.updateLead with:');
              print('  - leadId: $leadId');
              print('  - callStatus: $selectedCallStatus');
              print('  - callDuration: $_callDurationSeconds');

              await apiService.updateLead(
                id: leadId,
                leadName: lead.name,
                phoneNumber: lead.phone,
                store: store,
                source: lead.source ?? 'Walk-in',
                leadType: lead.leadType ?? 'General',
                callStatus: selectedCallStatus ?? 'Not Called',
                leadStatus: selectedLeadStatus ?? 'No Status',
                remarks:
                    remarksController.text.trim().isEmpty
                        ? null
                        : remarksController.text.trim(),
                followUpFlag: markAsFollowUp,
                followUpDate:
                    markAsFollowUp ? followUpDate?.toIso8601String() : null,
                functionDate: null,
                // IMPORTANT: Pass duration even if 0, as 0 is a valid duration for unanswered calls
                // Backend needs duration 0 to create report entries
                callDuration:
                    _callDurationSeconds >= 0 ? _callDurationSeconds : null,
              );
              print('DetailsScreen: General lead updated successfully via API');

              // Update local repository immediately to remove lead from lead screen if no longer uncalled
              try {
                final repository = LeadRepository();
                final updatedLead = LeadModel(
                  id: lead.id,
                  name: lead.name,
                  phone: lead.phone,
                  brand: lead.brand,
                  location: lead.location,
                  leadStatus:
                      selectedLeadStatus ?? lead.leadStatus ?? 'No Status',
                  callStatus: selectedCallStatus ?? 'Not Called',
                  followUpDate:
                      markAsFollowUp ? followUpDate : lead.followUpDate,
                  reason: lead.reason,
                  category: lead.category,
                  callDuration:
                      _callDurationSeconds >= 0
                          ? _callDurationSeconds
                          : lead.callDuration,
                  createdAt: lead.createdAt,
                  callCount: lead.callCount,
                );
                await repository.updateLead(updatedLead);
                print(
                  'DetailsScreen: Local repository updated - lead will be removed from lead screen if no longer uncalled',
                );
              } catch (e) {
                print('DetailsScreen: Error updating local repository: $e');
                // Don't block navigation if local update fails
              }
            }

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lead updated successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Show error message but don't block navigation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update on server: ${e.toString().replaceFirst('Exception: ', '')}',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            print('DetailsScreen: Error updating general lead via API: $e');
          }
        }
      }
    }

    // Reset dirty flag after successful save
    _isDirty = false;

    // Backend-driven flow: Simple navigation
    // Just pop back - screens will refresh and fetch from correct backend endpoints
    // Backend handles all collection transitions (Leads → FollowUps → Reports)
    if (mounted) {
      Navigator.of(context).pop();

      // Refresh all screens to fetch fresh data from backend
      try {
        final leadController = Provider.of<LeadScreenController>(
          context,
          listen: false,
        );
        await leadController.fetchAllLeadsFromApi();
      } catch (e) {
        print('Could not refresh LeadScreenController: $e');
      }

      try {
        final followupController = Provider.of<FollowupController>(
          context,
          listen: false,
        );
        await followupController.fetchFollowUpLeads();
      } catch (e) {
        print('Could not refresh FollowupController: $e');
      }

      try {
        final reportController = Provider.of<ReportController>(
          context,
          listen: false,
        );
        await reportController.fetchReportsWithCurrentFilters();
      } catch (e) {
        print('Could not refresh ReportController: $e');
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number is not available'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Clean phone number - keep + sign but remove spaces, dashes, parentheses
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleanedNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid phone number'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      // Start call tracking for outgoing call
      final callTrackingController = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );
      callTrackingController.startOutgoingCall(cleanedNumber);

      // Use PhoneCallService to make call and automatically track duration
      final success = await PhoneCallService.makeCall(cleanedNumber);

      if (success && mounted) {
        setState(() {
          _isCallActive = true;
          _callDurationSeconds = 0;
          _hasCalled = true; // Enable form fields after call is initiated
        });
      } else if (mounted) {
        // Fallback to url_launcher
        final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
        try {
          final launched = await launchUrl(
            phoneUri,
            mode: LaunchMode.externalApplication,
          );

          if (launched && mounted) {
            setState(() {
              _isCallActive = true;
              _callDurationSeconds = 0;
              _hasCalled = true;
            });
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Unable to make call. Please grant phone call permission in settings.',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (launchError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Unable to make call. Please grant phone call permission in settings.',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making phone call: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Remove call tracking listener immediately
    try {
      final callTrackingController = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );
      callTrackingController.removeListener(_onCallTrackingUpdate);
    } catch (e) {
      // Context may not be available during dispose
      print('DetailsScreen: Error removing listener in dispose: $e');
    }

    remarksController.dispose();
    customReasonController.dispose();
    super.dispose();
  }

  /// Mark the form as dirty when any field changes
  void _markDirty() {
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        backgroundColor: ColorConstant.primaryColor,
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back button positioned on the left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _handleBackNavigation,
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Centered title and subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10),
                        child: Text(
                          screenTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: TextConstant.dmSansMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          widget.contact["storeName"] ?? "Zorucci Edappally",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact Information Section
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: iconBgColor,
                            child: Icon(icon, color: iconColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.contact["name"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: TextConstant.dmSansMedium,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      widget.contact["phone"] ?? "",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: ColorConstant.grey,
                                        fontFamily: TextConstant.dmSansRegular,
                                      ),
                                    ),
                                    // Call Duration Badge for follow-up leads
                                    if (isFollowUpLead &&
                                        (_callDurationSeconds > 0 ||
                                            widget.contact["callDuration"] !=
                                                null))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.timer,
                                                size: 14,
                                                color: Colors.blue[700],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                FormatHelper.formatCallDurationWithUnits(
                                                  _callDurationSeconds > 0
                                                      ? _callDurationSeconds
                                                      : (widget.contact["callDuration"]
                                                              as int? ??
                                                          0),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue[700],
                                                  fontFamily:
                                                      TextConstant.dmSansMedium,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Hide Call Now button for follow-up leads (shown at bottom instead)
                          if (!isFollowUpLead)
                            ElevatedButton.icon(
                              onPressed:
                                  _isCallActive
                                      ? null
                                      : () async {
                                        await _makePhoneCall(
                                          widget.contact["phone"] ?? "",
                                        );
                                      },
                              icon: Icon(
                                _isCallActive
                                    ? Icons.phone_disabled
                                    : Icons.phone,
                                size: 18,
                              ),
                              label: Text(
                                _isCallActive ? "Calling..." : "Call Now",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isCallActive
                                        ? Colors.grey[400]
                                        : ColorConstant.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Lead Details Section - Dynamic based on call type
                      _buildDetailsSection(),

                      const SizedBox(height: 24),

                      // Real-time Call Duration Display
                      if (_isCallActive && _callDurationSeconds == 0)
                        _callInfoBox(
                          icon: Icons.phone_in_talk,
                          color: Colors.blue,
                          title: 'On Call',
                          value: 'Connected',
                        ),

                      // Show duration if call has ended (even if 0)
                      if (!_isCallActive && _callDurationSeconds >= 0)
                        _callInfoBox(
                          icon: Icons.timer,
                          color:
                              _callDurationSeconds > 0
                                  ? Colors.green
                                  : Colors.orange,
                          title: 'Call Duration',
                          value: FormatHelper.formatCallDurationWithUnits(
                            _callDurationSeconds,
                          ),
                        ),

                      if (_isWaitingForDuration || _callDurationSeconds > 0)
                        const SizedBox(height: 24),

                      // Status Dropdowns - Show as pills for follow-up leads
                      if (isFollowUpLead) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusPillDropdown(
                                "Call Status",
                                selectedCallStatus,
                                callStatusOptions,
                                Colors.green,
                                _hasCalled,
                                (value) {
                                  setState(() {
                                    selectedCallStatus = value;
                                    _isDirty = true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatusPillDropdown(
                                "Lead Status",
                                selectedLeadStatus,
                                leadStatusOptions,
                                Colors.purple,
                                _hasCalled,
                                (value) {
                                  setState(() {
                                    selectedLeadStatus = value;
                                    _isDirty = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Call Status Dropdown
                        _buildDropdown(
                          label:
                              _callDurationSeconds > 0
                                  ? "Call Status (Auto: Connected)"
                                  : "Call Status",
                          value: selectedCallStatus,
                          items: callStatusOptions,
                          enabled: _hasCalled,
                          onChanged: (value) {
                            setState(() {
                              selectedCallStatus = value;
                              _isDirty = true;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Reason Dropdown - Only for Loss of Sale and All Calls
                      if (widget.callTypeIndex == 0 ||
                          widget.callTypeIndex == 1) ...[
                        _buildDropdown(
                          label: "Reason",
                          value: selectedReason,
                          items: reasonOptions,
                          hint: "Add reason",
                          enabled: _hasCalled,
                          onChanged: (value) {
                            setState(() {
                              selectedReason = value;
                              _isDirty = true;
                              if (value != "Other") {
                                customReasonController.clear();
                              }
                            });
                          },
                        ),
                        // Custom Reason TextField (shown when "Other" is selected)
                        if (selectedReason == "Other") ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: customReasonController,
                            enabled: _hasCalled,
                            decoration: InputDecoration(
                              hintText: "Enter custom reason",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontFamily: TextConstant.dmSansRegular,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: ColorConstant.primaryColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ],
                      // Rating Section - Only for Return (replaces Reason dropdown)
                      if (widget.contact["isRentout"] == true) ...[
                        _buildRatingSection(),
                        const SizedBox(height: 16),
                      ],
                      // Lead Status Dropdown - Only for Booking Confirmation and Return
                      if (widget.callTypeIndex == 3 ||
                          widget.contact["isRentout"] == true)
                        _buildDropdown(
                          label: "Lead Status",
                          value: selectedLeadStatus,
                          items: leadStatusOptions,
                          hint: "No Status",
                          enabled: _hasCalled,
                          onChanged: (value) {
                            setState(() {
                              selectedLeadStatus = value;
                              _isDirty = true;
                            });
                          },
                        ),

                      if (widget.callTypeIndex == 3 ||
                          widget.contact["isRentout"] == true)
                        const SizedBox(height: 16),

                      const SizedBox(height: 16),

                      // Mark As Follow Up - Hide for follow-up leads (they're already follow-ups)
                      if (!isFollowUpLead)
                        Row(
                          children: [
                            Checkbox(
                              value: markAsFollowUp,
                              onChanged:
                                  _hasCalled
                                      ? (value) {
                                        setState(() {
                                          markAsFollowUp = value ?? false;
                                          _isDirty = true;
                                          if (markAsFollowUp &&
                                              followUpDate == null) {
                                            followUpDate = DateTime.now().add(
                                              const Duration(days: 7),
                                            );
                                          }
                                        });
                                      }
                                      : null,
                              activeColor: ColorConstant.primaryColor,
                            ),
                            Text(
                              "Mark As Follow Up",
                              style: TextStyle(
                                fontFamily: TextConstant.dmSansMedium,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            if (markAsFollowUp) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap:
                                    _hasCalled
                                        ? () async {
                                          DateTime? pickedDate =
                                              await showDatePicker(
                                                context: context,
                                                initialDate:
                                                    followUpDate ??
                                                    DateTime.now(),
                                                firstDate: DateTime.now(),
                                                lastDate: DateTime(2101),
                                              );
                                          if (pickedDate != null) {
                                            setState(() {
                                              followUpDate = pickedDate;
                                              _isDirty = true;
                                            });
                                          }
                                        }
                                        : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: iconBgColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    followUpDate != null
                                        ? "${followUpDate!.day} ${_getMonthName(followUpDate!.month)} ${followUpDate!.year}"
                                        : "Select Date",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: iconColor,
                                      fontFamily: TextConstant.dmSansMedium,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                      if (!isFollowUpLead) const SizedBox(height: 16),

                      // Mark As Starred Call
                      if (!isFollowUpLead)
                        Row(
                          children: [
                            Checkbox(
                              value: markAsStarred,
                              onChanged:
                                  _hasCalled
                                      ? (value) {
                                        setState(() {
                                          markAsStarred = value ?? false;
                                          _isDirty = true;
                                        });
                                      }
                                      : null,
                              activeColor: ColorConstant.primaryColor,
                            ),
                            Text(
                              "Mark As Starred Call",
                              style: TextStyle(
                                fontFamily: TextConstant.dmSansMedium,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                      if (!isFollowUpLead) const SizedBox(height: 16),

                      // Remarks
                      Text(
                        "Remarks",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: TextConstant.dmSansMedium,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: remarksController,
                        enabled: _hasCalled,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: "Enter your remarks",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: ColorConstant.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons - Different for follow-up leads
                      if (isFollowUpLead) ...[
                        // Save Follow Up button
                        ElevatedButton(
                          onPressed:
                              (_hasCalled || _isDirty) && !_isSaving
                                  ? () async {
                                    await _saveFollowUp();
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (_hasCalled || _isDirty) && !_isSaving
                                    ? ColorConstant.primaryColor
                                    : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 0),
                          ),
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text(
                                    "Save Follow Up",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: TextConstant.dmSansMedium,
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 12),
                        // Call Now button
                        ElevatedButton.icon(
                          onPressed:
                              _isCallActive
                                  ? null
                                  : () async {
                                    await _makePhoneCall(
                                      widget.contact["phone"] ?? "",
                                    );
                                  },
                          icon: Icon(
                            _isCallActive ? Icons.phone_disabled : Icons.phone,
                            size: 18,
                          ),
                          label: Text(
                            _isCallActive ? "Calling..." : "Call Now",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isCallActive
                                    ? Colors.grey[400]
                                    : ColorConstant.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 0),
                          ),
                        ),
                      ] else ...[
                        // Regular action buttons for non-follow-up leads
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: TextConstant.dmSansMedium,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _hasCalled
                                        ? () async {
                                          await _saveCallUpdate();
                                        }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _hasCalled
                                          ? ColorConstant.primaryColor
                                          : Colors.grey[400],
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Save Call Update",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: TextConstant.dmSansMedium,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle back navigation with unsaved changes detection
  Future<bool> _handleBackNavigation() async {
    if (!_isDirty) {
      // No unsaved changes, allow navigation
      return true;
    }

    // Show confirmation dialog
    final shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have entered details but not saved. What do you want to do?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Save
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      // User chose to save
      await _saveCallUpdate();
      return true; // Allow navigation after saving
    }

    // User chose to cancel or dismissed
    return false; // Prevent navigation
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xff171717),
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            fontFamily: TextConstant.dmSansMedium,
            height: isMultiline ? 1.4 : 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    String? hint,
    required Function(String?)? onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: TextConstant.dmSansMedium,
            color: enabled ? Colors.grey[800] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: enabled ? Colors.transparent : Colors.grey[100],
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              hint ?? "Select $label",
              style: TextStyle(
                color: enabled ? Colors.grey[400] : Colors.grey[300],
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: enabled ? Colors.grey[600] : Colors.grey[300],
            ),
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: TextConstant.dmSansRegular,
                        fontSize: 14,
                        color: enabled ? Colors.black : Colors.grey[400],
                      ),
                    ),
                  );
                }).toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    // Check if it's a follow-up lead
    if (isFollowUpLead) {
      return _buildFollowUpDetailsSection();
    }

    // Check if it's a return call
    if (widget.contact["isRentout"] == true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            "Booking No",
            widget.contact["bookingNo"] ?? "Not available",
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            "Return Date",
            widget.contact["returnDate"] ?? "Not available",
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            "Attended By",
            widget.contact["attendedBy"] ?? "Not available",
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            "Security Amount",
            widget.contact["securityAmount"] ?? "Not available",
          ),
        ],
      );
    }

    // Booking Confirmation (callTypeIndex: 3)
    if (widget.callTypeIndex == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  "Enquiry Date",
                  widget.contact["enquiryDate"] ?? "Not available",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailRow(
                  "Function Date",
                  widget.contact["functionDate"] ?? "Not available",
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            "Booking No",
            widget.contact["bookingNo"] ?? "Not available",
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            "Security Amount",
            widget.contact["securityAmount"] ?? "Not available",
          ),
        ],
      );
    }

    // Loss of Sale (callTypeIndex: 1) and All Calls (callTypeIndex: 0)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailRow(
                "Visit Date",
                widget.contact["visitDate"] ?? "Not available",
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailRow(
                "Function Date",
                widget.contact["functionDate"] ?? "Not available",
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          "Attended By",
          widget.contact["attendedBy"] ?? "Not available",
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          "Reason Collected From Store",
          widget.contact["reasonFromStore"] ?? "No reason provided",
          isMultiline: true,
        ),
      ],
    );
  }

  Widget _buildFollowUpDetailsSection() {
    // Get follow-up date from contact or lead
    final followUpDateValue =
        widget.contact["followUpDate"] as DateTime? ??
        (widget.contact["followUpDate"] != null
            ? DateTime.tryParse(widget.contact["followUpDate"].toString())
            : null) ??
        followUpDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Follow Up Date Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Follow Up Date",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  followUpDateValue != null
                      ? DateFormatter.formatDate(followUpDateValue)
                      : "Not set",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: TextConstant.dmSansMedium,
                  ),
                ),
                GestureDetector(
                  onTap:
                      _hasCalled
                          ? () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: followUpDateValue ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                followUpDate = pickedDate;
                                _isDirty = true;
                              });
                            }
                          }
                          : null,
                  child: Text(
                    "Change Date",
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _hasCalled
                              ? ColorConstant.primaryColor
                              : Colors.grey[400],
                      fontFamily: TextConstant.dmSansMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Three-column date layout
        Row(
          children: [
            Expanded(
              child: _buildDetailRow(
                "Visit Date",
                widget.contact["visitDate"] ??
                    widget.contact["visit_date"] ??
                    "Not available",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailRow(
                "Function Date",
                widget.contact["functionDate"] ??
                    widget.contact["function_date"] ??
                    "Not available",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailRow(
                "Call Date",
                widget.contact["callDate"] ??
                    widget.contact["date"] ??
                    widget.contact["created_at"] ??
                    "Not available",
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Attended By
        _buildDetailRow(
          "Attended By",
          widget.contact["attendedBy"] ??
              widget.contact["attended_by"] ??
              "Not available",
        ),
      ],
    );
  }

  Widget _buildStatusPillDropdown(
    String label,
    String? value,
    List<String> items,
    Color color,
    bool enabled,
    Function(String?)? onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              "Select $label",
              style: TextStyle(
                color: enabled ? Colors.grey[400] : Colors.grey[300],
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color:
                  enabled
                      ? Color.fromRGBO(
                        (color.red * 0.7).round().clamp(0, 255),
                        (color.green * 0.7).round().clamp(0, 255),
                        (color.blue * 0.7).round().clamp(0, 255),
                        1.0,
                      )
                      : Colors.grey[300],
            ),
            items:
                items.map((String item) {
                  final darkerColor = Color.fromRGBO(
                    (color.red * 0.7).round().clamp(0, 255),
                    (color.green * 0.7).round().clamp(0, 255),
                    (color.blue * 0.7).round().clamp(0, 255),
                    1.0,
                  );
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontFamily: TextConstant.dmSansRegular,
                        fontSize: 14,
                        color: enabled ? darkerColor : Colors.grey[400],
                      ),
                    ),
                  );
                }).toList(),
            onChanged: enabled ? onChanged : null,
            style: TextStyle(
              fontSize: 14,
              color: Color.fromRGBO(
                (color.red * 0.7).round().clamp(0, 255),
                (color.green * 0.7).round().clamp(0, 255),
                (color.blue * 0.7).round().clamp(0, 255),
                1.0,
              ),
              fontFamily: TextConstant.dmSansMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveFollowUp() async {
    final leadId = widget.contact["id"] as String?;
    if (leadId == null) return;

    // Prevent duplicate saves
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final apiService = ApiService();

      // Get follow-up date from state or contact
      final followUpDateValue =
          followUpDate ??
          (widget.contact["followUpDate"] as DateTime?) ??
          (widget.contact["followUpDate"] != null
              ? DateTime.tryParse(widget.contact["followUpDate"].toString())
              : null);

      // Update follow-up lead with current form data
      await apiService.postFollowUp(
        id: leadId,
        callStatus: selectedCallStatus ?? "Not called yet",
        leadStatus: selectedLeadStatus ?? "No Status",
        remarks:
            remarksController.text.trim().isEmpty
                ? null
                : remarksController.text.trim(),
        callDuration: _callDurationSeconds >= 0 ? _callDurationSeconds : null,
        followUpDate: followUpDateValue,
        clearFollowUpDate: followUpDateValue == null,
      );

      // Refresh follow-up controller
      final followupController = Provider.of<FollowupController>(
        context,
        listen: false,
      );
      await followupController.fetchFollowUpLeads();

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isDirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow-up saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving follow-up: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeFollowUp() async {
    final leadId = widget.contact["id"] as String?;
    if (leadId == null) return;

    try {
      final apiService = ApiService();

      // Update follow-up lead with null follow-up date to remove it
      await apiService.postFollowUp(
        id: leadId,
        callStatus: selectedCallStatus ?? "Not called yet",
        leadStatus: selectedLeadStatus ?? "No Status",
        remarks:
            remarksController.text.trim().isEmpty
                ? null
                : remarksController.text.trim(),
        callDuration: _callDurationSeconds >= 0 ? _callDurationSeconds : null,
        followUpDate: null,
        clearFollowUpDate: true,
      );

      // Refresh follow-up controller
      final followupController = Provider.of<FollowupController>(
        context,
        listen: false,
      );
      await followupController.fetchFollowUpLeads();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow-up removed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing follow-up: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rating",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: TextConstant.dmSansMedium,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap:
                  _hasCalled
                      ? () {
                        setState(() {
                          rating = index + 1;
                          _isDirty = true;
                        });
                      }
                      : null,
              child: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color:
                    index < rating
                        ? (_hasCalled ? Colors.amber : Colors.grey[300])
                        : Colors.grey[400],
                size: 32,
              ),
            );
          }),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }
}

Widget _callInfoBox({
  required IconData icon,
  required Color color,
  required String title,
  required String value,
}) {
  return Container(
    // margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.4), width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: TextConstant.dmSansMedium,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
