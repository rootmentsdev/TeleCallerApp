import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/bottomnavigation_bar.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
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

class _DetailsScreenState extends State<DetailsScreen> {
  bool callNow = false;
  bool callAnswered = false; // Track if call was answered
  String? selectedCallStatus;
  String? selectedReason;
  final TextEditingController customReasonController = TextEditingController();
  String? selectedLeadStatus;
  bool markAsFollowUp = false;
  DateTime? followUpDate;
  int rating = 0;
  final TextEditingController remarksController = TextEditingController();

  // Call duration tracking
  Timer? _callTimer;
  int _callDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Initialize call duration from existing contact if available
    final existingDuration = widget.contact["callDuration"] as int?;
    if (existingDuration != null && existingDuration > 0) {
      _callDurationSeconds = existingDuration;
    }

    // Initialize phone call service to receive call duration updates
    PhoneCallService.initialize(
      onCallEnded: (phoneNumber, duration) {
        debugPrint(
          'PhoneCallService: Call ended - Phone: $phoneNumber, Duration: $duration',
        );

        // Normalize phone numbers for comparison
        String normalizePhone(String phone) {
          // Remove all non-digit characters except +
          String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
          // Remove leading + if present for comparison
          if (cleaned.startsWith('+')) {
            cleaned = cleaned.substring(1);
          }
          // Remove leading country code if it's 91 (India)
          if (cleaned.startsWith('91') && cleaned.length > 10) {
            cleaned = cleaned.substring(2);
          }
          return cleaned;
        }

        // Check if this call matches the current contact
        final contactPhone = widget.contact["phone"] as String? ?? "";
        final normalizedContact = normalizePhone(contactPhone);
        final normalizedCall = normalizePhone(phoneNumber);

        debugPrint(
          'PhoneCallService: Contact phone: $contactPhone -> $normalizedContact',
        );
        debugPrint(
          'PhoneCallService: Call phone: $phoneNumber -> $normalizedCall',
        );
        debugPrint(
          'PhoneCallService: Match: ${normalizedContact == normalizedCall || normalizedContact.contains(normalizedCall) || normalizedCall.contains(normalizedContact)}',
        );

        // Update duration if phone numbers match (more lenient matching)
        final isMatch =
            normalizedContact == normalizedCall ||
            normalizedContact.contains(normalizedCall) ||
            normalizedCall.contains(normalizedContact) ||
            normalizedContact.endsWith(normalizedCall) ||
            normalizedCall.endsWith(normalizedContact);

        if (isMatch) {
          debugPrint(
            'PhoneCallService: Phone numbers match! Updating duration: $duration',
          );
          if (mounted) {
            setState(() {
              if (duration != null && duration > 0) {
                // Call was answered - automatically set status to Connected
                _callDurationSeconds = duration;
                callAnswered = true;
                selectedCallStatus = "Connected";
                debugPrint(
                  'PhoneCallService: Updated call duration to $_callDurationSeconds seconds',
                );
                // Stop any running timer since we have the actual duration
                _stopCallTimer();
              } else {
                // Call was not answered - allow manual status selection
                callAnswered = false;
                debugPrint(
                  'PhoneCallService: Call not answered (duration: $duration)',
                );
                // Set default status if not already set
                if (selectedCallStatus == null) {
                  selectedCallStatus = "Not Connected";
                }
              }
            });
          }
        } else {
          debugPrint(
            'PhoneCallService: Phone numbers do not match, ignoring callback',
          );
        }
      },
    );
  }

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

  Future<void> _saveCallUpdate() async {
    // Stop timer if running
    _stopCallTimer();

    debugPrint('_saveCallUpdate: _callDurationSeconds = $_callDurationSeconds');
    debugPrint('_saveCallUpdate: selectedCallStatus = $selectedCallStatus');
    debugPrint('_saveCallUpdate: callAnswered = $callAnswered');

    // Auto-set call status if call was answered (has duration)
    if (_callDurationSeconds > 0 && selectedCallStatus == null) {
      selectedCallStatus = "Connected";
      callAnswered = true;
      debugPrint(
        '_saveCallUpdate: Auto-set status to Connected (duration: $_callDurationSeconds)',
      );
    }

    // If no call status is set and no duration, set default
    if (selectedCallStatus == null || selectedCallStatus!.isEmpty) {
      // If call was made but no status selected, default to "Not Connected"
      if (callNow) {
        selectedCallStatus = "Not Connected";
      } else {
        // No call was made, don't require status
        selectedCallStatus = "Not called yet";
      }
    }

    // Update callAnswered based on final call status
    callAnswered =
        selectedCallStatus == "Connected" || _callDurationSeconds > 0;

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
          callStatus: selectedCallStatus, // Now guaranteed to be non-null
          followUpDate: markAsFollowUp ? followUpDate : null,
          reason:
              selectedReason == "Other"
                  ? customReasonController.text.trim().isEmpty
                      ? null
                      : customReasonController.text.trim()
                  : selectedReason,
          category: lead.category,
          createdAt: lead.createdAt,
          callDuration:
              (_callDurationSeconds > 0) ? _callDurationSeconds : null,
        );

        debugPrint(
          '_saveCallUpdate: Saving lead with callDuration: ${updatedLead.callDuration}',
        );
        await repository.updateLead(updatedLead);
        debugPrint('_saveCallUpdate: Lead updated successfully');
      }
    }

    // Navigate back to root (bottom navigation) and switch to Reports tab
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);

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

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _stopCallTimer();
    remarksController.dispose();
    customReasonController.dispose();
    PhoneCallService.dispose();
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
                          onPressed: () async {
                            await _makePhoneCall(widget.contact["phone"] ?? "");
                            // callNow will be set to true in _makePhoneCall if call succeeds
                          },
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text("Call Now"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstant.primaryColor,
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

                    // Show message if Call Now not clicked
                    // if (!callNow)
                    //   Container(
                    //     padding: const EdgeInsets.all(16),
                    //     decoration: BoxDecoration(
                    //       color: Colors.blue[50],
                    //       borderRadius: BorderRadius.circular(8),
                    //       border: Border.all(color: Colors.blue[200]!),
                    //     ),
                    //     child: Row(
                    //       children: [
                    //         Icon(
                    //           Icons.info_outline,
                    //           color: Colors.blue[700],
                    //           size: 20,
                    //         ),
                    //         const SizedBox(width: 12),
                    //         Expanded(
                    //           child: Text(
                    //             "Click 'Call Now' to enable data entry options",
                    //             style: TextStyle(
                    //               fontSize: 14,
                    //               color: Colors.blue[900],
                    //               fontFamily: TextConstant.dmSansRegular,
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    if (!callNow) const SizedBox(height: 24),

                    // Call Status Dropdown (optional - auto-set if call answered)
                    _buildDropdown(
                      label:
                          "Call Status ${_callDurationSeconds > 0 ? '(Auto: Connected)' : ''}",
                      value: selectedCallStatus,
                      items: callStatusOptions,
                      enabled: callNow,
                      onChanged:
                          callNow
                              ? (value) {
                                setState(() {
                                  // Allow manual override of status
                                  selectedCallStatus = value;
                                  // Update callAnswered flag
                                  callAnswered =
                                      value == "Connected" ||
                                      _callDurationSeconds > 0;
                                });
                              }
                              : null,
                    ),
                    // Display call duration if call is answered
                    if (callAnswered && _callDurationSeconds > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Call Duration: ${_formatDuration(_callDurationSeconds)}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[700],
                                fontFamily: TextConstant.dmSansMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Reason Dropdown - Only for Loss of Sale and All Calls
                    if (widget.callTypeIndex == 0 ||
                        widget.callTypeIndex == 1) ...[
                      _buildDropdown(
                        label: "Reason",
                        value: selectedReason,
                        items: reasonOptions,
                        hint: "Add reason",
                        enabled: callNow,
                        onChanged:
                            callNow
                                ? (value) {
                                  setState(() {
                                    selectedReason = value;
                                    if (value != "Other") {
                                      customReasonController.clear();
                                    }
                                  });
                                }
                                : null,
                      ),
                      // Custom Reason TextField (shown when "Other" is selected)
                      if (selectedReason == "Other") ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: customReasonController,
                          enabled: callNow,
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
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[200]!),
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
                        enabled: callNow,
                        onChanged:
                            callNow
                                ? (value) {
                                  setState(() {
                                    selectedLeadStatus = value;
                                  });
                                }
                                : null,
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
                              callNow
                                  ? (value) {
                                    setState(() {
                                      markAsFollowUp = value ?? false;
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
                            color: callNow ? Colors.black : Colors.grey[400],
                          ),
                        ),
                        if (markAsFollowUp && callNow) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap:
                                callNow
                                    ? () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                            context: context,
                                            initialDate:
                                                followUpDate ?? DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2101),
                                          );
                                      if (pickedDate != null) {
                                        setState(() {
                                          followUpDate = pickedDate;
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
                        color: callNow ? Colors.grey[800] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: remarksController,
                      enabled: callNow,
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
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: ColorConstant.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: !callNow,
                        fillColor:
                            callNow ? Colors.transparent : Colors.grey[100],
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
                            onPressed:
                                callNow
                                    ? () async {
                                      await _saveCallUpdate();
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  callNow
                                      ? ColorConstant.primaryColor
                                      : Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Save Call Update",
                              style: TextStyle(
                                color:
                                    callNow ? Colors.white : Colors.grey[600],
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
            color: callNow ? Colors.grey[800] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap:
                  callNow
                      ? () {
                        setState(() {
                          rating = index + 1;
                        });
                      }
                      : null,
              child: Icon(
                index < rating ? Icons.star : Icons.star_border,
                color:
                    callNow
                        ? (index < rating ? Colors.amber : Colors.grey[400])
                        : Colors.grey[300],
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

  /// Makes a direct phone call without opening dialer
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
      // Use PhoneCallService for call tracking
      final leadId = widget.contact["id"] as String?;
      final result = await PhoneCallService.makeCall(
        phoneNumber: cleanedNumber,
        leadId: leadId,
      );

      // If call was initiated successfully, enable fields
      if (result && mounted) {
        setState(() {
          callNow = true;
          // Duration will be automatically updated via PhoneCallService callback
        });
      }

      // Fallback to url_launcher if PhoneCallService fails
      if (!result) {
        if (mounted) {
          try {
            final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
            final launched = await launchUrl(
              phoneUri,
              mode: LaunchMode.externalApplication,
            );

            if (launched && mounted) {
              setState(() {
                callNow = true;
              });
            }
          } catch (launchError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Could not make call: ${launchError.toString()}',
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      // Fallback to url_launcher if PhoneCallService is not available
      debugPrint('Error in _makePhoneCall: $e');

      if (mounted) {
        try {
          final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
          final launched = await launchUrl(
            phoneUri,
            mode: LaunchMode.externalApplication,
          );

          if (launched && mounted) {
            setState(() {
              callNow = true;
            });
          }
        } catch (launchError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error making phone call: ${launchError.toString()}',
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }
}
