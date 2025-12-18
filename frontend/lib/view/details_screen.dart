import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/format_helper.dart';
import 'package:telecaller_app/view/bottomnavigation_bar.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/services/call_tracking_service.dart';
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

  String get screenTitle {
    // Check if it's a rentout feedback call
    if (widget.contact["isRentout"] == true) {
      return "Rentout Feedback Call";
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
    return callSummary[widget.callTypeIndex]["iconColor"] as Color;
  }

  Color get iconBgColor {
    return callSummary[widget.callTypeIndex]["bgColor"] as Color;
  }

  IconData get icon {
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

    // Initialize PhoneCallService to listen for automatic call duration
    PhoneCallService.initialize(
      onCallStarted: (phoneNumber) {
        // Call initiated - set state
        if (mounted) {
          setState(() {
            _isCallActive = true; // Show call is active but not answered yet
            _callDurationSeconds = 0; // Reset duration
          });
        }
      },
      onCallAnswered: (phoneNumber) {
        // Call answered - update UI
        if (mounted) {
          setState(() {
            _isCallActive = true;
          });
        }
      },
      onCallEnded: (phoneNumber, duration) {
        if (mounted && duration != null) {
          // For any call that ends with duration > 0, update the screen
          // This handles cases where user calls from this screen
          if (duration > 0) {
            setState(() {
              _callDurationSeconds = duration;
              _isCallActive = false;
              // Auto-set status to Connected if call had duration
              if (selectedCallStatus == null) {
                selectedCallStatus = "Connected";
              }
            });
          } else {
            // Call ended but was not answered (missed/rejected)
            setState(() {
              _isCallActive = false;
              _callDurationSeconds = 0;
            });
          }
        }
      },
    );

    // Set up call tracking listener
    _setupCallTrackingListener();
  }

  /// Set up call tracking listener for automatic call duration detection
  void _setupCallTrackingListener() {
    final callTrackingController = Provider.of<CallTrackingController>(
      context,
      listen: false,
    );

    // Set up callback for call state changes
    callTrackingController.setOnCallStateChangedCallback((callData) {
      final contactPhone = widget.contact["phone"] as String? ?? "";

      // Check if this call matches our contact
      if (_isPhoneNumberMatch(callData.phoneNumber, contactPhone)) {
        if (mounted) {
          setState(() {
            switch (callData.callState) {
              case CallState.ringing:
                _isCallActive = true;
                _callDurationSeconds = 0;
                break;
              case CallState.answered:
                _isCallActive = true;
                break;
              case CallState.ended:
                _isCallActive = false;
                _callDurationSeconds = callData.duration;

                // If duration is 0, poll for the actual duration from cache
                if (callData.duration == 0) {
                  _isWaitingForDuration = true;
                  _pollForDuration(callData.phoneNumber);
                } else {
                  // Auto-set call status based on duration
                  if (selectedCallStatus == null) {
                    selectedCallStatus =
                        callData.duration > 0
                            ? LeadConstants.callStatusConnected
                            : LeadConstants.callStatusNotConnected;
                  }
                }
                break;
            }
          });
        }
      }
    });
  }

  /// Poll for duration from cache if initial duration was 0
  Future<void> _pollForDuration(String phoneNumber) async {
    final contactPhone = widget.contact["phone"] as String? ?? "";

    // Poll up to 5 times, waiting 1 second between each attempt
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      try {
        final callTrackingService = CallTrackingService();
        final cachedResult = await callTrackingService.checkForCachedCallResult(
          contactPhone,
        );

        if (cachedResult != null && cachedResult.duration > 0) {
          print(
            'DetailsScreen: ✅ Polled duration found: ${cachedResult.duration}s',
          );

          if (mounted) {
            setState(() {
              _callDurationSeconds = cachedResult.duration;
              _isWaitingForDuration = false;
              _isCallActive = false;

              // Auto-set call status based on duration
              if (selectedCallStatus == null) {
                selectedCallStatus =
                    cachedResult.duration > 0
                        ? LeadConstants.callStatusConnected
                        : LeadConstants.callStatusNotConnected;
              }
            });
          }
          return; // Duration found, stop polling
        }
      } catch (e) {
        print('DetailsScreen: Error polling for duration: $e');
      }
    }

    print('DetailsScreen: ⚠️ Duration not found after polling');

    if (mounted) {
      setState(() {
        _isWaitingForDuration = false;
        _isCallActive = false;
      });
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

    return clean1 == clean2 ||
        clean1.contains(clean2) ||
        clean2.contains(clean1);
  }

  Future<void> _saveCallUpdate() async {
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
          source: lead.source,
          leadType: lead.leadType,
        );

        // Update locally first
        await repository.updateLead(updatedLead);

        // Refresh controllers to update UI
        // This ensures leads are moved from "leads" to "reports" if call status changed
        try {
          final leadController = Provider.of<LeadScreenController>(
            context,
            listen: false,
          );
          // Refresh to remove lead from leads list if it's now "called"
          leadController.refresh();
        } catch (e) {
          // LeadScreenController might not be available, that's okay
          print('Could not refresh LeadScreenController: $e');
        }

        try {
          final reportController = Provider.of<ReportController>(
            context,
            listen: false,
          );
          // Refresh to show updated lead in reports if it's now "called"
          reportController.refresh();
        } catch (e) {
          // ReportController might not be available, that's okay
          print('Could not refresh ReportController: $e');
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

            // Refresh again after API update to ensure UI is updated
            leadController.refresh();

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

        // If it's a Rent-Out lead, also update via API
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

            await leadController.updateRentOutLead(
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
            );

            // Refresh again after API update to ensure UI is updated
            leadController.refresh();

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rent-Out lead updated successfully'),
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
            print('Error updating Rent-Out lead via API: $e');
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
            );

            // Refresh again after API update to ensure UI is updated
            leadController.refresh();

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
              functionDate:
                  markAsFollowUp ? followUpDate?.toIso8601String() : null,
            );

            print('DetailsScreen: General lead updated successfully via API');

            // Refresh controllers to update UI
            try {
              final leadController = Provider.of<LeadScreenController>(
                context,
                listen: false,
              );
              leadController.refresh();
            } catch (e) {
              print('Could not refresh LeadScreenController: $e');
            }

            try {
              final reportController = Provider.of<ReportController>(
                context,
                listen: false,
              );
              reportController.refresh();
            } catch (e) {
              print('Could not refresh ReportController: $e');
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

        // Note: We don't remove leads from repository after calling
        // The lead screen filters by call status (isUncalledStatus) so called leads
        // won't appear there, but they'll still be available for reports screen
        // This ensures leads persist in reports even after screen changes
      }
    }

    // Reset dirty flag after successful save
    _isDirty = false;

    // Navigate based on follow-up status
    if (mounted) {
      // If follow-up date is set, navigate to follow-up screen
      if (markAsFollowUp && followUpDate != null) {
        Navigator.of(context).pop();
        // Navigate to follow-up screen (index 4 in bottom nav)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          BottomNavState.navigateToFollowUp();
        });
      } else {
        // Pop back to BottomNav (not all the way to LoginScreen)
        Navigator.of(context).pop();

        // Only navigate to Reports tab if this is a NEW lead (not previously called)
        // Check if the lead was previously called
        final repository = LeadRepository();
        final lead = repository.getLeadById(leadId!);

        if (lead != null) {
          // Check if this was a new lead (not called before)
          final wasNewLead = !LeadConstants.isCalledStatus(lead.callStatus);

          if (wasNewLead) {
            // Only new leads move to "New Leads" report screen
            ReportController.navigateToEquaryCalls();
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                BottomNavState.navigateToReports();
              });
            }
          }
          // If it was already called, just pop back - don't navigate to reports
        }
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
      final success = await PhoneCallService.makeCall(
        phoneNumber: cleanedNumber,
        leadId: widget.contact["id"] as String?,
      );

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
                      Text(
                        screenTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: TextConstant.dmSansMedium,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.contact["storeName"] ?? "Zorucci Edappally",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontFamily: TextConstant.dmSansRegular,
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
                                Text(
                                  widget.contact["phone"] ?? "",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorConstant.grey,
                                    fontFamily: TextConstant.dmSansRegular,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

                      // Call Duration Display Section
                      if (_isWaitingForDuration || _callDurationSeconds > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                _isWaitingForDuration
                                    ? Colors.blue[50]
                                    : Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _isWaitingForDuration
                                      ? Colors.blue[300]!
                                      : Colors.green[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      _isWaitingForDuration
                                          ? Colors.blue[100]
                                          : Colors.green[100],
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    _isWaitingForDuration
                                        ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.blue[700]!,
                                                ),
                                          ),
                                        )
                                        : Icon(
                                          Icons.timer,
                                          size: 24,
                                          color: Colors.green[700],
                                        ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isWaitingForDuration
                                          ? "Reading Call Duration..."
                                          : "Call Duration",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            _isWaitingForDuration
                                                ? Colors.blue[600]
                                                : Colors.green[600],
                                        fontFamily: TextConstant.dmSansRegular,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isWaitingForDuration
                                          ? "Writing to call log..."
                                          : FormatHelper.formatCallDurationWithUnits(
                                            _callDurationSeconds,
                                          ),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _isWaitingForDuration
                                                ? Colors.blue[700]
                                                : Colors.green[700],
                                        fontFamily: TextConstant.dmSansMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_isWaitingForDuration || _callDurationSeconds > 0)
                        const SizedBox(height: 24),

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
                      // Rating Section - Only for Rentout Feedback (replaces Reason dropdown)
                      if (widget.contact["isRentout"] == true) ...[
                        _buildRatingSection(),
                        const SizedBox(height: 16),
                      ],
                      // Lead Status Dropdown - Only for Booking Confirmation and Rentout
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

                      // Mark As Follow Up
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

                      const SizedBox(height: 16),

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

                      // Action Buttons
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
    // Check if it's a rentout feedback call
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
