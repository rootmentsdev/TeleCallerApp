import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  final int callTypeIndex; // 0: All Calls, 1: Loss of Sale, 2: Feedback Calls

  const ReportDetailsScreen({
    super.key,
    required this.contact,
    required this.callTypeIndex,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  bool callNow = true; // Default to true for completed calls
  String? selectedCallStatus;
  String? selectedReason;
  final TextEditingController customReasonController = TextEditingController();
  String? selectedLeadStatus;
  bool markAsFollowUp = false;
  DateTime? followUpDate;
  final TextEditingController remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize values from contact if available
    final contactCallStatus = widget.contact["callStatus"] as String?;
    selectedCallStatus =
        (contactCallStatus != null &&
                callStatusOptions.contains(contactCallStatus))
            ? contactCallStatus
            : "Connected";

    final contactLeadStatus = widget.contact["leadStatus"] as String?;
    selectedLeadStatus =
        (contactLeadStatus != null &&
                leadStatusOptions.contains(contactLeadStatus))
            ? contactLeadStatus
            : null;

    final contactReason = widget.contact["reason"] as String?;
    selectedReason =
        (contactReason != null && reasonOptions.contains(contactReason))
            ? contactReason
            : null;
    if (widget.contact["followUpDate"] != null) {
      try {
        final followUpDateStr = widget.contact["followUpDate"];
        if (followUpDateStr is String) {
          followUpDate = DateTime.parse(followUpDateStr);
          markAsFollowUp = true;
        }
      } catch (e) {
        // Handle parsing error
      }
    }
    if (widget.contact["remarks"] != null) {
      remarksController.text = widget.contact["remarks"] as String;
    }
    if (selectedReason == "Other") {
      customReasonController.text = widget.contact["reason"] as String? ?? "";
    }
  }

  final List<String> callStatusOptions = [
    "Not Called",
    "Connected",
    "Not Connected",
    "Call Back Later",
    "Busy",
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
    "New Lead",
    "Contacted",
    "Qualified",
    "Negotiation",
    "Won",
    "Lost",
  ];

  String get screenSubtitle {
    final storeName = widget.contact["storeName"] ?? "Zorucci Edappally";
    String category = "";

    switch (widget.callTypeIndex) {
      case 0:
        category = "All Calls";
        break;
      case 1:
        category = "Loss of Sale";
        break;
      case 2:
        category = "Feedback Calls";
        break;
      default:
        category = "All Calls";
    }

    return "$storeName | $category";
  }

  String _formatCallDuration(int? seconds) {
    if (seconds == null || seconds <= 0) {
      return "00:00 mins";
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')} mins";
  }

  @override
  void dispose() {
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
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Call Completed",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      screenSubtitle,
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
                    // Customer Information Section
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.contact["name"] ?? "",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: TextConstant.dmSansMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    widget.contact["phone"] ?? "",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                      fontFamily: TextConstant.dmSansRegular,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Call Duration Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _formatCallDuration(
                                        widget.contact["callDuration"] as int?,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontFamily: TextConstant.dmSansMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Lead Details Section - Dynamic based on call type
                    _buildDetailsSection(),

                    const SizedBox(height: 24),

                    // // Reason Dropdown
                    // _buildDropdown(
                    //   label: "Reason",
                    //   value: selectedReason,
                    //   items: reasonOptions,
                    //   hint: "Select Reason",
                    //   enabled: callNow,
                    //   onChanged:
                    //       callNow
                    //           ? (value) {
                    //             setState(() {
                    //               selectedReason = value;
                    //               if (value != "Other") {
                    //                 customReasonController.clear();
                    //               }
                    //             });
                    //           }
                    //           : null,
                    // ),

                    // // Custom Reason TextField (shown when "Other" is selected)
                    // if (selectedReason == "Other") ...[
                    //   const SizedBox(height: 16),
                    //   TextField(
                    //     controller: customReasonController,
                    //     enabled: callNow,
                    //     decoration: InputDecoration(
                    //       hintText: "Enter custom reason",
                    //       hintStyle: TextStyle(
                    //         color: Colors.grey[400],
                    //         fontFamily: TextConstant.dmSansRegular,
                    //       ),
                    //       border: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //         borderSide: BorderSide(color: Colors.grey[300]!),
                    //       ),
                    //       enabledBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //         borderSide: BorderSide(color: Colors.grey[300]!),
                    //       ),
                    //       focusedBorder: OutlineInputBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //         borderSide: BorderSide(
                    //           color: ColorConstant.primaryColor,
                    //           width: 2,
                    //         ),
                    //       ),
                    //       contentPadding: const EdgeInsets.all(12),
                    //     ),
                    //   ),
                    // ],
                    const SizedBox(height: 24),

                    // Call Status and Lead Status - Side by Side
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: "Call Status",
                            value: selectedCallStatus,
                            items: callStatusOptions,
                            enabled: callNow,
                            backgroundColor:
                                selectedCallStatus == "Connected"
                                    ? Colors.green[100]
                                    : null,
                            onChanged:
                                callNow
                                    ? (value) {
                                      setState(() {
                                        selectedCallStatus = value;
                                      });
                                    }
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            label: "Lead Status",
                            value: selectedLeadStatus,
                            items: leadStatusOptions,
                            hint: "Select Lead Status",
                            enabled: callNow,
                            backgroundColor:
                                selectedLeadStatus == "Won"
                                    ? const Color(0xFFE8E3FF)
                                    : null,
                            onChanged:
                                callNow
                                    ? (value) {
                                      setState(() {
                                        selectedLeadStatus = value;
                                      });
                                    }
                                    : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Follow Up Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Follow Up Date",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: TextConstant.dmSansMedium,
                                color:
                                    callNow
                                        ? Colors.grey[800]
                                        : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              followUpDate != null
                                  ? "${followUpDate!.day} ${_getMonthName(followUpDate!.month)} ${followUpDate!.year}"
                                  : "Not set",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                fontFamily: TextConstant.dmSansMedium,
                              ),
                            ),
                          ],
                        ),
                        if (callNow)
                          TextButton(
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: followUpDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  followUpDate = pickedDate;
                                  markAsFollowUp = true;
                                });
                              }
                            },
                            child: Text(
                              "Change Date",
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorConstant.primaryColor,
                                fontFamily: TextConstant.dmSansMedium,
                              ),
                            ),
                          ),
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
                                    ? () {
                                      // Handle save action
                                      Navigator.pop(context);
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
    // Format date to remove comma if present
    String formattedValue = value.replaceAll(',', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xff171717),
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedValue,
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
    Color? backgroundColor,
  }) {
    Color? bgColor = backgroundColor;
    if (bgColor == null && enabled) {
      if (label == "Call Status" && value == "Connected") {
        bgColor = Colors.green[100];
      } else if (label == "Lead Status" && value == "Won") {
        bgColor = const Color(0xFFE8E3FF);
      }
    }

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
            color: bgColor ?? (enabled ? Colors.transparent : Colors.grey[100]),
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
    // Loss of Sale (callTypeIndex: 1) and All Calls (callTypeIndex: 0)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Three column date layout
        Row(
          children: [
            Expanded(
              child: _buildDetailRow(
                "Visit Date",
                widget.contact["visitDate"] ??
                    widget.contact["date"] ??
                    "Not available",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailRow(
                "Function Date",
                widget.contact["functionDate"] ?? "Not available",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailRow(
                "Call Date",
                widget.contact["callDate"] ??
                    widget.contact["date"] ??
                    "Not available",
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          "Attended By",
          widget.contact["attendedBy"] ?? "Not available",
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          "Reason Collected From Store",
          widget.contact["reasonFromStore"] ??
              widget.contact["reason"] ??
              "No reason provided",
          isMultiline: true,
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
