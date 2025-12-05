import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/bottomnavigation_bar.dart';
import 'dart:async';

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

class _DetailsScreenState extends State<DetailsScreen>
    with WidgetsBindingObserver {
  String? selectedCallStatus;
  String? selectedReason;
  final TextEditingController customReasonController = TextEditingController();
  String? selectedLeadStatus;
  bool markAsFollowUp = false;
  DateTime? followUpDate;
  int rating = 0;
  final TextEditingController remarksController = TextEditingController();

  // Call tracking variables
  bool _isCallActive = false;
  DateTime? _callStartTime;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  bool _wasAppInBackground = false;
  DateTime? _backgroundTime;
  Timer? _autoStopTimer;

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
    WidgetsBinding.instance.addObserver(this);
    // Initialize call duration from existing contact if available
    final existingDuration = widget.contact["callDuration"] as int?;
    if (existingDuration != null && existingDuration > 0) {
      _callDurationSeconds = existingDuration;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background - user likely opened dialer or is on a call
      if (_isCallActive && _callStartTime != null) {
        _wasAppInBackground = true;
        _backgroundTime = DateTime.now();
        // Set auto-stop timer in case user doesn't return (max 2 hours)
        _autoStopTimer?.cancel();
        _autoStopTimer = Timer(const Duration(hours: 2), () {
          if (mounted && _isCallActive) {
            _stopCallTimer();
            setState(() {});
          }
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      if (_wasAppInBackground && _isCallActive) {
        // Calculate time spent in background
        if (_backgroundTime != null) {
          final backgroundDuration = DateTime.now().difference(
            _backgroundTime!,
          );

          // If user was away for more than 30 seconds, assume call ended
          // This handles the case where user makes call and returns to app
          if (backgroundDuration.inSeconds > 30) {
            // Finalize the duration - timer already calculated it
            _stopCallTimer();
            _wasAppInBackground = false;
            _backgroundTime = null;

            // Auto-set status to Connected if duration > 0
            if (_callDurationSeconds > 0 && selectedCallStatus == null) {
              selectedCallStatus = "Connected";
            }
          } else {
            // User returned quickly, might still be in dialer
            // Keep timer running
            _wasAppInBackground = false;
            _backgroundTime = null;
          }
        } else {
          // Fallback: stop timer if we were tracking
          _stopCallTimer();
          _wasAppInBackground = false;
        }
      }
    }
  }

  Future<void> _saveCallUpdate() async {
    // Stop timer if running
    _stopCallTimer();

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
        );

        await repository.updateLead(updatedLead);
      }
    }

    // Navigate back to previous screen (BottomNav) and switch to Reports tab
    if (mounted) {
      // Pop back to BottomNav (not all the way to LoginScreen)
      Navigator.of(context).pop();

      // Switch to Reports tab (index 3) in bottom navigation
      // Set flag to navigate to Equary Calls tab when Report screen loads
      ReportController.navigateToEquaryCalls();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          BottomNavState.navigateToReports();
        });
      }
    }
  }

  void _startCallTimer() {
    _callStartTime = DateTime.now();
    _isCallActive = true;
    _callDurationSeconds = 0; // Reset duration when starting new call
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _callStartTime != null) {
        final elapsed = DateTime.now().difference(_callStartTime!);
        setState(() {
          _callDurationSeconds = elapsed.inSeconds;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    // Finalize duration calculation
    if (_callStartTime != null && _isCallActive) {
      final elapsed = DateTime.now().difference(_callStartTime!);
      _callDurationSeconds = elapsed.inSeconds;
    }

    _isCallActive = false;
    _callStartTime = null;
    _wasAppInBackground = false;
    _backgroundTime = null;

    // Auto-set status to Connected if call had duration
    if (_callDurationSeconds > 0 && selectedCallStatus == null) {
      selectedCallStatus = "Connected";
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
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
      final launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched && mounted) {
        // Don't start timer yet - wait for user to tap call logo when call is answered
        // Just mark that dialer was opened
        setState(() {
          // Timer will start when user taps the call logo
        });
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

  void _onCallLogoTap() {
    // User taps call logo to indicate call was answered
    // Start tracking call duration from this point
    if (!_isCallActive) {
      _startCallTimer();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _stopCallTimer();
    _autoStopTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    remarksController.dispose();
    customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onTap: () => Navigator.pop(context),
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

                    // Call Logo - Tap to start tracking when call is answered
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _onCallLogoTap,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  _isCallActive
                                      ? Colors.green[50]
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    _isCallActive
                                        ? Colors.green[300]!
                                        : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCallActive
                                      ? Icons.phone_in_talk
                                      : Icons.phone,
                                  size: 24,
                                  color:
                                      _isCallActive
                                          ? Colors.green[700]
                                          : Colors.grey[700],
                                ),
                                if (_isCallActive) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    "Call Active",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontFamily: TextConstant.dmSansMedium,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    "Tap when answered",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontFamily: TextConstant.dmSansRegular,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_isCallActive) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              _stopCallTimer();
                              setState(() {});
                            },
                            child: const Text(
                              "End Call",
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Call Status Dropdown
                    _buildDropdown(
                      label:
                          _callDurationSeconds > 0
                              ? "Call Status (Auto: Connected)"
                              : "Call Status",
                      value: selectedCallStatus,
                      items: callStatusOptions,
                      enabled: true,
                      onChanged: (value) {
                        setState(() {
                          selectedCallStatus = value;
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
                        enabled: true,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
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
                          enabled: true,
                          decoration: InputDecoration(
                            hintText: "Enter custom reason",
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
                        enabled: true,
                        onChanged: (value) {
                          setState(() {
                            selectedLeadStatus = value;
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
                          onChanged: (value) {
                            setState(() {
                              markAsFollowUp = value ?? false;
                              if (markAsFollowUp && followUpDate == null) {
                                followUpDate = DateTime.now().add(
                                  const Duration(days: 7),
                                );
                              }
                            });
                          },
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
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: followUpDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  followUpDate = pickedDate;
                                });
                              }
                            },
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
                      enabled: true,
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                            onPressed: () async {
                              await _saveCallUpdate();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstant.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
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
              onTap: () {
                setState(() {
                  rating = index + 1;
                });
              },
              child: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: index < rating ? Colors.amber : Colors.grey[400],
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
