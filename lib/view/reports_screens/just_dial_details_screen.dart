import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';

class JustDialDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const JustDialDetailsScreen({super.key, required this.contact});

  @override
  State<JustDialDetailsScreen> createState() => _JustDialDetailsScreenState();
}

class _JustDialDetailsScreenState extends State<JustDialDetailsScreen> {
  String? selectedCallStatus;
  String? selectedLeadStatus;
  String? selectedClosingStatus;
  String? selectedReason;
  bool markAsFollowUp = false;
  DateTime? followUpDate;
  final TextEditingController remarksController = TextEditingController();

  final Color iconColor = const Color(0xFFF37927);
  final Color iconBgColor = const Color(0xFFFFE8D5);
  final IconData icon = Icons.headset_mic_outlined;

  final List<String> callStatusOptions = [
    "Not called yet",
    "Connected",
    "Not Connected",
    "Call Back Later",
    "Confirmed",
    "Cancelled",
  ];

  final List<String> leadStatusOptions = [
    "No Status",
    "Confirmed",
    "Pending",
    "Cancelled",
    "Follow Up Required",
  ];

  final List<String> closingStatusOptions = [
    "Already Visited",
    "Not Visited",
    "Scheduled Visit",
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

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: SafeArea(
        child: Column(
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
                      const Text(
                        "Just Dial Enquiries",
                        style: TextStyle(
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
                            onPressed: () {
                              // Handle call action
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

                      // Enquiry Details Section
                      _buildDetailRow(
                        "Enquiry Date",
                        widget.contact["enquiryDate"] ?? "Not available",
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        "Function Date",
                        widget.contact["functionDate"] ?? "Not available",
                      ),

                      const SizedBox(height: 24),

                      // Call Status Dropdown
                      _buildDropdown(
                        label: "Call Status",
                        value: selectedCallStatus,
                        items: callStatusOptions,
                        onChanged: (value) {
                          setState(() {
                            selectedCallStatus = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Lead Status Dropdown
                      _buildDropdown(
                        label: "Lead Status",
                        value: selectedLeadStatus,
                        items: leadStatusOptions,
                        hint: "No Status",
                        onChanged: (value) {
                          setState(() {
                            selectedLeadStatus = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Closing Status Dropdown
                      _buildDropdown(
                        label: "Closing Status",
                        value: selectedClosingStatus,
                        items: closingStatusOptions,
                        hint: "Already Visited",
                        onChanged: (value) {
                          setState(() {
                            selectedClosingStatus = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Reason Dropdown
                      _buildDropdown(
                        label: "Reason",
                        value: selectedReason,
                        items: reasonOptions,
                        hint: "Add reason",
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                      ),

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
                          const Text(
                            "Mark As Follow Up",
                            style: TextStyle(
                              fontFamily: TextConstant.dmSansMedium,
                              fontSize: 14,
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
                              onPressed: () {
                                // Handle save action
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstant.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
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
            color: const Color(0xff171717),
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
    required Function(String?) onChanged,
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
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              hint ?? "Select $label",
              style: TextStyle(
                color: Colors.grey[400],
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: TextConstant.dmSansRegular,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
          ),
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
